import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mediqux_mobile/models/appointment/appointment.dart';
import 'package:mediqux_mobile/models/appointment/appointment_request.dart';
import 'package:mediqux_mobile/models/doctor/doctor.dart';
import 'package:mediqux_mobile/models/institution/institution.dart';
import 'package:mediqux_mobile/models/patient/patient.dart';
import 'package:mediqux_mobile/providers/appointment_provider.dart';
import 'package:mediqux_mobile/providers/doctor_provider.dart';
import 'package:mediqux_mobile/providers/institution_provider.dart';
import 'package:mediqux_mobile/providers/patient_provider.dart';

const _kTypes = [
  'Consultation',
  'Follow-up',
  'Emergency',
  'Routine',
  'Specialist',
  'Surgery',
  'Lab Test',
  'Imaging',
  'Other',
];

const _kStatuses = ['scheduled', 'completed', 'cancelled'];

class AppointmentFormScreen extends ConsumerStatefulWidget {
  const AppointmentFormScreen({super.key, this.appointmentId});

  final String? appointmentId;

  @override
  ConsumerState<AppointmentFormScreen> createState() =>
      _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends ConsumerState<AppointmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();

  String? _selectedPatientId;
  String? _selectedDoctorId;
  String? _selectedInstitutionId;
  String? _selectedType;
  String _selectedStatus = 'scheduled';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isSaving = false;
  bool _initialized = false;

  List<Patient> _patients = [];
  List<Doctor> _doctors = [];
  List<Institution> _institutions = [];
  bool _loadingDropdowns = true;

  bool get _isEdit => widget.appointmentId != null;

  @override
  void initState() {
    super.initState();
    final pA = ref.read(patientsProvider);
    final dA = ref.read(doctorsProvider);
    final iA = ref.read(institutionsProvider);
    if (pA.hasValue && dA.hasValue && iA.hasValue) {
      _patients = pA.requireValue;
      _doctors = dA.requireValue;
      _institutions = iA.requireValue;
      _loadingDropdowns = false;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final results = await Future.wait([
          ref.read(patientsProvider.future),
          ref.read(doctorsProvider.future),
          ref.read(institutionsProvider.future),
        ]);
        if (mounted) {
          setState(() {
            _patients = results[0] as List<Patient>;
            _doctors = results[1] as List<Doctor>;
            _institutions = results[2] as List<Institution>;
            _loadingDropdowns = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _diagnosisCtrl.dispose();
    super.dispose();
  }

  void _initFrom(Appointment apt) {
    _selectedPatientId = apt.patientId;
    _selectedDoctorId = apt.doctorId;
    _selectedInstitutionId = apt.institutionId;
    _selectedType = apt.type;
    _selectedStatus = apt.status;
    _selectedDate = apt.appointmentDate;
    _selectedTime = TimeOfDay.fromDateTime(apt.appointmentDate);
    _notesCtrl.text = apt.notes ?? '';
    _diagnosisCtrl.text = apt.diagnosis ?? '';
    _initialized = true;
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

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  String _formatDateTime() {
    if (_selectedDate == null) return '';
    final dateFmt = DateFormat('MMM d, yyyy');
    final dateStr = dateFmt.format(_selectedDate!);
    if (_selectedTime == null) return dateStr;
    final h = _selectedTime!.hour.toString().padLeft(2, '0');
    final m = _selectedTime!.minute.toString().padLeft(2, '0');
    return '$dateStr  $h:$m';
  }

  DateTime _combinedDateTime() {
    final d = _selectedDate!;
    final t = _selectedTime ?? const TimeOfDay(hour: 0, minute: 0);
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time')),
      );
      return;
    }
    setState(() => _isSaving = true);
    final dt = _combinedDateTime();
    final request = AppointmentRequest(
      patientId: _selectedPatientId!,
      appointmentDate: dt.toIso8601String(),
      doctorId: _selectedDoctorId,
      institutionId: _selectedInstitutionId,
      type: _selectedType,
      status: _selectedStatus,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      diagnosis: _diagnosisCtrl.text.trim().isEmpty
          ? null
          : _diagnosisCtrl.text.trim(),
    );
    try {
      if (!_isEdit) {
        await ref.read(appointmentsProvider.notifier).create(request);
      } else {
        await ref
            .read(appointmentsProvider.notifier)
            .saveAppointment(widget.appointmentId!, request);
        ref.invalidate(appointmentDetailProvider(widget.appointmentId!));
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

    if (_isEdit && !_initialized) {
      ref.watch(appointmentDetailProvider(widget.appointmentId!)).whenData((
        apt,
      ) {
        if (!_initialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _initFrom(apt));
          });
        }
      });
      if (!_initialized) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Appointment'),
            backgroundColor: cs.surface,
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: _isEdit
            ? BackButton(color: cs.onSurface, onPressed: () => context.pop())
            : CloseButton(color: cs.onSurface, onPressed: () => context.pop()),
        title: Text(
          _isEdit ? 'Edit Appointment' : 'New Appointment',
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
                // Date & Time
                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Date & Time *',
                        hintText: 'Select date and time',
                        suffixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                      controller: TextEditingController(
                        text: _formatDateTime(),
                      ),
                      validator: (_) =>
                          _selectedDate == null ? 'Date is required' : null,
                    ),
                  ),
                ),
                if (_selectedDate != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time_rounded),
                    label: Text(
                      _selectedTime != null
                          ? 'Time: ${_selectedTime!.format(context)}'
                          : 'Pick time',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // Type dropdown
                // ignore: deprecated_member_use
                DropdownButtonFormField<String>(
                  // Deprecated in favour of DropdownMenu.
                  // ignore: deprecated_member_use
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: _kTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedType = v),
                ),
                const SizedBox(height: 12),
                // Status dropdown
                // ignore: deprecated_member_use
                DropdownButtonFormField<String>(
                  // Deprecated in favour of DropdownMenu.
                  // ignore: deprecated_member_use
                  value: _selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: _kStatuses
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedStatus = v);
                  },
                ),
                const SizedBox(height: 12),
                // Doctor dropdown
                // ignore: deprecated_member_use
                DropdownButtonFormField<String>(
                  // Deprecated in favour of DropdownMenu.
                  // ignore: deprecated_member_use
                  value: _selectedDoctorId,
                  decoration: const InputDecoration(labelText: 'Doctor'),
                  items: [
                    const DropdownMenuItem(child: Text('None')),
                    ..._doctors.map(
                      (d) => DropdownMenuItem(
                        value: d.id,
                        child: Text(d.fullName),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedDoctorId = v),
                ),
                const SizedBox(height: 12),
                // Institution dropdown
                // ignore: deprecated_member_use
                DropdownButtonFormField<String>(
                  // Deprecated in favour of DropdownMenu.
                  // ignore: deprecated_member_use
                  value: _selectedInstitutionId,
                  decoration: const InputDecoration(labelText: 'Institution'),
                  items: [
                    const DropdownMenuItem(child: Text('None')),
                    ..._institutions.map(
                      (i) => DropdownMenuItem(value: i.id, child: Text(i.name)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedInstitutionId = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _diagnosisCtrl,
                  decoration: const InputDecoration(labelText: 'Diagnosis'),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
