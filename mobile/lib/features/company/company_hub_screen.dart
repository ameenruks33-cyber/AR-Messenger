import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../models/announcement.dart';
import '../../providers/auth_controller.dart';
import '../attendance/attendance_screen.dart';
import '../contacts/contacts_tab.dart';

class CompanyHubScreen extends StatelessWidget {
  const CompanyHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    final companyId = profile?.companyId ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Company')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.displayName ?? 'Employee',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  profile?.employeeId.isEmpty == true ? 'Not linked to an employee record yet' : 'ID ${profile!.employeeId}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _HubTile(
            icon: Icons.fingerprint,
            title: 'Attendance',
            subtitle: 'GPS + live selfie check-in',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AttendanceScreen()),
            ),
          ),
          _HubTile(
            icon: Icons.people_outline,
            title: 'Directory',
            subtitle: 'Message colleagues',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContactsTab()),
            ),
          ),
          const SizedBox(height: 8),
          const Text('ANNOUNCEMENTS', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 8),
          if (companyId.isEmpty)
            const EmptyHint(
              icon: Icons.campaign_outlined,
              title: 'No company yet',
              subtitle: 'Admin can seed a company from the dashboard, then link your profile.',
            )
          else
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection(Collections.announcements)
                  .where('companyId', isEqualTo: companyId)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const EmptyHint(
                    icon: Icons.campaign_outlined,
                    title: 'No announcements',
                    subtitle: 'Managers can post from the admin dashboard.',
                  );
                }
                return Column(
                  children: docs.map((doc) {
                    final item = Announcement.fromDoc(doc);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.campaign, color: AppColors.teal),
                      title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(item.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.teal.withValues(alpha: 0.15),
          child: Icon(icon, color: AppColors.teal),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
