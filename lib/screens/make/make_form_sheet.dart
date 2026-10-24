import 'package:flutter/material.dart';

import '../../core/utils/validators.dart';
import '../../data/models/instrument.dart';
import '../../data/models/make.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/select_field.dart';

/// Bottom sheet used for both Add and Edit.
///   make == null -> Add
///   make != null -> Edit (fields start filled)
///
/// [instruments] = the list for the Instrument dropdown.
/// [onSave] must return null on success, or an error message.
class MakeFormSheet extends StatefulWidget {
  final Make? make;
  final List<Instrument> instruments;
  final Future<String?> Function(Instrument instrument, String makeName) onSave;

  const MakeFormSheet({
    super.key,
    this.make,
    required this.instruments,
    required this.onSave,
  });

  @override
  State<MakeFormSheet> createState() => _MakeFormSheetState();
}

class _MakeFormSheetState extends State<MakeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _makeController;

  int? _instrumentId; // selected instrument (null = nothing selected)
  String? _instrumentError;

  bool _isSaving = false;
  String? _error;

  bool get _isEdit => widget.make != null;

  /// Finds the selected Instrument object from its id.
  Instrument? get _selectedInstrument {
    for (final instrument in widget.instruments) {
      if (instrument.id == _instrumentId) return instrument;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _makeController = TextEditingController(text: widget.make?.makeName ?? '');
    _instrumentId = widget.make?.instrumentId;
  }

  @override
  void dispose() {
    _makeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final fieldsValid = _formKey.currentState?.validate() ?? false;
    final instrument = _selectedInstrument;

    // The dropdown is not a TextFormField, so we check it ourselves.
    setState(() {
      _instrumentError = instrument == null ? 'Instrument is required' : null;
    });

    if (!fieldsValid || instrument == null) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
      _error = null;
    });

    final error = await widget.onSave(instrument, _makeController.text.trim());

    // Sheet already closed (for example the session expired): do nothing.
    if (!mounted) return;

    if (error == null) {
      Navigator.pop(context); // success: close the sheet
    } else {
      setState(() {
        _isSaving = false;
        _error = error; // for example "Make already exists for this instrument."
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
                _isEdit ? 'Edit Make' : 'Add Make',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                ErrorBanner(message: _error!),
                const SizedBox(height: 16),
              ],
              SelectField<Instrument>(
                label: 'Instrument',
                hint: 'Select instrument',
                prefixIcon: Icons.precision_manufacturing_outlined,
                items: widget.instruments,
                value: _selectedInstrument,
                itemLabel: (i) => i.name,
                errorText: _instrumentError,
                enabled: !_isSaving,
                onChanged: (instrument) {
                  setState(() {
                    _instrumentId = instrument.id;
                    _instrumentError = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _makeController,
                label: 'Make',
                hint: 'e.g. Mitutoyo',
                prefixIcon: Icons.label_outline,
                enabled: !_isSaving,
                textInputAction: TextInputAction.done,
                validator: (v) => Validators.required(v, 'Make name'),
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