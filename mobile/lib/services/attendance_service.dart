import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/geo.dart';
import '../models/announcement.dart';
import '../models/attendance_record.dart';
import '../models/employee.dart';
import '../models/office.dart';
import '../models/user_profile.dart';
import 'location_service.dart';
import 'storage_service.dart';

class AttendanceException implements Exception {
  AttendanceException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AttendanceResult {
  const AttendanceResult({
    required this.recordId,
    required this.employeeName,
    required this.officeName,
    required this.timestamp,
    required this.type,
    required this.selfieUrl,
    required this.locationVerified,
  });

  final String recordId;
  final String employeeName;
  final String officeName;
  final DateTime timestamp;
  final String type;
  final String selfieUrl;
  final bool locationVerified;
}

class AttendanceService {
  AttendanceService({
    FirebaseFirestore? db,
    StorageService? storage,
    LocationService? location,
    DeviceService? devices,
  })  : _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? StorageService(),
        _location = location ?? LocationService(),
        _devices = devices ?? DeviceService();

  final FirebaseFirestore _db;
  final StorageService _storage;
  final LocationService _location;
  final DeviceService _devices;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<Employee> requireEmployee(UserProfile profile) async {
    if (profile.employeeId.isEmpty) {
      throw AttendanceException(
        'This phone number is not linked to an employee account yet.',
      );
    }
    final doc =
        await _db.collection(Collections.employees).doc(profile.employeeId).get();
    if (!doc.exists) {
      throw AttendanceException('Employee record was not found.');
    }
    final employee = Employee.fromDoc(doc);
    if (!employee.isActive) {
      throw AttendanceException('Your employee account is not active.');
    }
    return employee;
  }

  Future<List<Office>> officesForCompany(String companyId) async {
    final snap = await _db
        .collection(Collections.offices)
        .where('companyId', isEqualTo: companyId)
        .where('attendanceEnabled', isEqualTo: true)
        .get();
    return snap.docs.map(Office.fromDoc).toList();
  }

  Office? matchingOffice(LocationFix fix, List<Office> offices) {
    Office? best;
    var bestDistance = double.infinity;
    for (final office in offices) {
      final meters = distanceMeters(
        lat1: fix.latitude,
        lon1: fix.longitude,
        lat2: office.latitude,
        lon2: office.longitude,
      );
      if (meters <= office.radiusMeters && meters < bestDistance) {
        best = office;
        bestDistance = meters;
      }
    }
    return best;
  }

  Stream<List<AttendanceRecord>> watchHistory(String employeeId) {
    return _db
        .collection(Collections.attendance)
        .where('employeeId', isEqualTo: employeeId)
        .snapshots()
        .map((snap) {
      final records = snap.docs.map(AttendanceRecord.fromDoc).toList();
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return records;
    });
  }

  Stream<List<Announcement>> watchAnnouncements(String companyId) {
    if (companyId.isEmpty) return Stream.value(const []);
    return _db
        .collection(Collections.announcements)
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snap) {
      final items = snap.docs.map(Announcement.fromDoc).toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Future<AttendanceRecord?> todayRecord(String employeeId, String type) async {
    final start = DateTime.now();
    final from = DateTime(start.year, start.month, start.day);
    final snap = await _db
        .collection(Collections.attendance)
        .where('employeeId', isEqualTo: employeeId)
        .where('type', isEqualTo: type)
        .get();
    final today = snap.docs
        .map(AttendanceRecord.fromDoc)
        .where((record) => !record.timestamp.isBefore(from))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return today.isEmpty ? null : today.first;
  }

  Future<LocationFix> captureLocation() => _location.currentFix();

  Future<AttendanceResult> submit({
    required UserProfile profile,
    required Employee employee,
    required String type,
    required File selfie,
    required LocationFix fix,
    required Office office,
  }) async {
    if (fix.isMocked) {
      throw AttendanceException('Mock location detected. Attendance rejected.');
    }

    final device = await _devices.currentDevice();
    final deviceSnap = await _db.collection(Collections.devices).doc(device.id).get();
    var authorized = true;
    if (!deviceSnap.exists) {
      final existingDevices = await _db
          .collection(Collections.devices)
          .where('userId', isEqualTo: _uid)
          .get();
      authorized = existingDevices.docs.isEmpty;
      await _db.collection(Collections.devices).doc(device.id).set({
        'userId': _uid,
        'employeeId': employee.id,
        'platform': device.platform,
        'model': device.model,
        'authorized': authorized,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeenAt': FieldValue.serverTimestamp(),
      });
      if (!authorized) {
        throw AttendanceException(
          'New device detected. Administrator approval is required.',
        );
      }
    } else {
      authorized = deviceSnap.data()?['authorized'] == true;
      if (!authorized) {
        throw AttendanceException(
          'This device is not authorized. Ask your administrator.',
        );
      }
      await _db.collection(Collections.devices).doc(device.id).update({
        'lastSeenAt': FieldValue.serverTimestamp(),
      });
    }

    var suspicious = false;
    final previous = await _db
        .collection(Collections.attendance)
        .where('employeeId', isEqualTo: employee.id)
        .get();
    if (previous.docs.isNotEmpty) {
      final last = previous.docs.map(AttendanceRecord.fromDoc).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final latest = last.first;
      final meters = distanceMeters(
        lat1: latest.latitude,
        lon1: latest.longitude,
        lat2: fix.latitude,
        lon2: fix.longitude,
      );
      final kmh = speedKmh(
        meters: meters,
        duration: fix.timestamp.difference(latest.timestamp),
      );
      if (kmh > AppConstants.suspiciousSpeedKmh) {
        suspicious = true;
      }
    }

    final selfieUrl = await _storage.uploadSelfie(selfie);
    final now = DateTime.now();
    final doc = await _db.collection(Collections.attendance).add({
      'employeeId': employee.id,
      'employeeName': employee.name,
      'companyId': employee.companyId,
      'userId': _uid,
      'type': type,
      'timestamp': Timestamp.fromDate(now),
      'latitude': fix.latitude,
      'longitude': fix.longitude,
      'accuracy': fix.accuracy,
      'officeId': office.id,
      'officeName': office.name,
      'selfieUrl': selfieUrl,
      'deviceId': device.id,
      'verificationStatus': 'pending',
      'mockLocation': fix.isMocked,
      'suspiciousMovement': suspicious,
      'deviceAuthorized': authorized,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return AttendanceResult(
      recordId: doc.id,
      employeeName: employee.name,
      officeName: office.name,
      timestamp: now,
      type: type,
      selfieUrl: selfieUrl,
      locationVerified: true,
    );
  }
}
