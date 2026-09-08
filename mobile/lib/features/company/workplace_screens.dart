import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../models/chat.dart';
import '../../models/employee.dart';
import '../../models/office.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_controller.dart';
import '../../services/chat_service.dart';
import '../../services/location_service.dart';
import '../../services/workplace_service.dart';

class EmployeesScreen extends StatelessWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final companyId = context.watch<AuthController>().profile?.companyId ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Employees')),
      body: StreamBuilder<List<Employee>>(
        stream: WorkplaceService().employees(companyId),
        builder: (context, snapshot) {
          final people = snapshot.data ?? [];
          if (people.isEmpty) {
            return const EmptyHint(icon: Icons.people_outline, title: 'No employees yet', subtitle: 'Admin can add employees from the dashboard.');
          }
          return ListView(
            children: people
                .map(
                  (person) => ListTile(
                    leading: UserAvatar(name: person.name, photoUrl: person.photoUrl),
                    title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${person.department.isEmpty ? person.role : person.department} · ${person.phone}'),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class DirectoryScreen extends StatelessWidget {
  const DirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthController>().user?.uid ?? '';
    final companyId = context.watch<AuthController>().profile?.companyId ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Company directory')),
      body: StreamBuilder<List<Employee>>(
        stream: WorkplaceService().employees(companyId),
        builder: (context, snapshot) {
          final people = (snapshot.data ?? []).where((p) => p.userId != me).toList();
          if (people.isEmpty) {
            return const EmptyHint(icon: Icons.contact_page_outlined, title: 'Directory is empty', subtitle: 'Linked employees appear here for call and chat.');
          }
          return ListView(
            children: people
                .map(
                  (person) => ListTile(
                    leading: UserAvatar(name: person.name, photoUrl: person.photoUrl),
                    title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(person.department.isEmpty ? person.role : person.department),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.call, color: AppColors.teal),
                          onPressed: () => launchUrl(Uri(scheme: 'tel', path: person.phone)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat, color: AppColors.teal),
                          onPressed: person.userId.isEmpty
                              ? null
                              : () async {
                                  final chatId = await ChatService().openDirectChat(person.userId);
                                  if (!context.mounted) return;
                                  Navigator.pushNamed(
                                    context,
                                    '/chat',
                                    arguments: ChatThread(
                                      id: chatId,
                                      type: 'direct',
                                      memberIds: [me, person.userId],
                                      name: person.name,
                                      photoUrl: person.photoUrl,
                                      lastMessage: '',
                                      lastMessageAt: DateTime.now(),
                                      createdBy: me,
                                      companyId: person.companyId,
                                    ),
                                  );
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
    );
  }
}

class DepartmentsScreen extends StatelessWidget {
  const DepartmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final companyId = context.watch<AuthController>().profile?.companyId ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Departments')),
      body: StreamBuilder<List<Employee>>(
        stream: WorkplaceService().employees(companyId),
        builder: (context, snapshot) {
          final people = snapshot.data ?? [];
          final groups = <String, List<Employee>>{};
          for (final person in people) {
            final key = person.department.isEmpty ? 'General' : person.department;
            groups.putIfAbsent(key, () => []).add(person);
          }
          if (groups.isEmpty) {
            return const EmptyHint(icon: Icons.account_tree_outlined, title: 'No departments', subtitle: 'Departments come from employee records.');
          }
          return ListView(
            children: groups.entries
                .map(
                  (entry) => ExpansionTile(
                    leading: const Icon(Icons.groups, color: AppColors.teal),
                    title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${entry.value.length} people'),
                    children: entry.value.map((p) => ListTile(title: Text(p.name), subtitle: Text(p.role))).toList(),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class OfficesScreen extends StatelessWidget {
  const OfficesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final companyId = context.watch<AuthController>().profile?.companyId ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Offices')),
      body: StreamBuilder<List<Office>>(
        stream: WorkplaceService().offices(companyId),
        builder: (context, snapshot) {
          final offices = snapshot.data ?? [];
          if (offices.isEmpty) {
            return const EmptyHint(icon: Icons.apartment_outlined, title: 'No offices', subtitle: 'Admin can add GPS offices for attendance geofencing.');
          }
          return ListView(
            children: offices
                .map(
                  (office) => ListTile(
                    leading: const Icon(Icons.location_city, color: AppColors.teal),
                    title: Text(office.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${office.city} · ${office.radiusMeters.round()}m geofence'),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    final companyId = profile?.companyId ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _create(context, profile),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: WorkplaceService().collectionForCompany(Collections.tasks, companyId),
        builder: (context, snapshot) {
          final tasks = snapshot.data ?? [];
          if (tasks.isEmpty) {
            return const EmptyHint(icon: Icons.task_alt, title: 'No tasks', subtitle: 'Create a task from here or from a chat message.');
          }
          return ListView(
            children: tasks.map((task) {
              final status = task['status'] as String? ?? 'pending';
              return Card(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: ListTile(
                  title: Text(task['title'] as String? ?? 'Task', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${task['assigneeName'] ?? 'Unassigned'} · ${task['priority'] ?? 'Normal'}\n$status'),
                  isThreeLine: true,
                  trailing: Wrap(
                    children: [
                      TextButton(onPressed: () => WorkplaceService().updateTaskStatus(task['id'] as String, 'accepted'), child: const Text('Accept')),
                      TextButton(onPressed: () => WorkplaceService().updateTaskStatus(task['id'] as String, 'complete'), child: const Text('Complete')),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Future<void> _create(BuildContext context, UserProfile? profile) async {
    if (profile == null) return;
    final title = TextEditingController();
    final assignee = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: title, decoration: const InputDecoration(hintText: 'Check Building 4 AC')),
            TextField(controller: assignee, decoration: const InputDecoration(hintText: 'Assigned to')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      ),
    );
    if (ok == true && title.text.trim().isNotEmpty) {
      await WorkplaceService().createTask(
        profile: profile,
        title: title.text.trim(),
        assigneeName: assignee.text.trim(),
        due: DateTime.now().add(const Duration(hours: 8)),
      );
    }
  }
}

class LeaveScreen extends StatelessWidget {
  const LeaveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    final companyId = profile?.companyId ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Leave')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _request(context, profile),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: WorkplaceService().collectionForCompany(Collections.leaveRequests, companyId),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const EmptyHint(icon: Icons.event_busy, title: 'No leave requests', subtitle: 'Request annual, sick, or emergency leave.');
          }
          return ListView(
            children: items.map((item) {
              final from = (item['from'] as Timestamp?)?.toDate();
              final to = (item['to'] as Timestamp?)?.toDate();
              return ListTile(
                title: Text('${item['employeeName'] ?? ''} · ${item['type'] ?? ''}'),
                subtitle: Text('${from == null ? '' : DateFormat('d MMM').format(from)} → ${to == null ? '' : DateFormat('d MMM').format(to)}\n${item['reason'] ?? ''}'),
                isThreeLine: true,
                trailing: profile?.isManagerOrAbove == true && item['status'] == 'pending'
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(onPressed: () => WorkplaceService().setLeaveStatus(item['id'] as String, 'approved'), child: const Text('Approve')),
                          TextButton(onPressed: () => WorkplaceService().setLeaveStatus(item['id'] as String, 'rejected'), child: const Text('Reject')),
                        ],
                      )
                    : Text(item['status'] as String? ?? ''),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Future<void> _request(BuildContext context, UserProfile? profile) async {
    if (profile == null) return;
    final reason = TextEditingController(text: 'Annual leave');
    DateTime from = DateTime.now().add(const Duration(days: 1));
    DateTime to = from.add(const Duration(days: 3));
    String type = 'Annual Leave';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request leave'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: type,
              items: const ['Annual Leave', 'Sick Leave', 'Emergency Leave']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (value) => type = value ?? type,
            ),
            TextField(controller: reason, decoration: const InputDecoration(hintText: 'Reason')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
        ],
      ),
    );
    if (ok == true) {
      await WorkplaceService().requestLeave(profile: profile, type: type, from: from, to: to, reason: reason.text.trim());
    }
  }
}

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    final companyId = profile?.companyId ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _create(context, profile),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: WorkplaceService().collectionForCompany(Collections.events, companyId),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const EmptyHint(icon: Icons.calendar_month, title: 'No events', subtitle: 'Create meetings, reminders, and company events.');
          }
          return ListView(
            children: items.map((item) {
              final at = (item['at'] as Timestamp?)?.toDate();
              return ListTile(
                leading: const Icon(Icons.event, color: AppColors.teal),
                title: Text(item['title'] as String? ?? 'Event', style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${at == null ? '' : DateFormat('EEE d MMM, h:mm a').format(at)}\n${item['groupName'] ?? ''}'),
                isThreeLine: true,
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Future<void> _create(BuildContext context, UserProfile? profile) async {
    if (profile == null) return;
    final title = TextEditingController(text: 'Team meeting');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New event'),
        content: TextField(controller: title, decoration: const InputDecoration(hintText: 'Title')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && title.text.trim().isNotEmpty) {
      await WorkplaceService().createEvent(profile: profile, title: title.text.trim(), at: DateTime.now().add(const Duration(hours: 2)), groupName: 'Management Group');
    }
  }
}

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    final companyId = profile?.companyId ?? '';
    const folders = ['Company Policies', 'Employee Documents', 'Contracts', 'Attendance Reports', 'Meeting Documents', 'Announcements'];
    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _add(context, profile),
        child: const Icon(Icons.upload_file),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: WorkplaceService().collectionForCompany(Collections.documents, companyId),
        builder: (context, snapshot) {
          final docs = snapshot.data ?? [];
          return ListView(
            children: [
              ...folders.map(
                (folder) => ExpansionTile(
                  leading: const Icon(Icons.folder, color: AppColors.warning),
                  title: Text(folder, style: const TextStyle(fontWeight: FontWeight.w700)),
                  children: docs
                      .where((d) => d['folder'] == folder)
                      .map((d) => ListTile(title: Text(d['title'] as String? ?? 'Document')))
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _add(BuildContext context, UserProfile? profile) async {
    if (profile == null) return;
    final title = TextEditingController();
    String folder = 'Company Policies';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: title, decoration: const InputDecoration(hintText: 'Title')),
            DropdownButtonFormField<String>(
              initialValue: folder,
              items: const ['Company Policies', 'Employee Documents', 'Contracts', 'Attendance Reports', 'Meeting Documents', 'Announcements']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (value) => folder = value ?? folder,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && title.text.trim().isNotEmpty) {
      await WorkplaceService().addDocument(profile: profile, title: title.text.trim(), folder: folder);
    }
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final companyId = context.watch<AuthController>().profile?.companyId ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: FutureBuilder(
        future: Future.wait([
          WorkplaceService().employees(companyId).first,
          WorkplaceService().todayAttendance(companyId),
          WorkplaceService().offices(companyId).first,
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final employees = snapshot.data![0] as List<Employee>;
          final records = snapshot.data![1] as List;
          final offices = snapshot.data![2] as List<Office>;
          final presentIds = records.map((r) => (r as dynamic).employeeId as String).toSet();
          final late = records.where((r) {
            final time = (r as dynamic).timestamp as DateTime;
            return time.hour > 9 || (time.hour == 9 && time.minute >= 15);
          }).length;
          final present = presentIds.length;
          final absent = (employees.length - present).clamp(0, 9999);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatCard(label: 'Employees', value: '${employees.length}'),
              _StatCard(label: 'Present', value: '$present', color: AppColors.accent),
              _StatCard(label: 'Late', value: '$late', color: AppColors.warning),
              _StatCard(label: 'Absent', value: '$absent', color: AppColors.danger),
              const SizedBox(height: 12),
              ...offices.map((office) {
                final count = records.where((r) => (r as dynamic).officeId == office.id).length;
                return ListTile(title: Text(office.name), trailing: Text('$count'));
              }),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
      ),
    );
  }
}

class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('This alerts authorized company contacts with your identity, time, and GPS. Location sharing is opt-in.'),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'EMERGENCY',
              color: AppColors.danger,
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm emergency'),
                    content: const Text('Notify authorized company contacts now?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
                    ],
                  ),
                );
                if (ok != true || profile == null) return;
                final fix = await LocationService().currentFix();
                await WorkplaceService().sendSos(profile: profile, latitude: fix.latitude, longitude: fix.longitude, type: 'SOS');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Emergency sent to authorized contacts')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class RecognitionScreen extends StatelessWidget {
  const RecognitionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    final companyId = profile?.companyId ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Recognition')),
      floatingActionButton: profile?.isManagerOrAbove == true
          ? FloatingActionButton(
              onPressed: () => _give(context, profile),
              child: const Icon(Icons.star),
            )
          : null,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: WorkplaceService().collectionForCompany(Collections.recognition, companyId),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const EmptyHint(icon: Icons.emoji_events_outlined, title: 'No badges yet', subtitle: 'Managers can award Employee of the Month and other recognition.');
          }
          return ListView(
            children: items
                .map(
                  (item) => ListTile(
                    leading: const Text('🏆', style: TextStyle(fontSize: 24)),
                    title: Text(item['badge'] as String? ?? 'Badge', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(item['employeeName'] as String? ?? ''),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  Future<void> _give(BuildContext context, UserProfile? profile) async {
    if (profile == null) return;
    final name = TextEditingController();
    String badge = 'Employee of the Month';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Give recognition'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(hintText: 'Employee name')),
            DropdownButtonFormField<String>(
              initialValue: badge,
              items: const ['Employee of the Month', 'Best Attendance', 'Best Team Player', 'Customer Champion']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (value) => badge = value ?? badge,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Award')),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      await WorkplaceService().giveBadge(profile: profile, employeeName: name.text.trim(), badge: badge);
    }
  }
}
