import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mediqux_mobile/models/medication/medication.dart';
import 'package:mediqux_mobile/models/medication/medication_request.dart';
import 'package:mediqux_mobile/providers/medication_provider.dart';
import 'package:mediqux_mobile/utils/error_utils.dart';

const _kDosageForms = [
  'Tablet',
  'Capsule',
  'Syrup',
  'Suspension',
  'Injection',
  'Drops',
  'Cream',
  'Ointment',
  'Gel',
  'Patch',
  'Inhaler',
  'Spray',
  'Powder',
  'Granules',
  'Lotion',
  'Solution',
  'Other',
];

class MedicationFormScreen extends ConsumerStatefulWidget {
  const MedicationFormScreen({super.key, this.medicationId});

  final String? medicationId;

  @override
  ConsumerState<MedicationFormScreen> createState() =>
      _MedicationFormScreenState();
}

class _MedicationFormScreenState extends ConsumerState<MedicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _genericNameCtrl = TextEditingController();
  final _manufacturerCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _strengthCtrl = TextEditingController();
  final _selectedForms = <String>[];
  final _strengths = <String>[];
  bool _isSaving = false;
  bool _initialized = false;

  bool get _isEdit => widget.medicationId != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _genericNameCtrl.dispose();
    _manufacturerCtrl.dispose();
    _descCtrl.dispose();
    _strengthCtrl.dispose();
    super.dispose();
  }

  void _initFrom(Medication medication) {
    _nameCtrl.text = medication.name;
    _genericNameCtrl.text = medication.genericName ?? '';
    _manufacturerCtrl.text = medication.manufacturer ?? '';
    _descCtrl.text = medication.description ?? '';
    _selectedForms
      ..clear()
      ..addAll(medication.dosageForms);
    _strengths
      ..clear()
      ..addAll(medication.strengths);
    _initialized = true;
  }

  void _addStrength() {
    final val = _strengthCtrl.text.trim();
    if (val.isEmpty) return;
    if (!_strengths.contains(val)) {
      setState(() {
        _strengths.add(val);
        _strengthCtrl.clear();
      });
    } else {
      _strengthCtrl.clear();
    }
  }

  Future<void> _pickDosageForms() async {
    final picked = await showDialog<List<String>>(
      context: context,
      builder: (ctx) =>
          _DosageFormPickerDialog(selected: List.from(_selectedForms)),
    );
    if (picked != null) {
      setState(() {
        _selectedForms
          ..clear()
          ..addAll(picked);
      });
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    final request = MedicationRequest(
      name: _nameCtrl.text.trim(),
      genericName: _genericNameCtrl.text.trim().isEmpty
          ? null
          : _genericNameCtrl.text.trim(),
      manufacturer: _manufacturerCtrl.text.trim().isEmpty
          ? null
          : _manufacturerCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      dosageForms: List.from(_selectedForms),
      strengths: List.from(_strengths),
    );
    try {
      if (!_isEdit) {
        await ref.read(medicationsProvider.notifier).create(request);
      } else {
        await ref
            .read(medicationsProvider.notifier)
            .saveMedication(widget.medicationId!, request);
        ref.invalidate(medicationDetailProvider(widget.medicationId!));
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

    if (_isEdit && !_initialized) {
      ref.watch(medicationDetailProvider(widget.medicationId!)).whenData((med) {
        if (!_initialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _initFrom(med));
          });
        }
      });
      if (!_initialized) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Medication'),
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
          _isEdit ? 'Edit Medication' : 'Add Medication',
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
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Medication Name *',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _genericNameCtrl,
                decoration: const InputDecoration(labelText: 'Generic Name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _manufacturerCtrl,
                decoration: const InputDecoration(labelText: 'Manufacturer'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'Dosage Forms',
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _pickDosageForms,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              if (_selectedForms.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'No dosage forms selected.',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedForms
                      .map(
                        (f) => Chip(
                          label: Text(f),
                          onDeleted: () =>
                              setState(() => _selectedForms.remove(f)),
                          deleteIconColor: cs.onSurfaceVariant,
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 20),
              Text(
                'Strengths',
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _strengthCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Add strength (e.g. 500mg)',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      onFieldSubmitted: (_) => _addStrength(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addStrength,
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'Add strength',
                  ),
                ],
              ),
              if (_strengths.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _strengths
                      .map(
                        (s) => Chip(
                          label: Text(s),
                          onDeleted: () => setState(() => _strengths.remove(s)),
                          deleteIconColor: cs.onSurfaceVariant,
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _DosageFormPickerDialog extends StatefulWidget {
  const _DosageFormPickerDialog({required this.selected});

  final List<String> selected;

  @override
  State<_DosageFormPickerDialog> createState() =>
      _DosageFormPickerDialogState();
}

class _DosageFormPickerDialogState extends State<_DosageFormPickerDialog> {
  late final List<String> _picked;

  @override
  void initState() {
    super.initState();
    _picked = List.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Select Dosage Forms'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: _kDosageForms.map((form) {
            return CheckboxListTile(
              value: _picked.contains(form),
              onChanged: (checked) {
                setState(() {
                  if (checked ?? false) {
                    _picked.add(form);
                  } else {
                    _picked.remove(form);
                  }
                });
              },
              title: Text(form),
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_picked),
          style: FilledButton.styleFrom(backgroundColor: cs.primary),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
