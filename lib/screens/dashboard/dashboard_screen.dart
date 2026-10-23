import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/dashboard_summary.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/permission_provider.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/stat_card.dart';
import '../department/department_screen.dart';

/// One module tile. It shows only if the user has [permission]
/// (names are the same ones the React app checks with hasPermission).
class _Module {
  final String permission;
  final String label;
  final IconData icon;

  /// null = screen not built yet (tile shows "coming soon").
  final Widget Function()? screenBuilder;

  const _Module(this.permission, this.label, this.icon, {this.screenBuilder});
}

final _modules = [
  _Module('View Calibration', 'Calibration', Icons.build_circle_outlined),
  _Module('View Scrap', 'Scrap', Icons.delete_outline),
  _Module('View Report', 'Reports', Icons.bar_chart_rounded),
  _Module('View Traceability', 'Traceability', Icons.account_tree_outlined),
  _Module('View NABL', 'NABL', Icons.workspace_premium_outlined),
  _Module('View Instrument', 'Instruments', Icons.precision_manufacturing_outlined),
  _Module('View Instrument Configuration', 'Config', Icons.tune),
  _Module('View Machine', 'Machines', Icons.settings_outlined),
  _Module('View Department', 'Departments', Icons.apartment_outlined, screenBuilder: () => const DepartmentScreen(),),
  _Module('View Make', 'Make', Icons.label_outline),
  _Module('View Mail', 'Mail', Icons.mail_outline),
];

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _expiredMessage = 'Session expired. Please login again.';

  @override
  void initState() {
    super.initState();
    // Load after the first frame (we cannot notify listeners during build).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  /// Loads dashboard numbers and permissions together.
  Future<void> _load() async {
    final dashboard = context.read<DashboardProvider>();
    final permissions = context.read<PermissionProvider>();
    final auth = context.read<AuthProvider>();

    await Future.wait([dashboard.load(), permissions.load()]);

    if (!mounted) return;
    // Server said 401: session is dead, so go back to Login.
    if (dashboard.isUnauthorized || permissions.isUnauthorized) {
      await auth.logout(message: _expiredMessage);
    }
  }

  Future<void> _changeYear(int delta) async {
    final dashboard = context.read<DashboardProvider>();
    final auth = context.read<AuthProvider>();

    await dashboard.changeYear(delta);

    if (!mounted) return;
    if (dashboard.isUnauthorized) {
      await auth.logout(message: _expiredMessage);
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(15),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // watch = rebuild whenever these providers call notifyListeners()
    final dash = context.watch<DashboardProvider>();
    final perms = context.watch<PermissionProvider>();
    final user = context.read<AuthProvider>().user;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light, // white status bar icons
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          onRefresh: _load, // pull down to refresh
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              _buildHeader(user?.username ?? '', user?.role ?? '', dash),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dash.errorMessage != null) ...[
                      ErrorBanner(message: dash.errorMessage!),
                      const SizedBox(height: 12),
                      PrimaryButton(label: 'Try again', onPressed: _load),
                      const SizedBox(height: 20),
                    ],
                    if (dash.isLoading && dash.summary == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    if (dash.summary != null) ..._buildSummary(dash.summary!),
                    const SizedBox(height: 24),
                    _buildModulesSection(perms),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Header (greeting, role, year selector, logout)
  // ---------------------------------------------------------------------

  Widget _buildHeader(String username, String role, DashboardProvider dash) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12, // below the status bar
        8,
        24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                color: Colors.white,
                tooltip: 'Logout',
                // After logout, AuthGate automatically shows LoginScreen.
                onPressed: () => context.read<AuthProvider>().logout(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_buildRoleChip(role), _buildYearSelector(dash)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.badge_outlined, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            role.isEmpty ? 'User' : role,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelector(DashboardProvider dash) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_left),
            color: Colors.white,
            disabledColor: Colors.white38,
            // null = disabled while loading
            onPressed: dash.isLoading ? null : () => _changeYear(-1),
          ),
          Text(
            '${dash.year}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_right),
            color: Colors.white,
            disabledColor: Colors.white38,
            onPressed: dash.isLoading ? null : () => _changeYear(1),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Summary: progress card + the same 5 cards as the web dashboard
  // ---------------------------------------------------------------------

  List<Widget> _buildSummary(DashboardSummary s) {
    return [
      _buildProgressCard(s),
      const SizedBox(height: 16),
      _statRow(
        StatCard(
          label: 'Planned',
          value: s.planned,
          icon: Icons.event_note_outlined,
          color: AppColors.planned,
        ),
        StatCard(
          label: 'Calibrated',
          value: s.calibrated,
          icon: Icons.verified_outlined,
          color: AppColors.calibrated,
        ),
      ),
      const SizedBox(height: 12),
      _statRow(
        StatCard(
          label: 'Scrap',
          value: s.scrap,
          icon: Icons.delete_outline,
          color: AppColors.scrap,
        ),
        StatCard(
          label: 'Removed',
          value: s.removed,
          icon: Icons.remove_circle_outline,
          color: AppColors.replaced,
        ),
      ),
      const SizedBox(height: 12),
      // Fifth card: full width
      SizedBox(
        width: double.infinity,
        child: StatCard(
          label: 'Total Instruments',
          value: s.totalInstruments,
          icon: Icons.precision_manufacturing_outlined,
          color: AppColors.instruments,
        ),
      ),
    ];
  }

  Widget _statRow(Widget left, Widget right) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget _buildProgressCard(DashboardSummary s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      // Bar and percentage animate from 0 to the real value
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: s.progress),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calibration progress',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(value * 100).round()}%',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: AppColors.border,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${s.calibrated} of ${s.workTotal} calibrations done',
              style: const TextStyle(fontSize: 13, color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // "Your modules": tiles shown only for the "View ..." permissions
  // ---------------------------------------------------------------------

  Widget _buildModulesSection(PermissionProvider perms) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your modules',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 12),
          _buildModulesBody(perms),
        ],
      ),
    );
  }

  Widget _buildModulesBody(PermissionProvider perms) {
    if (perms.isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.primary,
        ),
      );
    }

    if (perms.errorMessage != null) {
      return Text(
        perms.errorMessage!,
        style: const TextStyle(fontSize: 13, color: AppColors.errorText),
      );
    }

    // Keep only the modules this user's role is allowed to view
    final allowed = _modules.where((m) => perms.has(m.permission)).toList();

    if (allowed.isEmpty) {
      return const Text(
        'No modules assigned to your role.',
        style: TextStyle(fontSize: 13, color: AppColors.textLight),
      );
    }

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true, // grid sits inside the page ListView
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: allowed.map(_buildModuleTile).toList(),
    );
  }

  Widget _buildModuleTile(_Module module) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        final builder = module.screenBuilder;

        // Screen not built yet
        if (builder == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${module.label} screen is coming soon')),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => builder()),
        );
      },
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(module.icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                module.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
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
    );
  }
}