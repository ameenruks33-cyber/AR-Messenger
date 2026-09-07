import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
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
    final raw = _phone.text.replaceAll(RegExp(r'[\s-]'), '');
    if (raw.length < 8) {
      setState(() => _error = 'Enter a valid mobile number.');
      return;
    }
    final phone = raw.startsWith('+') ? raw : '${AppConstants.defaultCountryCode}$raw';
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthController>().sendOtp(phone);
      if (!mounted) return;
      Navigator.of(context).pushNamed('/otp');
    } catch (e) {
      setState(() => _error = e.toString());
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
                'Enter your mobile number. We will send an OTP to verify your account.',
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
                decoration: const InputDecoration(
                  labelText: 'Mobile number',
                  hintText: '+971 5X XXX XXXX',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
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
