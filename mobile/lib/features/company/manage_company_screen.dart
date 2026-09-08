import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../models/company.dart';
import '../../providers/auth_controller.dart';
import '../../services/workplace_service.dart';

class ManageCompanyScreen extends StatefulWidget {
  const ManageCompanyScreen({super.key});

  @override
  State<ManageCompanyScreen> createState() => _ManageCompanyScreenState();
}

class _ManageCompanyScreenState extends State<ManageCompanyScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController(text: '+971');
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController(text: 'United Arab Emirates');
  final _notes = TextEditingController();
  String? _editingId;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _city.dispose();
    _country.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _fill(Company company) {
    setState(() {
      _editingId = company.id;
      _name.text = company.name;
      _phone.text = company.phone.isEmpty ? '+971' : company.phone;
      _email.text = company.email;
      _address.text = company.address;
      _city.text = company.city;
      _country.text = company.country.isEmpty ? 'United Arab Emirates' : company.country;
      _notes.text = company.notes;
      _error = null;
    });
  }

  void _clear() {
    setState(() {
      _editingId = null;
      _name.clear();
      _phone.text = '+971';
      _email.clear();
      _address.clear();
      _city.clear();
      _country.text = 'United Arab Emirates';
      _notes.clear();
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 2) {
      setState(() => _error = 'Enter a company name.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final service = WorkplaceService();
      if (_editingId == null) {
        await service.createCompany(
          name: _name.text,
          phone: _phone.text,
          email: _email.text,
          address: _address.text,
          city: _city.text,
          country: _country.text,
          notes: _notes.text,
        );
      } else {
        await service.updateCompany(
          id: _editingId!,
          name: _name.text,
          phone: _phone.text,
          email: _email.text,
          address: _address.text,
          city: _city.text,
          country: _country.text,
          notes: _notes.text,
        );
      }
      if (!mounted) return;
      await context.read<AuthController>().refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_editingId == null ? 'Company created' : 'Company updated')),
        );
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(Company company) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete company'),
        content: Text('Delete ${company.name}? Employees cannot do this. Only admin can.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await WorkplaceService().deleteCompany(company.id);
    if (!mounted) return;
    await context.read<AuthController>().refreshProfile();
    if (!mounted) return;
    if (_editingId == company.id) _clear();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    if (profile?.isAdmin != true) {
      return const Scaffold(
        body: EmptyHint(
          icon: Icons.lock_outline,
          title: 'Admin only',
          subtitle: 'Only administrators can create, edit, or delete a company.',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Manage company')),
      body: StreamBuilder<List<Company>>(
        stream: WorkplaceService().watchCompanies(),
        builder: (context, snapshot) {
          final companies = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Existing companies', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (companies.isEmpty)
                const Text('No company yet. Create one below.', style: TextStyle(color: AppColors.muted)),
              ...companies.map(
                (company) => Card(
                  child: ListTile(
                    title: Text(company.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text([company.city, company.phone].where((v) => v.isNotEmpty).join(' · ')),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(onPressed: () => _fill(company), child: const Text('Edit')),
                        TextButton(
                          onPressed: () => _delete(company),
                          child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(_editingId == null ? 'Create company' : 'Edit company', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 8),
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'Company name')),
              const SizedBox(height: 8),
              TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 8),
              TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 8),
              TextField(controller: _address, decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: 8),
              TextField(controller: _city, decoration: const InputDecoration(labelText: 'City')),
              const SizedBox(height: 8),
              TextField(controller: _country, decoration: const InputDecoration(labelText: 'Country')),
              const SizedBox(height: 8),
              TextField(controller: _notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes')),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ],
              const SizedBox(height: 16),
              PrimaryButton(label: _editingId == null ? 'Create company' : 'Save changes', loading: _busy, onPressed: _save),
              if (_editingId != null)
                TextButton(onPressed: _clear, child: const Text('Create another company')),
            ],
          );
        },
      ),
    );
  }
}
