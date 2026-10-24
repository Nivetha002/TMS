import 'package:flutter/material.dart';

import '../../core/utils/validators.dart';
import '../../data/models/machine.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/primary_button.dart';

/// Bottom sheet used for both Add and Edit.
///   machine == null -> Add
///   machine != null -> Edit (fields start filled)
///
/// [existingNames] = names of the OTHER machines, used for the
/// "already exists" check (the web does this check on the screen too).
/// [onSave] must return null on success, or an error message.
class MachineFormSheet extends StatefulWidget {
  final Machine? machine;
  final List<String> existingNames;
  final Future<String?> Function(String name, String shortName) onSave;

  const MachineFormSheet({
    super.key,
    this.machine,
    required this.existingNames,
    required this.onSave,
  });

  @override
  State<MachineFormSheet> createState() => _MachineFormSheetState();
}

class _MachineFormSheetState extends State<MachineFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _shortNameController;

  bool _isSaving = false;
  String? _error;

  bool get _isEdit => widget.machine != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.machine?.name ?? '');
    _shortNameController =
        TextEditingController(text: widget.machine?.shortName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    super.dispose();
  }

  /// Required + "already exists" check (not case sensitive).
  String? _validateName(String? value) {
    final requiredError = Validators.required(value, 'Machine name');
    if (requiredError != null) return requiredError;

    final name = value!.trim().toLowerCase();
    final exists = widget.existingNames.any((n) => n.toLowerCase() == name);
    if (exists) return 'Machine name already exists';

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
                _isEdit ? 'Edit Machine' : 'Add Machine',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                ErrorBanner(message: _error!),
                const SizedBox(height: 16),
              ],
              AppTextField(
                controller: _nameController,
                label: 'Machine Name',
                hint: 'Enter machine name',
                prefixIcon: Icons.settings_outlined,
                enabled: !_isSaving,
                validator: _validateName,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _shortNameController,
                label: 'Short Name',
                hint: 'Enter machine short name',
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