import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// A dropdown that opens a searchable list in a bottom sheet.
/// Works with any type [T] (Instrument, Department, ...).
///
/// The parent keeps the selected value and the error text:
///   SelectField<Instrument>(
///     items: instruments,
///     value: selected,
///     itemLabel: (i) => i.name,
///     onChanged: (i) => setState(() => selected = i),
///   )
class SelectField<T> extends StatelessWidget {
  final String label;
  final String hint;
  final IconData prefixIcon;
  final List<T> items;
  final T? value; // null = nothing selected yet
  final String Function(T item) itemLabel; // how to show one item as text
  final ValueChanged<T> onChanged;
  final String? errorText;
  final bool enabled;

  const SelectField({
    super.key,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    required this.items,
    required this.value,
    required this.itemLabel,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Future<void> _open(BuildContext context) async {
    FocusScope.of(context).unfocus(); // close keyboard first

    final picked = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SelectSheet<T>(
        title: label,
        items: items,
        itemLabel: itemLabel,
        selected: value,
      ),
    );

    // picked is null when the user closes the sheet without choosing
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? () => _open(context) : null,
          // InputDecorator draws the same box as a text field
          child: InputDecorator(
            decoration: InputDecoration(
              errorText: errorText,
              filled: true,
              fillColor: AppColors.fieldBackground,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              prefixIcon: Icon(prefixIcon, color: AppColors.textLight),
              suffixIcon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textLight,
              ),
              border: _border(AppColors.border),
              enabledBorder: _border(AppColors.border),
              errorBorder: _border(AppColors.errorText),
            ),
            child: Text(
              hasValue ? itemLabel(value as T) : hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                color: hasValue ? AppColors.textDark : AppColors.textLight,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The bottom sheet: title, search box, and the list.
class _SelectSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T item) itemLabel;
  final T? selected;

  const _SelectSheet({
    required this.title,
    required this.items,
    required this.itemLabel,
    required this.selected,
  });

  @override
  State<_SelectSheet<T>> createState() => _SelectSheetState<T>();
}

class _SelectSheetState<T> extends State<_SelectSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.items
        : widget.items
            .where((i) => widget.itemLabel(i).toLowerCase().contains(q))
            .toList();

    return Padding(
      // keyboard height, so the sheet moves above the keyboard
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select ${widget.title}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: const TextStyle(color: AppColors.textLight),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textLight),
                  filled: true,
                  fillColor: AppColors.fieldBackground,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No results',
                        style: TextStyle(color: AppColors.textLight),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isSelected = item == widget.selected;

                        return ListTile(
                          title: Text(widget.itemLabel(item)),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: AppColors.primary)
                              : null,
                          // returns the chosen item to SelectField._open
                          onTap: () => Navigator.pop(context, item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}