import 'package:flutter/material.dart';

import '../../core/utils/validators.dart';
import '../../data/models/department.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/primary_button.dart';

/// Bottom sheet used for both Add and Edit.
///   department == null -> Add
///   department != null -> Edit (fields start filled)
///
/// [onSave] must return null on success, or an error message.
class DepartmentFormSheet extends StatefulWidget {
  final Department? department;
  final Future<String?> Function(String name, String shortName) onSave;

  const DepartmentFormSheet({
    super.key,
    this.department,
    required this.onSave,
  });

  @override
  State<DepartmentFormSheet> createState() => _DepartmentFormSheetState();
}

class _DepartmentFormSheetState extends State<DepartmentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _shortNameController;

  bool _isSaving = false;
  String? _error;

  bool get _isEdit => widget.department != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.department?.name ?? '');
    _shortNameController =
        TextEditingController(text: widget.department?.shortName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    super.dispose();
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
        _error = error; // for example "Department name already exists."
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
                _isEdit ? 'Edit Department' : 'Add Department',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                ErrorBanner(message: _error!),
                const SizedBox(height: 16),
              ],
              AppTextField(
                controller: _nameController,
                label: 'Department Name',
                hint: 'Enter department name',
                prefixIcon: Icons.apartment_outlined,
                enabled: !_isSaving,
                validator: (v) => Validators.required(v, 'Department name'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _shortNameController,
                label: 'Short Name',
                hint: 'Enter short name',
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