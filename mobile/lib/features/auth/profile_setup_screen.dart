import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/phone.dart';
import '../../core/widgets/app_widgets.dart';
import '../../providers/auth_controller.dart';
import '../../services/storage_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _name = TextEditingController();
  File? _photo;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    final cameras = await availableCameras();
    if (!mounted || cameras.isEmpty) return;
    final file = await Navigator.of(context).push<File>(
      MaterialPageRoute(builder: (_) => _LiveCapturePage(cameras: cameras)),
    );
    if (file != null) setState(() => _photo = file);
  }

  Future<void> _submit() async {
    if (_name.text.trim().length < 2) {
      setState(() => _error = 'Enter your name.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      var photoUrl = '';
      if (_photo != null) {
        try {
          photoUrl = await StorageService().uploadProfilePhoto(_photo!);
        } catch (_) {
          photoUrl = '';
        }
      }
      if (!mounted) return;
      await context.read<AuthController>().completeProfile(
            displayName: _name.text.trim(),
            photoUrl: photoUrl,
          );
    } catch (e) {
      setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _capturePhoto,
              child: CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.teal.withValues(alpha: 0.15),
                backgroundImage: _photo != null ? FileImage(_photo!) : null,
                child: _photo == null
                    ? const Icon(Icons.camera_alt, color: AppColors.teal, size: 32)
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            const Text('Tap to take a live profile photo', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 24),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Your name'),
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

class _LiveCapturePage extends StatefulWidget {
  const _LiveCapturePage({required this.cameras});
  final List<CameraDescription> cameras;

  @override
  State<_LiveCapturePage> createState() => _LiveCapturePageState();
}

class _LiveCapturePageState extends State<_LiveCapturePage> {
  CameraController? _controller;

  @override
  void initState() {
    super.initState();
    final front = widget.cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => widget.cameras.first,
    );
    _controller = CameraController(front, ResolutionPreset.medium, enableAudio: false);
    _controller!.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Live photo')),
      body: controller == null || !controller.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CameraPreview(controller),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: FloatingActionButton(
                      onPressed: () async {
                        final file = await controller.takePicture();
                        if (context.mounted) {
                          Navigator.pop(context, File(file.path));
                        }
                      },
                      child: const Icon(Icons.camera),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
