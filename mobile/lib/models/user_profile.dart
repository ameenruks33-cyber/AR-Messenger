import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.phone,
    required this.displayName,
    required this.photoUrl,
    required this.about,
    required this.role,
    required this.companyId,
    required this.employeeId,
    required this.isOnline,
    this.lastSeen,
    this.fcmToken,
    this.createdAt,
  });

  final String id;
  final String phone;
  final String displayName;
  final String photoUrl;
  final String about;
  final String role;
  final String companyId;
  final String employeeId;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? fcmToken;
  final DateTime? createdAt;

  bool get isAdmin =>
      role == 'super_admin' || role == 'hr_admin' || role == 'company_admin';

  bool get isManagerOrAbove => isAdmin || role == 'manager';

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserProfile(
      id: doc.id,
      phone: data['phone'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      about: data['about'] as String? ?? 'Available',
      role: data['role'] as String? ?? 'employee',
      companyId: data['companyId'] as String? ?? '',
      employeeId: data['employeeId'] as String? ?? '',
      isOnline: data['isOnline'] as bool? ?? false,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      fcmToken: data['fcmToken'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'phone': phone,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'about': about,
      'role': 'employee',
      'companyId': companyId,
      'employeeId': employeeId,
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
