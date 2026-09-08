import 'package:cloud_firestore/cloud_firestore.dart';

class Company {
  const Company({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    required this.country,
    required this.workStartHour,
    required this.lateAfterMinutes,
    required this.notes,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String country;
  final int workStartHour;
  final int lateAfterMinutes;
  final String notes;

  factory Company.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Company(
      id: doc.id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      address: data['address'] as String? ?? '',
      city: data['city'] as String? ?? '',
      country: data['country'] as String? ?? '',
      workStartHour: (data['workStartHour'] as num?)?.toInt() ?? 8,
      lateAfterMinutes: (data['lateAfterMinutes'] as num?)?.toInt() ?? 15,
      notes: data['notes'] as String? ?? '',
    );
  }
}
