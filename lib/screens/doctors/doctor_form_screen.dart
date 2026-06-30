import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mediqux_mobile/models/doctor/doctor.dart';
import 'package:mediqux_mobile/models/doctor/doctor_request.dart';
import 'package:mediqux_mobile/providers/doctor_provider.dart';

class DoctorFormScreen extends ConsumerStatefulWidget {
  const DoctorFormScreen({super.key, this.doctorId});

  final String? doctorId;

  @override
  ConsumerState<DoctorFormScreen> createState() => _DoctorFormScreenState();
}

class _DoctorFormScreenState extends ConsumerState<DoctorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _specialtyCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _selectedInstitutionIds = <String>{};
  bool _isSaving = false;
  bool _initialized = false;

  bool get _isEdit => widget.doctorId != null;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _specialtyCtrl.dispose();
    _licenseCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _initFrom(Doctor doctor) {
    _firstNameCtrl.text = doctor.firstName;
    _lastNameCtrl.text = doctor.lastName;
    _specialtyCtrl.text = doctor.specialty ?? '';
    _licenseCtrl.text = doctor.licenseNumber ?? '';
    _phoneCtrl.text = doctor.phone ?? '';
    _emailCtrl.text = doctor.email ?? '';
    _selectedInstitutionIds
      ..clear()
      ..addAll((doctor.institutions ?? []).map((i) => i.id));
    _initialized = true;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    final request = DoctorRequest(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      specialty: _specialtyCtrl.text.trim().isEmpty
          ? null
          : _specialtyCtrl.text.trim(),
      licenseNumber: _licenseCtrl.text.trim().isEmpty
          ? null
          : _licenseCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      institutionIds: _selectedInstitutionIds.toList(),
    );
    try {
      if (!_isEdit) {
        await ref.read(doctorsProvider.notifier).create(request);
      } else {
        await ref
            .read(doctorsProvider.notifier)
            .saveDoctor(widget.doctorId!, request);
        ref.invalidate(doctorDetailProvider(widget.doctorId!));
      }
      if (mounted) context.pop();
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_isEdit && !_initialized) {
      ref.watch(doctorDetailProvider(widget.doctorId!)).whenData((doctor) {
        if (!_initialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _initFrom(doctor));
          });
        }
      });
      if (!_initialized) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Doctor'),
            backgroundColor: cs.surface,
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
    }

    final availableAsync = ref.watch(availableInstitutionsProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: _isEdit
            ? BackButton(color: cs.onSurface, onPressed: () => context.pop())
            : CloseButton(color: cs.onSurface, onPressed: () => context.pop()),
        title: Text(
          _isEdit ? 'Edit Doctor' : 'Add Doctor',
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _firstNameCtrl,
                decoration: const InputDecoration(labelText: 'First Name *'),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'First name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameCtrl,
                decoration: const InputDecoration(labelText: 'Last Name *'),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Last name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _specialtyCtrl,
                decoration: const InputDecoration(labelText: 'Specialty'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _licenseCtrl,
                decoration: const InputDecoration(labelText: 'License Number'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return null;
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                    return 'Invalid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Institutions',
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 8),
              availableAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Text(
                  'Could not load institutions: $e',
                  style: TextStyle(color: cs.error),
                ),
                data: (institutions) {
                  if (institutions.isEmpty) {
                    return Text(
                      'No institutions available.',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    );
                  }
                  return Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: institutions.map((inst) {
                        final id = inst['id'] ?? '';
                        final name = inst['name'] ?? '';
                        final type = inst['type'] ?? '';
                        return CheckboxListTile(
                          value: _selectedInstitutionIds.contains(id),
                          onChanged: (checked) {
                            setState(() {
                              if (checked ?? false) {
                                _selectedInstitutionIds.add(id);
                              } else {
                                _selectedInstitutionIds.remove(id);
                              }
                            });
                          },
                          title: Text(
                            name,
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: type.isNotEmpty ? Text(type) : null,
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
