import 'package:flutter/material.dart';

import '../../core/utils/validators.dart';
import '../../data/models/instrument.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/primary_button.dart';

/// Bottom sheet used for both Add and Edit.
///   instrument == null -> Add
///   instrument != null -> Edit (fields start filled)
///
/// [existingNames] = names of the OTHER instruments, used for the
/// "already exists" check (the web does this check on the screen too).
/// [onSave] must return null on success, or an error message.
class InstrumentFormSheet extends StatefulWidget {
  final Instrument? instrument;
  final List<String> existingNames;
  final Future<String?> Function(String name, String shortName) onSave;

  const InstrumentFormSheet({
    super.key,
    this.instrument,
    required this.existingNames,
    required this.onSave,
  });

  @override
  State<InstrumentFormSheet> createState() => _InstrumentFormSheetState();
}

class _InstrumentFormSheetState extends State<InstrumentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _shortNameController;

  bool _isSaving = false;
  String? _error;

  bool get _isEdit => widget.instrument != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.instrument?.name ?? '');
    _shortNameController =
        TextEditingController(text: widget.instrument?.shortName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    super.dispose();
  }

  /// Required + "already exists" check (not case sensitive).
  String? _validateName(String? value) {
    final requiredError = Validators.required(value, 'Instrument name');
    if (requiredError != null) return requiredError;

    final name = value!.trim().toLowerCase();
    final exists = widget.existingNames.any((n) => n.toLowerCase() == name);
    if (exists) return 'Instrument name already exists';

    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
      _error = null;
    });

    final error = await widget.onSave(
      _nameController.text.trim(),
      _shortNameController.text.trim(),
    );

    // Sheet already closed (for example the session expired): do nothing.
    if (!mounted) return;

    if (error == null) {
      Navigator.pop(context); // success: close the sheet
    } else {
      setState(() {
        _isSaving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // viewInsets.bottom = keyboard height, so the sheet moves above it
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEdit ? 'Edit Instrument' : 'Add Instrument',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                ErrorBanner(message: _error!),
                const SizedBox(height: 16),
              ],
              AppTextField(
                controller: _nameController,
                label: 'Instrument Name',
                hint: 'Enter instrument name',
                prefixIcon: Icons.precision_manufacturing_outlined,
                enabled: !_isSaving,
                validator: _validateName,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _shortNameController,
                label: 'Short Name',
                hint: 'Enter instrument short name',
                prefixIcon: Icons.short_text,
                enabled: !_isSaving,
                textInputAction: TextInputAction.done,
                validator: (v) => Validators.required(v, 'Short name'),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: _isEdit ? 'Update' : 'Save',
                isLoading: _isSaving,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}