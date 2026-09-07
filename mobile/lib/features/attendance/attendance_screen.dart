import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../models/attendance_record.dart';
import '../../models/employee.dart';
import '../../providers/auth_controller.dart';
import '../../services/attendance_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _service = AttendanceService();
  bool _busy = false;
  String? _error;
  AttendanceRecord? _checkIn;
  AttendanceRecord? _checkOut;
  Employee? _employee;
  String? _officeHint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadToday());
  }

  Future<void> _loadToday() async {
    final profile = context.read<AuthController>().profile;
    if (profile == null || profile.employeeId.isEmpty) return;
    try {
      final employee = await _service.requireEmployee(profile);
      final checkIn = await _service.todayRecord(employee.id, 'check_in');
      final checkOut = await _service.todayRecord(employee.id, 'check_out');
      if (!mounted) return;
      setState(() {
        _employee = employee;
        _checkIn = checkIn;
        _checkOut = checkOut;
        _officeHint = checkIn?.officeName;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _run(String type) async {
    final profile = context.read<AuthController>().profile;
    if (profile == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final employee = await _service.requireEmployee(profile);
      final fix = await _service.captureLocation();
      if (fix.isMocked) {
        throw AttendanceException('Mock location detected');
      }
      final offices = await _service.officesForCompany(employee.companyId);
      final office = _service.matchingOffice(fix, offices);
      if (office == null) {
        throw AttendanceException(
          'Location not authorized. You must be inside an office geofence.',
        );
      }
      if (!mounted) return;
      final selfie = await Navigator.of(context).push<File>(
        MaterialPageRoute(builder: (_) => const SelfieCaptureScreen()),
      );
      if (selfie == null) {
        throw AttendanceException('Live selfie is required.');
      }
      final result = await _service.submit(
        profile: profile,
        employee: employee,
        type: type,
        selfie: selfie,
        fix: fix,
        office: office,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AttendanceResultScreen(result: result)),
      );
      await _loadToday();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/attendance-history'),
          ),
          IconButton(
            icon: const Icon(Icons.campaign_outlined),
            onPressed: () => Navigator.pushNamed(context, '/notices'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadToday,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(greeting, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 4),
            Text(
              profile?.displayName ?? 'Employee',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('hh:mm a').format(DateTime.now()),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              _officeHint == null ? 'Office will be detected from GPS' : '📍 $_officeHint',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            if (profile?.employeeId.isEmpty ?? true)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Your phone number is not linked to a company employee account yet. Ask HR to add you from the admin dashboard.',
                  ),
                ),
              )
            else ...[
              PrimaryButton(
                label: 'CHECK IN',
                loading: _busy,
                onPressed: _checkIn == null ? () => _run('check_in') : null,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'CHECK OUT',
                color: AppColors.primary,
                loading: _busy,
                onPressed: _checkIn != null && _checkOut == null ? () => _run('check_out') : null,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppColors.danger), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 32),
            const Text('Today\'s Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            _StatusRow(
              label: 'Check-in',
              value: _checkIn == null ? 'Not yet' : DateFormat('hh:mm a').format(_checkIn!.timestamp),
              done: _checkIn != null,
            ),
            _StatusRow(
              label: 'Check-out',
              value: _checkOut == null ? 'Not yet' : DateFormat('hh:mm a').format(_checkOut!.timestamp),
              done: _checkOut != null,
            ),
            if (_employee != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('Department: ${_employee!.department.isEmpty ? 'Unassigned' : _employee!.department}',
                    style: const TextStyle(color: AppColors.muted)),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value, required this.done});

  final String label;
  final String value;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(done ? Icons.check_circle : Icons.remove_circle_outline, color: done ? AppColors.accent : AppColors.muted),
      title: Text(label),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class SelfieCaptureScreen extends StatefulWidget {
  const SelfieCaptureScreen({super.key});

  @override
  State<SelfieCaptureScreen> createState() => _SelfieCaptureScreenState();
}

class _SelfieCaptureScreenState extends State<SelfieCaptureScreen> {
  CameraController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _controller = CameraController(front, ResolutionPreset.medium, enableAudio: false);
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      setState(() => _error = 'Unable to open the camera.');
    }
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
      appBar: AppBar(title: const Text('Live selfie')),
      body: _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white)))
          : controller == null || !controller.value.isInitialized
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    CameraPreview(controller),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Gallery photos are not allowed',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 12),
                            FloatingActionButton.large(
                              onPressed: () async {
                                final shot = await controller.takePicture();
                                if (context.mounted) Navigator.pop(context, File(shot.path));
                              },
                              child: const Icon(Icons.camera_alt),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class AttendanceResultScreen extends StatelessWidget {
  const AttendanceResultScreen({super.key, required this.result});

  final AttendanceResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance recorded')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: AppColors.accent, size: 88),
            const SizedBox(height: 12),
            Text(
              result.type == 'check_in' ? 'CHECK-IN SUCCESSFUL' : 'CHECK-OUT SUCCESSFUL',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            _line('Employee', result.employeeName),
            _line('Date', DateFormat('dd MMMM yyyy').format(result.timestamp)),
            _line('Time', DateFormat('hh:mm a').format(result.timestamp)),
            _line('Office', result.officeName),
            _line('Location', result.locationVerified ? 'Verified' : 'Pending'),
            _line('Photo', 'Captured'),
            const Spacer(),
            PrimaryButton(label: 'Done', onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: AppColors.muted))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final employeeId = context.watch<AuthController>().profile?.employeeId ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance history')),
      body: employeeId.isEmpty
          ? const Center(child: Text('No employee account linked.'))
          : StreamBuilder<List<AttendanceRecord>>(
              stream: AttendanceService().watchHistory(employeeId),
              builder: (context, snapshot) {
                final records = snapshot.data ?? [];
                if (records.isEmpty) {
                  return const Center(child: Text('No attendance records yet.'));
                }
                return ListView.separated(
                  itemCount: records.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return ListTile(
                      leading: Icon(
                        record.isCheckIn ? Icons.login : Icons.logout,
                        color: record.verificationStatus == 'rejected' ? AppColors.danger : AppColors.teal,
                      ),
                      title: Text('${record.isCheckIn ? 'Check-in' : 'Check-out'} · ${record.officeName}'),
                      subtitle: Text(
                        '${DateFormat('dd MMM yyyy, hh:mm a').format(record.timestamp)} · ${record.verificationStatus}',
                      ),
                      trailing: record.selfieUrl.isEmpty
                          ? null
                          : CircleAvatar(backgroundImage: NetworkImage(record.selfieUrl)),
                    );
                  },
                );
              },
            ),
    );
  }
}

class NoticesScreen extends StatelessWidget {
  const NoticesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final companyId = context.watch<AuthController>().profile?.companyId ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Company notices')),
      body: StreamBuilder(
        stream: AttendanceService().watchAnnouncements(companyId),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No company announcements.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(item.body),
                      const SizedBox(height: 8),
                      Text(DateFormat('dd MMM yyyy').format(item.createdAt), style: const TextStyle(color: AppColors.muted)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
