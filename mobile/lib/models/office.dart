import 'package:cloud_firestore/cloud_firestore.dart';

class Office {
  const Office({
    required this.id,
    required this.companyId,
    required this.name,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.attendanceEnabled,
  });

  final String id;
  final String companyId;
  final String name;
  final String city;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final bool attendanceEnabled;

  factory Office.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Office(
      id: doc.id,
      companyId: data['companyId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      city: data['city'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      radiusMeters: (data['radiusMeters'] as num?)?.toDouble() ?? 150,
      attendanceEnabled: data['attendanceEnabled'] as bool? ?? true,
    );
  }
}
