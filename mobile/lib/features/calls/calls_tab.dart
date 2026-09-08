import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../models/employee.dart';
import '../../providers/auth_controller.dart';
import '../../services/chat_service.dart';
import '../../services/workplace_service.dart';

class CallsTab extends StatelessWidget {
  const CallsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthController>().user?.uid ?? '';
    final companyId = context.watch<AuthController>().profile?.companyId ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Calls')),
      body: ListView(
        children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection(Collections.calls).where('callerId', isEqualTo: me).snapshots(),
            builder: (context, snapshot) {
              final docs = [...(snapshot.data?.docs ?? [])]
                ..sort((a, b) {
                  final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
                  final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
                  return bTime.compareTo(aTime);
                });
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: EmptyHint(
                    icon: Icons.call_outlined,
                    title: 'No recent calls',
                    subtitle: 'Voice calls open the phone dialer. Video calling is logged until in-app WebRTC is added.',
                  ),
                );
              }
              return Column(
                children: docs.map((doc) {
                  final data = doc.data();
                  final kind = data['kind'] as String? ?? 'voice';
                  final at = (data['createdAt'] as Timestamp?)?.toDate();
                  return ListTile(
                    leading: Icon(kind == 'video' ? Icons.videocam : Icons.call, color: AppColors.teal),
                    title: Text(kind == 'video' ? 'Video call' : 'Voice call'),
                    subtitle: Text(at == null ? '' : DateFormat('d MMM, h:mm a').format(at)),
                  );
                }).toList(),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('DIRECTORY', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          StreamBuilder<List<Employee>>(
            stream: WorkplaceService().employees(companyId),
            builder: (context, snapshot) {
              final people = (snapshot.data ?? []).where((p) => p.userId != me).toList();
              if (people.isEmpty) {
                return const ListTile(title: Text('Add employees in the company dashboard to call from here.'));
              }
              return Column(
                children: people
                    .map(
                      (person) => ListTile(
                        leading: UserAvatar(name: person.name, photoUrl: person.photoUrl),
                        title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(person.phone),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.call, color: AppColors.accent),
                              onPressed: () async {
                                if (person.userId.isNotEmpty) await ChatService().logCall(otherUid: person.userId, kind: 'voice');
                                await launchUrl(Uri(scheme: 'tel', path: person.phone));
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.videocam, color: AppColors.teal),
                              onPressed: () async {
                                if (person.userId.isNotEmpty) await ChatService().logCall(otherUid: person.userId, kind: 'video');
                                await launchUrl(Uri(scheme: 'tel', path: person.phone));
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
