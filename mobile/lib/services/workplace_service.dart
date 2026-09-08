import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/app_constants.dart';
import '../models/attendance_record.dart';
import '../models/employee.dart';
import '../models/office.dart';
import '../models/user_profile.dart';

class WorkplaceService {
  WorkplaceService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Stream<List<Employee>> employees(String companyId) {
    if (companyId.isEmpty) return Stream.value(const []);
    return _db
        .collection(Collections.employees)
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snap) => snap.docs.map(Employee.fromDoc).toList());
  }

  Stream<List<Office>> offices(String companyId) {
    if (companyId.isEmpty) return Stream.value(const []);
    return _db
        .collection(Collections.offices)
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snap) => snap.docs.map(Office.fromDoc).toList());
  }

  Stream<List<Map<String, dynamic>>> collectionForCompany(String name, String companyId) {
    Query<Map<String, dynamic>> query;
    if (companyId.isNotEmpty) {
      query = _db.collection(name).where('companyId', isEqualTo: companyId);
    } else if (name == Collections.leaveRequests) {
      query = _db.collection(name).where('userId', isEqualTo: _uid);
    } else if (name == Collections.recognition) {
      query = _db.collection(name).where('givenBy', isEqualTo: _uid);
    } else {
      query = _db.collection(name).where('createdBy', isEqualTo: _uid);
    }
    return query.snapshots().map((snap) {
      return snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }

  Future<void> createTask({
    required UserProfile profile,
    required String title,
    String assigneeName = '',
    String assigneeId = '',
    String priority = 'High',
    DateTime? due,
  }) {
    return _db.collection(Collections.tasks).add({
      'companyId': profile.companyId,
      'title': title,
      'assigneeName': assigneeName,
      'assigneeId': assigneeId,
      'priority': priority,
      'status': 'pending',
      'createdBy': _uid,
      'dueAt': due == null ? null : Timestamp.fromDate(due),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTaskStatus(String id, String status) {
    return _db.collection(Collections.tasks).doc(id).update({'status': status});
  }

  Future<void> requestLeave({
    required UserProfile profile,
    required String type,
    required DateTime from,
    required DateTime to,
    required String reason,
  }) {
    return _db.collection(Collections.leaveRequests).add({
      'companyId': profile.companyId,
      'userId': _uid,
      'employeeName': profile.displayName,
      'type': type,
      'from': Timestamp.fromDate(from),
      'to': Timestamp.fromDate(to),
      'reason': reason,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setLeaveStatus(String id, String status) {
    return _db.collection(Collections.leaveRequests).doc(id).update({
      'status': status,
      'reviewedBy': _uid,
    });
  }

  Future<void> createEvent({
    required UserProfile profile,
    required String title,
    required DateTime at,
    String groupName = '',
  }) {
    return _db.collection(Collections.events).add({
      'companyId': profile.companyId,
      'title': title,
      'at': Timestamp.fromDate(at),
      'groupName': groupName,
      'createdBy': _uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addDocument({
    required UserProfile profile,
    required String title,
    required String folder,
  }) {
    return _db.collection(Collections.documents).add({
      'companyId': profile.companyId,
      'title': title,
      'folder': folder,
      'createdBy': _uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendSos({
    required UserProfile profile,
    required double latitude,
    required double longitude,
    required String type,
  }) {
    return _db.collection(Collections.emergencies).add({
      'companyId': profile.companyId,
      'userId': _uid,
      'employeeName': profile.displayName,
      'phone': profile.phone,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> giveBadge({
    required UserProfile profile,
    required String employeeName,
    required String badge,
  }) {
    return _db.collection(Collections.recognition).add({
      'companyId': profile.companyId,
      'employeeName': employeeName,
      'badge': badge,
      'givenBy': _uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<AttendanceRecord>> todayAttendance(String companyId) async {
    if (companyId.isEmpty) return const [];
    final start = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    try {
      final snap = await _db
          .collection(Collections.attendance)
          .where('companyId', isEqualTo: companyId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .get();
      return snap.docs.map(AttendanceRecord.fromDoc).toList();
    } catch (_) {
      final snap = await _db.collection(Collections.attendance).where('companyId', isEqualTo: companyId).get();
      return snap.docs.map(AttendanceRecord.fromDoc).where((row) => row.timestamp.isAfter(start)).toList();
    }
  }
}
