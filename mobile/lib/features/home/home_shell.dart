import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_controller.dart';
import '../../providers/prefs_controller.dart';
import '../../services/app_update_service.dart';
import '../calls/calls_tab.dart';
import '../chat/chats_tab.dart';
import '../communities/communities_tab.dart';
import '../company/company_hub_screen.dart';
import '../profile/settings_screen.dart';
import '../status/status_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  bool _applying = false;
  final _updates = AppUpdateService();

  Future<void> _apply(AppUpdateNotice notice) async {
    if (_applying) return;
    setState(() => _applying = true);
    try {
      await context.read<AuthController>().applyWorkspaceUpdate(notice.companyId);
      if (!mounted) return;
      await context.read<PrefsController>().setLastAppliedUpdate(notice.seq);
      if (!mounted) return;
      if (_updates.isNewerApp(notice.appVersion)) {
        await launchUrl(Uri.parse(notice.apkUrl.isEmpty ? AppConstants.apkUrl : notice.apkUrl), mode: LaunchMode.externalApplication);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(notice.companyName.isEmpty ? 'App updated' : '${notice.companyName} is now on this phone')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastApplied = context.watch<PrefsController>().lastAppliedUpdate;
    final pages = const [
      ChatsTab(),
      CommunitiesTab(),
      StatusTab(),
      CallsTab(),
      CompanyHubScreen(),
      SettingsScreen(),
    ];

    return StreamBuilder<AppUpdateNotice?>(
      stream: _updates.watchLatest(),
      builder: (context, snapshot) {
        final notice = snapshot.data;
        final showUpdate = notice != null && notice.seq > lastApplied;
        return Scaffold(
          body: Column(
            children: [
              if (showUpdate)
                Material(
                  color: AppColors.teal,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.system_update_alt, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              notice.message,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton(
                            onPressed: _applying ? null : () => _apply(notice),
                            child: Text(
                              _applying ? 'Updating…' : 'Update',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(child: IndexedStack(index: _index, children: pages)),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.chat_outlined), selectedIcon: Icon(Icons.chat), label: 'Chats'),
              NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Communities'),
              NavigationDestination(icon: Icon(Icons.camera_alt_outlined), selectedIcon: Icon(Icons.camera_alt), label: 'Status'),
              NavigationDestination(icon: Icon(Icons.call_outlined), selectedIcon: Icon(Icons.call), label: 'Calls'),
              NavigationDestination(icon: Icon(Icons.apartment_outlined), selectedIcon: Icon(Icons.apartment), label: 'Company'),
              NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
            ],
          ),
        );
      },
    );
  }
}
