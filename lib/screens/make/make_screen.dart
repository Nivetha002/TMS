import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/instrument.dart';
import '../../data/models/make.dart';
import '../../providers/auth_provider.dart';
import '../../providers/instrument_provider.dart';
import '../../providers/make_provider.dart';
import '../../providers/permission_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/error_banner.dart';
import 'make_form_sheet.dart';

class MakeScreen extends StatefulWidget {
  const MakeScreen({super.key});

  @override
  State<MakeScreen> createState() => _MakeScreenState();
}

class _MakeScreenState extends State<MakeScreen> {
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

  /// Loads the makes AND the instruments (for the dropdown) together.
  Future<void> _load() async {
    final makes = context.read<MakeProvider>();
    final instruments = context.read<InstrumentProvider>();

    await Future.wait([makes.load(), instruments.load()]);

    if (!mounted) return;
    if (makes.isUnauthorized || instruments.isUnauthorized) _handleExpired();
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

  /// Opens the Add sheet (make == null) or the Edit sheet.
  Future<void> _openForm({Make? make}) async {
    final instruments = context.read<InstrumentProvider>().items;

    // No instruments = nothing to choose in the dropdown
    if (instruments.isEmpty) {
      _showMessage('No instruments found. Add an instrument first.',
          isError: true);
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true, // lets the sheet grow above the keyboard
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => MakeFormSheet(
        make: make,
        instruments: instruments,
        onSave: (instrument, makeName) => _save(make, instrument, makeName),
      ),
    );
  }

  /// Called by the sheet. Returns null on success, or an error message.
  Future<String?> _save(
    Make? make,
    Instrument instrument,
    String makeName,
  ) async {
    final provider = context.read<MakeProvider>();

    final error = make == null
        ? await provider.add(instrument.id, instrument.name, makeName)
        : await provider.update(make.id, instrument.id, instrument.name, makeName);

    if (!mounted) return error;

    if (provider.isUnauthorized) {
      _handleExpired();
      return error;
    }

    if (error == null) {
      _showMessage(make == null
          ? 'Make "$makeName" added successfully!'
          : 'Make "$makeName" updated.');
    }
    return error; // the sheet shows it in a red banner
  }

  Future<void> _confirmDelete(Make make) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Make?',
      message: 'Delete make "${make.makeName}"? This cannot be undone.',
    );
    if (!confirmed || !mounted) return;

    final provider = context.read<MakeProvider>();
    final error = await provider.delete(make.id);

    if (!mounted) return;
    if (provider.isUnauthorized) {
      _handleExpired();
      return;
    }

    _showMessage(error ?? 'Make "${make.makeName}" deleted.',
        isError: error != null);
  }

  // ---------------------------------------------------------------------
  // build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MakeProvider>();
    final perms = context.watch<PermissionProvider>();

    // Same permission names the web page checks
    final canView = perms.has('View Make');
    final canAdd = perms.has('Add Make');
    final canEdit = perms.has('Edit Make');
    final canDelete = perms.has('Delete Make');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Make'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: canView && canAdd
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
      body: !canView
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "You don't have permission to view the Make module.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMedium),
                ),
              ),
            )
          : Column(
              children: [
                _buildSearchField(),
                Expanded(child: _buildList(provider, canEdit, canDelete)),
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
          hintText: 'Search make or instrument...',
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

  Widget _buildList(MakeProvider provider, bool canEdit, bool canDelete) {
    final items = provider.filter(_search);

    return RefreshIndicator(
      onRefresh: _load, // pull down to refresh
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // bottom 96 = space so the Add button never hides the last card
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          if (provider.errorMessage != null) ...[
            ErrorBanner(message: provider.errorMessage!),
            const SizedBox(height: 12),
          ],
          if (provider.isLoading && provider.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          if (!provider.isLoading &&
              provider.errorMessage == null &&
              items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Text(
                  'No Data Found',
                  style: TextStyle(color: AppColors.textLight),
                ),
              ),
            ),
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Text(
                '${items.length} ${items.length == 1 ? 'make' : 'makes'}',
                style: const TextStyle(fontSize: 13, color: AppColors.textLight),
              ),
            ),
          ...items.map((m) => _buildCard(m, canEdit, canDelete)),
        ],
      ),
    );
  }

  Widget _buildCard(Make make, bool canEdit, bool canDelete) {
    return AppCard(
      key: ValueKey(make.id),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.label_outline, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  make.makeName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                // The instrument this make belongs to
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    make.instrumentName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              color: AppColors.primary,
              tooltip: 'Edit',
              onPressed: () => _openForm(make: make),
            ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppColors.errorText,
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(make),
            ),
        ],
      ),
    );
  }
}