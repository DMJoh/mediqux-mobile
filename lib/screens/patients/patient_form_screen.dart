import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mediqux_mobile/models/patient/patient.dart';
import 'package:mediqux_mobile/models/patient/patient_request.dart';
import 'package:mediqux_mobile/providers/patient_provider.dart';
import 'package:mediqux_mobile/utils/error_utils.dart';
import 'package:mediqux_mobile/widgets/form_section.dart';
import 'package:mediqux_mobile/widgets/gradient_button.dart';

class PatientFormScreen extends ConsumerStatefulWidget {
  const PatientFormScreen({super.key, this.patientId});

  final String? patientId;

  @override
  ConsumerState<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends ConsumerState<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedDate;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _dobCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  void _initFromPatient(Patient patient) {
    _firstNameCtrl.text = patient.firstName;
    _lastNameCtrl.text = patient.lastName;
    _phoneCtrl.text = patient.phone ?? '';
    _emailCtrl.text = patient.email ?? '';
    _addressCtrl.text = patient.address ?? '';
    _emergencyNameCtrl.text = patient.emergencyContactName ?? '';
    _emergencyPhoneCtrl.text = patient.emergencyContactPhone ?? '';
    _selectedGender = patient.gender;
    if (patient.dateOfBirth != null && patient.dateOfBirth!.isNotEmpty) {
      final dob = DateTime.tryParse(patient.dateOfBirth!);
      if (dob != null) {
        _selectedDate = DateTime(dob.year, dob.month, dob.day);
        _dobCtrl.text = DateFormat('MMM d, yyyy').format(_selectedDate!);
      }
    }
    _initialized = true;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ??
          DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      _dobCtrl.text = DateFormat('MMM d, yyyy').format(picked);
    });
  }

  String? _dobAsIso() {
    if (_selectedDate == null) return null;
    final d = _selectedDate!;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _isSaving = true);
    final request = PatientRequest(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      dateOfBirth: _dobAsIso(),
      gender: _selectedGender,
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      emergencyContactName: _emergencyNameCtrl.text.trim().isEmpty
          ? null
          : _emergencyNameCtrl.text.trim(),
      emergencyContactPhone: _emergencyPhoneCtrl.text.trim().isEmpty
          ? null
          : _emergencyPhoneCtrl.text.trim(),
    );
    try {
      if (widget.patientId == null) {
        await ref.read(patientsProvider.notifier).create(request);
      } else {
        await ref
            .read(patientsProvider.notifier)
            .savePatient(widget.patientId!, request);
        ref.invalidate(patientDetailProvider(widget.patientId!));
      }
      if (mounted) context.pop();
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.patientId != null;

    if (isEdit && !_initialized) {
      ref.watch(patientDetailProvider(widget.patientId!)).whenData((p) {
        if (!_initialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _initFromPatient(p));
          });
        }
      });
      if (!_initialized) {
        return Scaffold(
          appBar: AppBar(title: Text(isEdit ? 'Edit Patient' : 'Add Patient')),
          body: const Center(
            child: CircularProgressIndicator(
              strokeCap: StrokeCap.round,
              strokeWidth: 3,
            ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: isEdit
            ? BackButton(onPressed: () => context.pop())
            : CloseButton(onPressed: () => context.pop()),
        title: Text(isEdit ? 'Edit Patient' : 'Add Patient'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GradientButton(
              compact: true,
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FormSection(
                title: 'Personal',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'First Name *',
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Last Name *',
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _dobCtrl,
                          decoration: InputDecoration(
                            labelText: 'Date of Birth',
                            suffixIcon: Icon(
                              Icons.calendar_today_outlined,
                              color: cs.primary,
                              size: 20,
                            ),
                          ),
                          readOnly: true,
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          // value updates display on every rebuild;
                          // initialValue only sets once, breaking edit
                          // pre-fill.
                          // ignore: deprecated_member_use
                          value: _selectedGender,
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Male',
                              child: Text('Male'),
                            ),
                            DropdownMenuItem(
                              value: 'Female',
                              child: Text('Female'),
                            ),
                            DropdownMenuItem(
                              value: 'Other',
                              child: Text('Other'),
                            ),
                          ],
                          onChanged: (v) => setState(() => _selectedGender = v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FormSection(
                title: 'Contact',
                children: [
                  TextFormField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return null;
                      }
                      final clean = v.trim();
                      final valid = RegExp(r'^[0-9+\s\-]+$').hasMatch(clean);
                      return valid ? null : 'Invalid phone number';
                    },
                  ),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return null;
                      }
                      final valid = RegExp(
                        r'^[^@]+@[^@]+\.[^@]+$',
                      ).hasMatch(v.trim());
                      return valid ? null : 'Invalid email address';
                    },
                  ),
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(labelText: 'Address'),
                    maxLines: 3,
                    keyboardType: TextInputType.multiline,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FormSection(
                title: 'Emergency Contact',
                children: [
                  TextFormField(
                    controller: _emergencyNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Contact Name',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  TextFormField(
                    controller: _emergencyPhoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Contact Phone',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return null;
                      }
                      final valid = RegExp(r'^[0-9+\s\-]+$').hasMatch(v.trim());
                      return valid ? null : 'Invalid phone number';
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
