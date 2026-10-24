import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../data/models/mail_bucket.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/primary_button.dart';

/// One email row in the form: a text controller + the server id (if any).
class _MailRow {
  final int? id; // null = new email
  final TextEditingController controller;

  _MailRow({this.id, String mail = ''})
      : controller = TextEditingController(text: mail);
}

/// Bottom sheet to edit ALL emails of one group.
/// [onSave] must return null on success, or an error message.
class MailFormSheet extends StatefulWidget {
  final MailBucket bucket;
  final Future<String?> Function(List<MailEntry> entries) onSave;

  const MailFormSheet({super.key, required this.bucket, required this.onSave});

  @override
  State<MailFormSheet> createState() => _MailFormSheetState();
}

class _MailFormSheetState extends State<MailFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final List<_MailRow> _rows;

  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rows = widget.bucket.records
        .map((r) => _MailRow(id: r.id, mail: r.mail))
        .toList();

    // Like the web page: a group with no emails starts with one empty row
    if (_rows.isEmpty) _rows.add(_MailRow());
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.controller.dispose();
    }
    super.dispose();
  }

  /// Required + valid format + no duplicate inside this group.
  String? _validateRow(_MailRow row, String? value) {
    final error = Validators.email(value);
    if (error != null) return error;

    final mail = value!.trim().toLowerCase();
    final isDuplicate = _rows.any(
      (other) =>
          other != row && other.controller.text.trim().toLowerCase() == mail,
    );
    return isDuplicate ? 'Duplicate email' : null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
      _error = null;
    });

    final entries = _rows
        .map((r) => MailEntry(id: r.id, mail: r.controller.text.trim()))
        .toList();

    final error = await widget.onSave(entries);

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

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _buildRow(_MailRow row) {
    return Padding(
      key: ObjectKey(row), // keeps each row's text when another row is removed
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: row.controller,
        enabled: !_isSaving,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        textInputAction: TextInputAction.next,
        validator: (value) => _validateRow(row, value),
        style: const TextStyle(fontSize: 15, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: 'e.g. user@example.com',
          hintStyle: const TextStyle(color: AppColors.textLight),
          filled: true,
          fillColor: AppColors.fieldBackground,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          prefixIcon: const Icon(Icons.mail_outline, color: AppColors.textLight),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textLight),
            tooltip: 'Remove',
            onPressed: _isSaving ? null : () => setState(() => _rows.remove(row)),
          ),
          border: _border(AppColors.border),
          enabledBorder: _border(AppColors.border),
          disabledBorder: _border(AppColors.border),
          focusedBorder: _border(AppColors.primary, width: 1.5),
          errorBorder: _border(AppColors.errorText),
          focusedErrorBorder: _border(AppColors.errorText, width: 1.5),
        ),
      ),
    );
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
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.bucket.description,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Add one or more email addresses',
                style: TextStyle(fontSize: 13, color: AppColors.textLight),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                ErrorBanner(message: _error!),
                const SizedBox(height: 16),
              ],
              if (_rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'No emails. Tap "Add email" below.',
                    style: TextStyle(fontSize: 13, color: AppColors.textLight),
                  ),
                ),
              ..._rows.map(_buildRow),
              TextButton.icon(
                onPressed: _isSaving
                    ? null
                    : () => setState(() => _rows.add(_MailRow())),
                icon: const Icon(Icons.add),
                label: const Text('Add email'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Submit',
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