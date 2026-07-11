import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mediqux_mobile/models/appointment/appointment.dart';
import 'package:mediqux_mobile/models/medication/medication.dart';
import 'package:mediqux_mobile/models/prescription/prescription.dart';
import 'package:mediqux_mobile/models/prescription/prescription_request.dart';
import 'package:mediqux_mobile/providers/appointment_provider.dart';
import 'package:mediqux_mobile/providers/medication_provider.dart';
import 'package:mediqux_mobile/providers/prescription_provider.dart';
import 'package:mediqux_mobile/utils/error_utils.dart';

const _kFrequencies = [
  'Once daily',
  'Twice daily',
  '3 times daily',
  '4 times daily',
  'Every 6 hours',
  'Every 8 hours',
  'Every 12 hours',
  'As needed',
  'Weekly',
  'Monthly',
];

const _kStatuses = ['active', 'discontinued', 'completed'];

class PrescriptionFormScreen extends ConsumerStatefulWidget {
  const PrescriptionFormScreen({super.key, this.prescriptionId});

  final String? prescriptionId;

  @override
  ConsumerState<PrescriptionFormScreen> createState() =>
      _PrescriptionFormScreenState();
}

class _PrescriptionFormScreenState
    extends ConsumerState<PrescriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dosageCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();

  String? _selectedAppointmentId;
  String? _selectedMedicationId;
  String? _selectedFrequency;
  String _selectedStatus = 'active';

  bool _isSaving = false;
  bool _initialized = false;
  bool _loadingDropdowns = true;

  List<Appointment> _appointments = [];
  List<Medication> _medications = [];

  bool get _isEdit => widget.prescriptionId != null;

  @override
  void initState() {
    super.initState();
    final aA = ref.read(appointmentsProvider);
    final mA = ref.read(medicationsProvider);
    if (aA.hasValue && !aA.isLoading && mA.hasValue && !mA.isLoading) {
      _appointments = aA.requireValue;
      _medications = mA.requireValue;
      _loadingDropdowns = false;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final results = await Future.wait([
          ref.read(appointmentsProvider.future),
          ref.read(medicationsProvider.future),
        ]);
        if (mounted) {
          setState(() {
            _appointments = results[0] as List<Appointment>;
            _medications = results[1] as List<Medication>;
            _loadingDropdowns = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _dosageCtrl.dispose();
    _durationCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  void _initFrom(Prescription rx) {
    _selectedAppointmentId = rx.appointmentId;
    _selectedMedicationId = rx.medicationId;
    _dosageCtrl.text = rx.dosage;
    _selectedFrequency = _kFrequencies.contains(rx.frequency)
        ? rx.frequency
        : null;
    _durationCtrl.text = rx.duration;
    _instructionsCtrl.text = rx.instructions ?? '';
    _selectedStatus = rx.status ?? 'active';
    _initialized = true;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    final request = PrescriptionRequest(
      appointmentId: _selectedAppointmentId!,
      medicationId: _selectedMedicationId!,
      dosage: _dosageCtrl.text.trim(),
      frequency: _selectedFrequency ?? _dosageCtrl.text.trim(),
      duration: _durationCtrl.text.trim(),
      instructions: _instructionsCtrl.text.trim().isEmpty
          ? null
          : _instructionsCtrl.text.trim(),
      status: _selectedStatus,
    );
    try {
      if (!_isEdit) {
        await ref.read(prescriptionsProvider.notifier).create(request);
      } else {
        await ref
            .read(prescriptionsProvider.notifier)
            .savePrescription(widget.prescriptionId!, request);
        ref.invalidate(prescriptionDetailProvider(widget.prescriptionId!));
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

  String _aptLabel(Appointment apt) {
    final dateStr = DateFormat('MMM d, yyyy').format(apt.appointmentDate);
    return '$dateStr – ${apt.patientName}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isEdit && !_initialized) {
      ref.watch(prescriptionDetailProvider(widget.prescriptionId!)).whenData((
        rx,
      ) {
        if (!_initialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _initFrom(rx));
          });
        }
      });
      if (!_initialized) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Prescription'),
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
          _isEdit ? 'Edit Prescription' : 'New Prescription',
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
                // Appointment dropdown
                // ignore: deprecated_member_use
                DropdownButtonFormField<String>(
                  // Deprecated in favour of DropdownMenu.
                  // ignore: deprecated_member_use
                  value: _selectedAppointmentId,
                  decoration: const InputDecoration(labelText: 'Appointment *'),
                  isExpanded: true,
                  items: _appointments
                      .map(
                        (a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(
                            _aptLabel(a),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedAppointmentId = v),
                  validator: (v) =>
                      v == null ? 'Appointment is required' : null,
                ),
                const SizedBox(height: 12),
                // Medication dropdown
                // ignore: deprecated_member_use
                DropdownButtonFormField<String>(
                  // Deprecated in favour of DropdownMenu.
                  // ignore: deprecated_member_use
                  value: _selectedMedicationId,
                  decoration: const InputDecoration(labelText: 'Medication *'),
                  isExpanded: true,
                  items: _medications
                      .map(
                        (m) => DropdownMenuItem(
                          value: m.id,
                          child: Text(m.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedMedicationId = v),
                  validator: (v) => v == null ? 'Medication is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dosageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dosage *',
                    hintText: 'e.g. 500mg',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Dosage is required'
                      : null,
                ),
                const SizedBox(height: 12),
                // Frequency dropdown
                // ignore: deprecated_member_use
                DropdownButtonFormField<String>(
                  // Deprecated in favour of DropdownMenu.
                  // ignore: deprecated_member_use
                  value: _selectedFrequency,
                  decoration: const InputDecoration(labelText: 'Frequency *'),
                  items: _kFrequencies
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedFrequency = v),
                  validator: (v) => v == null ? 'Frequency is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _durationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Duration *',
                    hintText: 'e.g. 7 days',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Duration is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _instructionsCtrl,
                  decoration: const InputDecoration(labelText: 'Instructions'),
                  maxLines: 3,
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
                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
