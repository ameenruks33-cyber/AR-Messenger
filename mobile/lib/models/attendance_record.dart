import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.companyId,
    required this.userId,
    required this.type,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.officeId,
    required this.officeName,
    required this.selfieUrl,
    required this.deviceId,
    required this.verificationStatus,
    required this.mockLocation,
    required this.suspiciousMovement,
    required this.deviceAuthorized,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final String companyId;
  final String userId;
  final String type;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String officeId;
  final String officeName;
  final String selfieUrl;
  final String deviceId;
  final String verificationStatus;
  final bool mockLocation;
  final bool suspiciousMovement;
  final bool deviceAuthorized;

  bool get isCheckIn => type == 'check_in';

  factory AttendanceRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AttendanceRecord(
      id: doc.id,
      employeeId: data['employeeId'] as String? ?? '',
      employeeName: data['employeeName'] as String? ?? '',
      companyId: data['companyId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      type: data['type'] as String? ?? 'check_in',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      officeId: data['officeId'] as String? ?? '',
      officeName: data['officeName'] as String? ?? '',
      selfieUrl: data['selfieUrl'] as String? ?? '',
      deviceId: data['deviceId'] as String? ?? '',
      verificationStatus: data['verificationStatus'] as String? ?? 'pending',
      mockLocation: data['mockLocation'] as bool? ?? false,
      suspiciousMovement: data['suspiciousMovement'] as bool? ?? false,
      deviceAuthorized: data['deviceAuthorized'] as bool? ?? false,
    );
  }
}
