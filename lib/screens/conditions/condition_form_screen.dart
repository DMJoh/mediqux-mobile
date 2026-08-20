import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mediqux_mobile/models/condition/condition.dart';
import 'package:mediqux_mobile/models/condition/condition_request.dart';
import 'package:mediqux_mobile/providers/condition_provider.dart';
import 'package:mediqux_mobile/utils/error_utils.dart';

const _kCategories = [
  'Cardiovascular',
  'Respiratory',
  'Neurological',
  'Gastrointestinal',
  'Endocrine',
  'Musculoskeletal',
  'Dermatological',
  'Psychiatric',
  'Infectious Disease',
  'Oncological',
  'Hematological',
  'Renal',
  'Ophthalmological',
  'ENT',
  'Gynecological',
  'Pediatric',
  'Emergency',
  'Other',
];

const _kSeverities = ['Low', 'Medium', 'High'];

class ConditionFormScreen extends ConsumerStatefulWidget {
  const ConditionFormScreen({super.key, this.conditionId});

  final String? conditionId;

  @override
  ConsumerState<ConditionFormScreen> createState() =>
      _ConditionFormScreenState();
}

class _ConditionFormScreenState extends ConsumerState<ConditionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _icdCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedCategory;
  String? _selectedSeverity;
  bool _isSaving = false;
  bool _initialized = false;

  bool get _isEdit => widget.conditionId != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _icdCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _initFrom(Condition condition) {
    _nameCtrl.text = condition.name;
    _icdCtrl.text = condition.icdCode ?? '';
    _descCtrl.text = condition.description ?? '';
    _selectedCategory = condition.category;
    _selectedSeverity = condition.severity;
    _initialized = true;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    final request = ConditionRequest(
      name: _nameCtrl.text.trim(),
      icdCode: _icdCtrl.text.trim().isEmpty ? null : _icdCtrl.text.trim(),
      category: _selectedCategory,
      severity: _selectedSeverity,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
    );
    try {
      if (!_isEdit) {
        await ref.read(conditionsProvider.notifier).create(request);
      } else {
        await ref
            .read(conditionsProvider.notifier)
            .saveCondition(widget.conditionId!, request);
        ref.invalidate(conditionDetailProvider(widget.conditionId!));
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

    if (_isEdit && !_initialized) {
      ref.watch(conditionDetailProvider(widget.conditionId!)).whenData((cond) {
        if (!_initialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _initFrom(cond));
          });
        }
      });
      if (!_initialized) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Condition'),
            backgroundColor: cs.surface,
          ),
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
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: _isEdit
            ? BackButton(color: cs.onSurface, onPressed: () => context.pop())
            : CloseButton(color: cs.onSurface, onPressed: () => context.pop()),
        title: Text(
          _isEdit ? 'Edit Condition' : 'Add Condition',
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
                  labelText: 'Condition Name *',
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
                controller: _icdCtrl,
                decoration: const InputDecoration(
                  labelText: 'ICD Code',
                  hintText: 'e.g. I10',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                // value updates display on every rebuild;
                // initialValue only sets once, breaking edit pre-fill.
                // ignore: deprecated_member_use
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _kCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                // value updates display on every rebuild;
                // initialValue only sets once, breaking edit pre-fill.
                // ignore: deprecated_member_use
                value: _selectedSeverity,
                decoration: const InputDecoration(labelText: 'Severity'),
                items: _kSeverities
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedSeverity = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
