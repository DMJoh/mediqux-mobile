import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mediqux_mobile/models/diagnostic_study/diagnostic_study.dart';
import 'package:mediqux_mobile/models/doctor/doctor.dart';
import 'package:mediqux_mobile/models/institution/institution.dart';
import 'package:mediqux_mobile/models/patient/patient.dart';
import 'package:mediqux_mobile/providers/diagnostic_study_provider.dart';
import 'package:mediqux_mobile/providers/doctor_provider.dart';
import 'package:mediqux_mobile/providers/institution_provider.dart';
import 'package:mediqux_mobile/providers/patient_provider.dart';
import 'package:mediqux_mobile/utils/error_utils.dart';
import 'package:mediqux_mobile/widgets/form_section.dart';
import 'package:mediqux_mobile/widgets/gradient_button.dart';

const _kStudyTypes = [
  'X-Ray',
  'CT Scan',
  'MRI',
  'Ultrasound',
  'PET Scan',
  'Mammography',
  'Echocardiogram',
  'Fluoroscopy',
  'Nuclear Medicine',
  'DEXA Scan',
  'Angiography',
  'Other',
];

class DiagnosticStudyFormScreen extends ConsumerStatefulWidget {
  const DiagnosticStudyFormScreen({super.key, this.studyId});

  final String? studyId;

  @override
  ConsumerState<DiagnosticStudyFormScreen> createState() =>
      _DiagnosticStudyFormScreenState();
}

class _DiagnosticStudyFormScreenState
    extends ConsumerState<DiagnosticStudyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bodyRegionCtrl = TextEditingController();
  final _indicationCtrl = TextEditingController();
  final _findingsCtrl = TextEditingController();
  final _conclusionCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _selectedPatientId;
  String? _selectedStudyType;
  String? _selectedOrderingPhysicianId;
  String? _selectedPerformingPhysicianId;
  String? _selectedInstitutionId;
  DateTime? _selectedDate;
  String? _filePath;
  String? _fileName;

  bool _isSaving = false;
  bool _initialized = false;
  bool _loadingDropdowns = true;

  List<Patient> _patients = [];
  List<Doctor> _doctors = [];
  List<Institution> _institutions = [];

  bool get _isEdit => widget.studyId != null;

  @override
  void initState() {
    super.initState();
    final pA = ref.read(patientsProvider);
    final dA = ref.read(doctorsProvider);
    final iA = ref.read(institutionsProvider);
    if (pA.hasValue &&
        !pA.isLoading &&
        dA.hasValue &&
        !dA.isLoading &&
        iA.hasValue &&
        !iA.isLoading) {
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
    _bodyRegionCtrl.dispose();
    _indicationCtrl.dispose();
    _findingsCtrl.dispose();
    _conclusionCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _initFrom(DiagnosticStudy study) {
    _selectedPatientId = study.patientId;
    _selectedStudyType = study.studyType;
    _selectedDate = study.studyDate;
    _bodyRegionCtrl.text = study.bodyRegion ?? '';
    _selectedOrderingPhysicianId = study.orderingPhysician?.id;
    _selectedPerformingPhysicianId = study.performingPhysician?.id;
    _selectedInstitutionId = study.institution?.id;
    _indicationCtrl.text = study.clinicalIndication ?? '';
    _findingsCtrl.text = study.findings ?? '';
    _conclusionCtrl.text = study.conclusion ?? '';
    _notesCtrl.text = study.notes ?? '';
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

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
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
        const SnackBar(content: Text('Please select a study date')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      if (!_isEdit) {
        await ref
            .read(diagnosticStudiesProvider.notifier)
            .create(
              patientId: _selectedPatientId!,
              studyType: _selectedStudyType!,
              studyDate: _selectedDate!,
              bodyRegion: _bodyRegionCtrl.text.trim().isEmpty
                  ? null
                  : _bodyRegionCtrl.text.trim(),
              orderingPhysicianId: _selectedOrderingPhysicianId,
              performingPhysicianId: _selectedPerformingPhysicianId,
              institutionId: _selectedInstitutionId,
              clinicalIndication: _indicationCtrl.text.trim().isEmpty
                  ? null
                  : _indicationCtrl.text.trim(),
              findings: _findingsCtrl.text.trim().isEmpty
                  ? null
                  : _findingsCtrl.text.trim(),
              conclusion: _conclusionCtrl.text.trim().isEmpty
                  ? null
                  : _conclusionCtrl.text.trim(),
              notes: _notesCtrl.text.trim().isEmpty
                  ? null
                  : _notesCtrl.text.trim(),
              filePath: _filePath,
              fileName: _fileName,
            );
      } else {
        await ref
            .read(diagnosticStudiesProvider.notifier)
            .saveStudy(
              widget.studyId!,
              patientId: _selectedPatientId!,
              studyType: _selectedStudyType!,
              studyDate: _selectedDate!,
              bodyRegion: _bodyRegionCtrl.text.trim().isEmpty
                  ? null
                  : _bodyRegionCtrl.text.trim(),
              orderingPhysicianId: _selectedOrderingPhysicianId,
              performingPhysicianId: _selectedPerformingPhysicianId,
              institutionId: _selectedInstitutionId,
              clinicalIndication: _indicationCtrl.text.trim().isEmpty
                  ? null
                  : _indicationCtrl.text.trim(),
              findings: _findingsCtrl.text.trim().isEmpty
                  ? null
                  : _findingsCtrl.text.trim(),
              conclusion: _conclusionCtrl.text.trim().isEmpty
                  ? null
                  : _conclusionCtrl.text.trim(),
              notes: _notesCtrl.text.trim().isEmpty
                  ? null
                  : _notesCtrl.text.trim(),
              filePath: _filePath,
              fileName: _fileName,
            );
        ref.invalidate(diagnosticStudyDetailProvider(widget.studyId!));
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
    final tt = Theme.of(context).textTheme;
    final dateFmt = DateFormat('MMM d, yyyy');

    if (_isEdit && !_initialized) {
      ref.watch(diagnosticStudyDetailProvider(widget.studyId!)).whenData((
        study,
      ) {
        if (!_initialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _initFrom(study));
          });
        }
      });
      if (!_initialized) {
        return Scaffold(
          appBar: AppBar(title: const Text('Edit Study')),
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
        leading: _isEdit
            ? BackButton(onPressed: () => context.pop())
            : CloseButton(onPressed: () => context.pop()),
        title: Text(_isEdit ? 'Edit Study' : 'New Diagnostic Study'),
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
              if (_loadingDropdowns)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeCap: StrokeCap.round,
                      strokeWidth: 3,
                    ),
                  ),
                )
              else ...[
                FormSection(
                  title: 'Details',
                  children: [
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
                      validator: (v) =>
                          v == null ? 'Patient is required' : null,
                    ),
                    // Study type dropdown
                    // ignore: deprecated_member_use
                    DropdownButtonFormField<String>(
                      // Deprecated in favour of DropdownMenu.
                      // ignore: deprecated_member_use
                      value: _selectedStudyType,
                      decoration: const InputDecoration(
                        labelText: 'Study Type *',
                      ),
                      items: _kStudyTypes
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedStudyType = v),
                      validator: (v) =>
                          v == null ? 'Study type is required' : null,
                    ),
                    // Date picker
                    GestureDetector(
                      onTap: _pickDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Study Date *',
                            hintText: 'Select date',
                            suffixIcon: Icon(Icons.calendar_today_outlined),
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
                    TextFormField(
                      controller: _bodyRegionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Body Region',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    // Ordering physician dropdown
                    // ignore: deprecated_member_use
                    DropdownButtonFormField<String>(
                      // Deprecated in favour of DropdownMenu.
                      // ignore: deprecated_member_use
                      value: _selectedOrderingPhysicianId,
                      decoration: const InputDecoration(
                        labelText: 'Ordering Physician',
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
                      onChanged: (v) =>
                          setState(() => _selectedOrderingPhysicianId = v),
                    ),
                    // Performing physician dropdown
                    // ignore: deprecated_member_use
                    DropdownButtonFormField<String>(
                      // Deprecated in favour of DropdownMenu.
                      // ignore: deprecated_member_use
                      value: _selectedPerformingPhysicianId,
                      decoration: const InputDecoration(
                        labelText: 'Performing Physician',
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
                      onChanged: (v) =>
                          setState(() => _selectedPerformingPhysicianId = v),
                    ),
                    // Institution dropdown
                    // ignore: deprecated_member_use
                    DropdownButtonFormField<String>(
                      // Deprecated in favour of DropdownMenu.
                      // ignore: deprecated_member_use
                      value: _selectedInstitutionId,
                      decoration: const InputDecoration(
                        labelText: 'Institution',
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
                  ],
                ),
                const SizedBox(height: 16),
                FormSection(
                  title: 'Clinical Info',
                  children: [
                    TextFormField(
                      controller: _indicationCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Clinical Indication',
                      ),
                      maxLines: 2,
                    ),
                    TextFormField(
                      controller: _findingsCtrl,
                      decoration: const InputDecoration(labelText: 'Findings'),
                      maxLines: 3,
                    ),
                    TextFormField(
                      controller: _conclusionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Conclusion',
                      ),
                      maxLines: 2,
                    ),
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      maxLines: 2,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FormSection(
                  title: 'Attachment',
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.upload_file_outlined),
                      label: const Text('Attach File (optional)'),
                    ),
                    if (_fileName != null)
                      Row(
                        children: [
                          Icon(
                            Icons.attach_file_outlined,
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
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
