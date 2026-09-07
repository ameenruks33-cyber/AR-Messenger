import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/phone.dart';
import '../../core/widgets/app_widgets.dart';
import '../../providers/auth_controller.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _phone = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = normalizePhoneNumber(_phone.text);
    if (phone.length < 10) {
      setState(() => _error = 'Enter a valid mobile number, for example +9715XXXXXXXX.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthController>().sendOtp(phone);
      if (!mounted) return;
      Navigator.of(context).pushNamed('/otp');
    } catch (e) {
      setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your UAE mobile number. Example: 50 123 4567 or +971501234567. Do not keep a leading 0 after +971.',
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Mobile number',
                  hintText: '50 123 4567',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              if (_phone.text.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'OTP will be sent to ${normalizePhoneNumber(_phone.text)}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ],
              const Spacer(),
              PrimaryButton(label: 'Send OTP', onPressed: _submit, loading: _loading),
            ],
          ),
        ),
      ),
    );
  }
}
