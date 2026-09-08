import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';

class AppUpdateNotice {
  const AppUpdateNotice({
    required this.message,
    required this.companyId,
    required this.companyName,
    required this.appVersion,
    required this.apkUrl,
    required this.seq,
  });

  final String message;
  final String companyId;
  final String companyName;
  final String appVersion;
  final String apkUrl;
  final int seq;

  factory AppUpdateNotice.fromMap(Map<String, dynamic> data) {
    return AppUpdateNotice(
      message: data['message'] as String? ?? 'New company data is ready.',
      companyId: data['companyId'] as String? ?? '',
      companyName: data['companyName'] as String? ?? '',
      appVersion: data['appVersion'] as String? ?? AppConstants.appVersion,
      apkUrl: data['apkUrl'] as String? ?? AppConstants.apkUrl,
      seq: (data['seq'] as num?)?.toInt() ?? 0,
    );
  }
}

class AppUpdateService {
  Stream<AppUpdateNotice?> watchLatest() {
    return FirebaseFirestore.instance.collection(Collections.appUpdates).doc('latest').snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return AppUpdateNotice.fromMap(data);
    });
  }

  bool isNewerApp(String remote) {
    int score(String value) {
      final parts = value.split('.').map((part) => int.tryParse(part) ?? 0).toList();
      while (parts.length < 3) {
        parts.add(0);
      }
      return parts[0] * 10000 + parts[1] * 100 + parts[2];
    }

    return score(remote) > score(AppConstants.appVersion);
  }
}
