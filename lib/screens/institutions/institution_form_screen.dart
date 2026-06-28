import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mediqux_mobile/models/institution/institution.dart';
import 'package:mediqux_mobile/models/institution/institution_request.dart';
import 'package:mediqux_mobile/providers/institution_provider.dart';

const _kTypes = [
  'Hospital',
  'Clinic',
  'Laboratory',
  'Pharmacy',
  'Diagnostic Center',
  'Nursing Home',
];

class InstitutionFormScreen extends ConsumerStatefulWidget {
  const InstitutionFormScreen({super.key, this.institutionId});

  final String? institutionId;

  @override
  ConsumerState<InstitutionFormScreen> createState() =>
      _InstitutionFormScreenState();
}

class _InstitutionFormScreenState extends ConsumerState<InstitutionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  String? _selectedType;
  bool _isSaving = false;
  bool _initialized = false;

  bool get _isEdit => widget.institutionId != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  void _initFrom(Institution institution) {
    _nameCtrl.text = institution.name;
    _addressCtrl.text = institution.address ?? '';
    _phoneCtrl.text = institution.phone ?? '';
    _emailCtrl.text = institution.email ?? '';
    _websiteCtrl.text = institution.website ?? '';
    _selectedType = institution.type;
    _initialized = true;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _isSaving = true);
    final request = InstitutionRequest(
      name: _nameCtrl.text.trim(),
      type: _selectedType,
      address: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      website: _websiteCtrl.text.trim().isEmpty
          ? null
          : _websiteCtrl.text.trim(),
    );
    try {
      if (!_isEdit) {
        await ref.read(institutionsProvider.notifier).create(request);
      } else {
        await ref
            .read(institutionsProvider.notifier)
            .saveInstitution(widget.institutionId!, request);
        ref.invalidate(institutionDetailProvider(widget.institutionId!));
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
      ref.watch(institutionDetailProvider(widget.institutionId!)).whenData((
        inst,
      ) {
        if (!_initialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _initFrom(inst));
          });
        }
      });
      if (!_initialized) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Institution'),
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
          _isEdit ? 'Edit Institution' : 'Add Institution',
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
                  labelText: 'Institution Name *',
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
              DropdownButtonFormField<String>(
                // value updates display on every rebuild;
                // initialValue only sets once, breaking edit pre-fill.
                // ignore: deprecated_member_use
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: _kTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedType = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return null;
                  }
                  if (!RegExp(r'^[0-9+\s\-]+$').hasMatch(v.trim())) {
                    return 'Invalid phone number';
                  }
                  return null;
                },
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _websiteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Website',
                  hintText: 'https://example.com',
                ),
                keyboardType: TextInputType.url,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return null;
                  }
                  if (!RegExp('^https?://.+').hasMatch(v.trim())) {
                    return 'Must start with http:// or https://';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 3,
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
