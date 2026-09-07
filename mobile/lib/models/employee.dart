import 'package:cloud_firestore/cloud_firestore.dart';

class Employee {
  const Employee({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.name,
    required this.phone,
    required this.role,
    required this.status,
    required this.department,
    required this.photoUrl,
  });

  final String id;
  final String userId;
  final String companyId;
  final String name;
  final String phone;
  final String role;
  final String status;
  final String department;
  final String photoUrl;

  bool get isActive => status == 'active';

  factory Employee.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Employee(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      companyId: data['companyId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: data['role'] as String? ?? 'employee',
      status: data['status'] as String? ?? 'pending',
      department: data['department'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
    );
  }
}
