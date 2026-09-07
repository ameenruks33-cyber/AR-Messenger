import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/phone.dart';
import '../../core/widgets/app_widgets.dart';
import '../../providers/auth_controller.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _code = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthController>().verifyOtp(_code.text.trim());
    } catch (e) {
      setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = context.watch<AuthController>().pendingPhone ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Enter PIN')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No SMS is used. For $phone, create a 6-digit PIN if this is your first time, or enter the same PIN you already set.',
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: '6-digit PIN',
                counterText: '',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const Spacer(),
            PrimaryButton(label: 'Continue', onPressed: _submit, loading: _loading),
          ],
        ),
      ),
    );
  }
}
