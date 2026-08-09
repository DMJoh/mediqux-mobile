import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mediqux_mobile/models/appointment/appointment.dart';
import 'package:mediqux_mobile/models/doctor/doctor.dart';
import 'package:mediqux_mobile/models/institution/institution.dart';
import 'package:mediqux_mobile/models/lab_panel/lab_panel.dart';
import 'package:mediqux_mobile/models/lab_report/lab_report.dart';
import 'package:mediqux_mobile/models/patient/patient.dart';
import 'package:mediqux_mobile/providers/appointment_provider.dart';
import 'package:mediqux_mobile/providers/doctor_provider.dart';
import 'package:mediqux_mobile/providers/institution_provider.dart';
import 'package:mediqux_mobile/providers/lab_report_provider.dart';
import 'package:mediqux_mobile/providers/patient_provider.dart';
import 'package:mediqux_mobile/utils/error_utils.dart';

const _testTypes = [
  'Blood',
  'Urine',
  'X-Ray',
  'MRI',
  'CT',
  'Ultrasound',
  'ECG',
  'Pathology',
  'Other',
];

const _statuses = ['Normal', 'High', 'Low', 'Critical', 'Abnormal'];

class _LabValueEntry {
  _LabValueEntry({String? parameterName, String? unit, String? referenceRange})
    : parameterNameCtrl = TextEditingController(text: parameterName ?? ''),
      valueCtrl = TextEditingController(),
      unitCtrl = TextEditingController(text: unit ?? ''),
      referenceRangeCtrl = TextEditingController(text: referenceRange ?? ''),
      status = 'Normal';

  final TextEditingController parameterNameCtrl;
  final TextEditingController valueCtrl;
  final TextEditingController unitCtrl;
  final TextEditingController referenceRangeCtrl;
  String status;

  void dispose() {
    parameterNameCtrl.dispose();
    valueCtrl.dispose();
    unitCtrl.dispose();
    referenceRangeCtrl.dispose();
  }

  Map<String, dynamic> toJson() => {
    'parameter_name': parameterNameCtrl.text.trim(),
    'value': double.tryParse(valueCtrl.text.trim()) ?? 0,
    'unit': unitCtrl.text.trim().isEmpty ? null : unitCtrl.text.trim(),
    'reference_range': referenceRangeCtrl.text.trim().isEmpty
        ? null
        : referenceRangeCtrl.text.trim(),
    'status': status.toLowerCase(),
  };

  bool get hasName => parameterNameCtrl.text.trim().isNotEmpty;
  bool get hasValue => valueCtrl.text.trim().isNotEmpty;
}

class LabReportFormScreen extends ConsumerStatefulWidget {
  const LabReportFormScreen({super.key, this.reportId});

  final String? reportId;

  @override
  ConsumerState<LabReportFormScreen> createState() =>
      _LabReportFormScreenState();
}

class _LabReportFormScreenState extends ConsumerState<LabReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _testNameCtrl = TextEditingController();

  String? _selectedPatientId;
  String? _selectedAppointmentId;
  String? _selectedTestType;
  String? _selectedInstitutionId;
  String? _selectedDoctorId;
  DateTime? _selectedDate;
  String? _filePath;
  String? _fileName;

  final List<_LabValueEntry> _labValues = [];

  bool _isSaving = false;
  bool _loadingDropdowns = true;
  bool _initialized = false;

  List<Patient> _patients = [];
  List<Appointment> _appointments = [];
  List<Doctor> _doctors = [];
  List<Institution> _institutions = [];

  bool get _isEdit => widget.reportId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final results = await Future.wait([
        ref.read(patientsProvider.future),
        ref.read(appointmentsProvider.future),
        ref.read(doctorsProvider.future),
        ref.read(institutionsProvider.future),
      ]);
      if (mounted) {
        setState(() {
          _patients = results[0] as List<Patient>;
          _appointments = results[1] as List<Appointment>;
          _doctors = results[2] as List<Doctor>;
          _institutions = results[3] as List<Institution>;
          _loadingDropdowns = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _testNameCtrl.dispose();
    for (final e in _labValues) {
      e.dispose();
    }
    super.dispose();
  }

  void _populateFromReport() {
    if (_initialized || !_isEdit) return;
    ref.read(labReportDetailProvider(widget.reportId!)).whenData((report) {
      _testNameCtrl.text = report.testName;
      _selectedTestType = report.testType;
      _selectedDate = report.testDate;
      _selectedPatientId = report.patientId;
      _selectedAppointmentId = report.appointmentId;
      _selectedInstitutionId =
          _institutions.any((i) => i.name == report.institutionName)
          ? _institutions
              .firstWhere((i) => i.name == report.institutionName)
              .id
          : null;
      _selectedDoctorId = report.performedBy != null
          ? _doctors
              .where((d) => d.id == report.performedBy!.id)
              .map((d) => d.id)
              .firstOrNull
          : null;
      for (final lv in report.labValues ?? <LabValue>[]) {
        final entry = _LabValueEntry(
          parameterName: lv.parameterName,
          unit: lv.unit,
          referenceRange: lv.referenceRange,
        );
        entry.valueCtrl.text = lv.value == lv.value.truncateToDouble()
            ? lv.value.toInt().toString()
            : lv.value.toStringAsFixed(2);
        entry.status =
            lv.status[0].toUpperCase() + lv.status.substring(1);
        if (!_statuses.contains(entry.status)) entry.status = 'Normal';
        _labValues.add(entry);
      }
      _initialized = true;
    });
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

  void _addLabValueRow({
    String? parameterName,
    String? unit,
    String? referenceRange,
  }) {
    setState(() {
      _labValues.add(
        _LabValueEntry(
          parameterName: parameterName,
          unit: unit,
          referenceRange: referenceRange,
        ),
      );
    });
  }

  void _removeLabValueRow(int index) {
    setState(() {
      _labValues[index].dispose();
      _labValues.removeAt(index);
    });
  }

  Future<void> _showPanelPicker() async {
    final panelsAsync = ref.read(labPanelsProvider);
    final panels = panelsAsync.valueOrNull;
    if (panels == null) {
      unawaited(ref.read(labPanelsProvider.future).then((_) {
        if (mounted) _showPanelPicker();
      }));
      return;
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PanelPickerSheet(
        panels: panels,
        onSelected: (panel) {
          Navigator.of(ctx).pop();
          setState(() {
            for (final e in _labValues) {
              e.dispose();
            }
            _labValues.clear();
            for (final p in panel.parameters) {
              _labValues.add(
                _LabValueEntry(
                  parameterName: p.parameterName,
                  unit: p.unit,
                  referenceRange: p.referenceRange,
                ),
              );
            }
          });
        },
      ),
    );
  }

  List<Map<String, dynamic>> _collectLabValues() {
    return _labValues
        .where((e) => e.hasName && e.hasValue)
        .map((e) => e.toJson())
        .toList();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      final labValues = _collectLabValues();
      if (_isEdit) {
        await ref.read(labReportsProvider.notifier).saveEdit(
          id: widget.reportId!,
          testName: _testNameCtrl.text.trim(),
          testType: _selectedTestType!,
          testDate: _selectedDate!,
          appointmentId: _selectedAppointmentId,
          institutionId: _selectedInstitutionId,
          performedById: _selectedDoctorId,
          labValues: labValues,
        );
        if (mounted) {
          ref.invalidate(labReportDetailProvider(widget.reportId!));
          context.pop();
        }
      } else if (_filePath != null) {
        await ref.read(labReportsProvider.notifier).upload(
          patientId: _selectedPatientId!,
          testName: _testNameCtrl.text.trim(),
          testType: _selectedTestType!,
          testDate: _selectedDate!,
          appointmentId: _selectedAppointmentId,
          institutionId: _selectedInstitutionId,
          performedById: _selectedDoctorId,
          filePath: _filePath!,
          fileName: _fileName!,
        );
        if (mounted) context.pop();
      } else {
        await ref.read(labReportsProvider.notifier).create(
          patientId: _selectedPatientId!,
          testName: _testNameCtrl.text.trim(),
          testType: _selectedTestType!,
          testDate: _selectedDate!,
          appointmentId: _selectedAppointmentId,
          institutionId: _selectedInstitutionId,
          performedById: _selectedDoctorId,
          labValues: labValues,
        );
        if (mounted) context.pop();
      }
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
    final dateFmt = DateFormat('MMM d, yyyy');
    return '${dateFmt.format(apt.appointmentDate)} – ${apt.patientName}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final dateFmt = DateFormat('MMM d, yyyy');

    if (_isEdit && !_loadingDropdowns && !_initialized) {
      _populateFromReport();
    }

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
          _isEdit ? 'Edit Lab Report' : 'New Lab Report',
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
                if (!_isEdit)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPatientId,
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
                    validator: (v) =>
                        v == null ? 'Patient is required' : null,
                  )
                else
                  TextFormField(
                    initialValue: _patients
                        .where((p) => p.id == _selectedPatientId)
                        .map((p) => p.fullName)
                        .firstOrNull ?? '',
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Patient'),
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
                DropdownButtonFormField<String>(
                  initialValue: _selectedTestType,
                  decoration: const InputDecoration(labelText: 'Test Type *'),
                  items: _testTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedTestType = v),
                  validator: (v) =>
                      v == null ? 'Test type is required' : null,
                ),
                const SizedBox(height: 12),
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
                DropdownButtonFormField<String>(
                  initialValue: _selectedAppointmentId,
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
                  onChanged: (v) =>
                      setState(() => _selectedAppointmentId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedInstitutionId,
                  decoration: const InputDecoration(
                    labelText: 'Institution (optional)',
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(child: Text('None')),
                    ..._institutions.map(
                      (i) => DropdownMenuItem(
                        value: i.id,
                        child: Text(
                          i.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedInstitutionId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDoctorId,
                  decoration: const InputDecoration(
                    labelText: 'Performed By (optional)',
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(child: Text('None')),
                    ..._doctors.map(
                      (d) => DropdownMenuItem(
                        value: d.id,
                        child: Text(
                          d.fullName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedDoctorId = v),
                ),
                const SizedBox(height: 20),

                _SectionHeader(
                  title: 'Lab Values',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: _showPanelPicker,
                        icon: const Icon(Icons.library_books_rounded, size: 16),
                        label: const Text('Load Panel'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.add_circle_outline_rounded,
                          color: cs.primary,
                        ),
                        tooltip: 'Add row',
                        onPressed: _addLabValueRow,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (_labValues.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No lab values. Load a panel or add rows manually.',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ..._labValues.asMap().entries.map(
                    (entry) => _LabValueRowWidget(
                      key: ValueKey(entry.key),
                      entry: entry.value,
                      onRemove: () => _removeLabValueRow(entry.key),
                      onChanged: () => setState(() {}),
                    ),
                  ),

                if (!_isEdit) ...[
                  const SizedBox(height: 20),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(
          title,
          style: tt.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.primary,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _LabValueRowWidget extends StatefulWidget {
  const _LabValueRowWidget({
    required this.entry,
    required this.onRemove,
    required this.onChanged,
    super.key,
  });

  final _LabValueEntry entry;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  State<_LabValueRowWidget> createState() => _LabValueRowWidgetState();
}

class _LabValueRowWidgetState extends State<_LabValueRowWidget> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.entry.parameterNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Parameter',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.remove_circle_outline_rounded,
                  color: cs.error,
                  size: 20,
                ),
                onPressed: widget.onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: widget.entry.valueCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Value',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: widget.entry.unitCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.entry.referenceRangeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ref. Range',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: widget.entry.status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    isDense: true,
                  ),
                  items: _statuses
                      .map(
                        (s) => DropdownMenuItem(value: s, child: Text(s)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => widget.entry.status = v);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PanelPickerSheet extends StatelessWidget {
  const _PanelPickerSheet({
    required this.panels,
    required this.onSelected,
  });

  final List<LabPanel> panels;
  final void Function(LabPanel) onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Select a Panel',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: panels.isEmpty
                ? Center(
                    child: Text(
                      'No panels available',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: controller,
                    itemCount: panels.length,
                    itemBuilder: (_, i) {
                      final panel = panels[i];
                      return ListTile(
                        title: Text(panel.name),
                        subtitle: Text(
                          '${panel.parameters.length} parameters'
                          '${panel.category != null
                              ? ' · ${panel.category}'
                              : ''}',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => onSelected(panel),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
