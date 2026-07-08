import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mediqux_mobile/models/appointment/appointment.dart';
import 'package:mediqux_mobile/models/patient/patient.dart';
import 'package:mediqux_mobile/providers/appointment_provider.dart';
import 'package:mediqux_mobile/providers/lab_report_provider.dart';
import 'package:mediqux_mobile/providers/patient_provider.dart';

class LabReportFormScreen extends ConsumerStatefulWidget {
  const LabReportFormScreen({super.key});

  @override
  ConsumerState<LabReportFormScreen> createState() =>
      _LabReportFormScreenState();
}

class _LabReportFormScreenState extends ConsumerState<LabReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _testNameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _selectedPatientId;
  String? _selectedAppointmentId;
  DateTime? _selectedDate;
  String? _filePath;
  String? _fileName;

  bool _isSaving = false;
  bool _loadingDropdowns = true;

  List<Patient> _patients = [];
  List<Appointment> _appointments = [];

  @override
  void initState() {
    super.initState();
    final pA = ref.read(patientsProvider);
    final aA = ref.read(appointmentsProvider);
    if (pA.hasValue && aA.hasValue) {
      _patients = pA.requireValue;
      _appointments = aA.requireValue;
      _loadingDropdowns = false;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final results = await Future.wait([
          ref.read(patientsProvider.future),
          ref.read(appointmentsProvider.future),
        ]);
        if (mounted) {
          setState(() {
            _patients = results[0] as List<Patient>;
            _appointments = results[1] as List<Appointment>;
            _loadingDropdowns = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _testNameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      final path = result.files.single.path;
      if (path != null) {
        setState(() {
          _filePath = path;
          _fileName = result.files.single.name;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a test date')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      if (_filePath != null) {
        await ref
            .read(labReportsProvider.notifier)
            .upload(
              patientId: _selectedPatientId!,
              testName: _testNameCtrl.text.trim(),
              testDate: _selectedDate!,
              appointmentId: _selectedAppointmentId,
              notes: _notesCtrl.text.trim().isEmpty
                  ? null
                  : _notesCtrl.text.trim(),
              filePath: _filePath!,
              fileName: _fileName!,
            );
      } else {
        await ref
            .read(labReportsProvider.notifier)
            .create(
              patientId: _selectedPatientId!,
              testName: _testNameCtrl.text.trim(),
              testDate: _selectedDate!,
              appointmentId: _selectedAppointmentId,
              notes: _notesCtrl.text.trim().isEmpty
                  ? null
                  : _notesCtrl.text.trim(),
            );
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

  String _aptLabel(Appointment apt) {
    final dateFmt = DateFormat('MMM d, yyyy');
    final dateStr = dateFmt.format(apt.appointmentDate);
    return '$dateStr – ${apt.patientName}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final dateFmt = DateFormat('MMM d, yyyy');

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: CloseButton(
          color: cs.onSurface,
          onPressed: () => context.pop(),
        ),
        title: Text(
          'New Lab Report',
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
              if (_loadingDropdowns)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                // Patient dropdown
                // ignore: deprecated_member_use
                DropdownButtonFormField<String>(
                  // Deprecated in favour of DropdownMenu.
                  // ignore: deprecated_member_use
                  value: _selectedPatientId,
                  decoration: const InputDecoration(labelText: 'Patient *'),
                  items: _patients
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.fullName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedPatientId = v),
                  validator: (v) => v == null ? 'Patient is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _testNameCtrl,
                  decoration: const InputDecoration(labelText: 'Test Name *'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Test name is required'
                      : null,
                ),
                const SizedBox(height: 12),
                // Date picker
                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Test Date *',
                        hintText: 'Select date',
                        suffixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                      controller: TextEditingController(
                        text: _selectedDate != null
                            ? dateFmt.format(_selectedDate!)
                            : '',
                      ),
                      validator: (_) =>
                          _selectedDate == null ? 'Date is required' : null,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Appointment dropdown (optional)
                // ignore: deprecated_member_use
                DropdownButtonFormField<String>(
                  // Deprecated in favour of DropdownMenu.
                  // ignore: deprecated_member_use
                  value: _selectedAppointmentId,
                  decoration: const InputDecoration(
                    labelText: 'Appointment (optional)',
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(child: Text('None')),
                    ..._appointments.map(
                      (a) => DropdownMenuItem(
                        value: a.id,
                        child: Text(
                          _aptLabel(a),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedAppointmentId = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                // PDF upload
                OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Upload PDF (optional)'),
                ),
                if (_fileName != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.picture_as_pdf_rounded,
                        size: 18,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _fileName!,
                          style: tt.bodySmall?.copyWith(color: cs.primary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        onPressed: () => setState(() {
                          _filePath = null;
                          _fileName = null;
                        }),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
