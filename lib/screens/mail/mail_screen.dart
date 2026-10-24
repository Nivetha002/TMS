import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/mail_bucket.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mail_provider.dart';
import '../../providers/permission_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/error_banner.dart';
import 'mail_form_sheet.dart';

class MailScreen extends StatefulWidget {
  const MailScreen({super.key});

  @override
  State<MailScreen> createState() => _MailScreenState();
}

class _MailScreenState extends State<MailScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    // Load after the first frame (we cannot notify listeners during build).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------

  Future<void> _load() async {
    final provider = context.read<MailProvider>();

    await provider.load();

    if (!mounted) return;
    if (provider.isUnauthorized) _handleExpired();
  }

  /// Session is dead: close every screen above the first one, then logout.
  /// AuthGate then shows Login with the "Session expired" message.
  void _handleExpired() {
    final auth = context.read<AuthProvider>();
    Navigator.of(context).popUntil((route) => route.isFirst);
    auth.logout(message: 'Session expired. Please login again.');
  }

  void _showMessage(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? AppColors.errorText : AppColors.primary,
        ),
      );
  }

  Future<void> _openForm(MailBucket bucket) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true, // lets the sheet grow above the keyboard
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => MailFormSheet(
        bucket: bucket,
        onSave: (entries) => _save(bucket, entries),
      ),
    );
  }

  /// Called by the sheet. Returns null on success, or an error message.
  Future<String?> _save(MailBucket bucket, List<MailEntry> entries) async {
    final provider = context.read<MailProvider>();

    final error = await provider.saveBucket(bucket, entries);

    if (!mounted) return error;

    if (provider.isUnauthorized) {
      _handleExpired();
      return error;
    }

    if (error == null) {
      _showMessage('"${bucket.description}" updated successfully!');
    }
    return error; // the sheet shows it in a red banner
  }

  // ---------------------------------------------------------------------
  // build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MailProvider>();
    final perms = context.watch<PermissionProvider>();

    // Same as the web page: view needs "View Mail",
    // and the Edit button is shown for "Add Mail".
    final canView = perms.has('View Mail');
    final canEdit = perms.has('Add Mail');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mail'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: !canView
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "You don't have permission to view the Mail module.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMedium),
                ),
              ),
            )
          : Column(
              children: [
                _buildSearchField(),
                Expanded(child: _buildList(provider, canEdit)),
              ],
            ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _search = value),
        decoration: InputDecoration(
          hintText: 'Search description or mail...',
          hintStyle: const TextStyle(color: AppColors.textLight),
          prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
          suffixIcon: _search.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textLight),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _search = '');
                  },
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: _border(AppColors.border),
          enabledBorder: _border(AppColors.border),
          focusedBorder: _border(AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildList(MailProvider provider, bool canEdit) {
    final buckets = provider.filter(_search);

    // The 6 groups always exist, so only show them when we have data
    // (or when loading did not fail).
    final showBuckets =
        provider.errorMessage == null || provider.records.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _load, // pull down to refresh
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          if (provider.errorMessage != null) ...[
            ErrorBanner(message: provider.errorMessage!),
            const SizedBox(height: 12),
          ],
          if (provider.isLoading && provider.records.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (showBuckets) ...[
            if (buckets.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: Text(
                    'No Data Found',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                ),
              ),
            ...buckets.map((b) => _buildCard(b, canEdit)),
          ],
        ],
      ),
    );
  }

  Widget _buildCard(MailBucket bucket, bool canEdit) {
    final mails = bucket.mails;

    return AppCard(
      key: ValueKey(bucket.description),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.mail_outline, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    bucket.description,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (mails.isEmpty)
                  const Text(
                    'No mail configured',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textLight,
                    ),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: mails.map(_buildMailChip).toList(),
                  ),
              ],
            ),
          ),
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              color: AppColors.primary,
              tooltip: 'Edit',
              onPressed: () => _openForm(bucket),
            ),
        ],
      ),
    );
  }

  Widget _buildMailChip(String mail) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mail_outline, size: 12, color: AppColors.primaryDark),
          const SizedBox(width: 4),
          // Flexible: a very long email gets "..." instead of overflowing
          Flexible(
            child: Text(
              mail,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}