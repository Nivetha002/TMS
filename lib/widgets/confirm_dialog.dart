import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Shows "Are you sure?" and returns true if the user taps the red button.
/// Usage: final ok = await showConfirmDialog(context, title: ..., message: ...);
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.errorText),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );

  // null means the user tapped outside the dialog, so treat it as "no".
  return result ?? false;
}