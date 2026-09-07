import 'package:flutter/material.dart';

import '../../core/widgets/app_widgets.dart';

class CallsTab extends StatelessWidget {
  const CallsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: MessengerAppBar(title: 'Calls'),
      body: EmptyHint(
        icon: Icons.call_outlined,
        title: 'Calls come later',
        subtitle: 'Voice and video calling are planned for Phase 6 after chat and attendance are stable.',
      ),
    );
  }
}
