import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/storage/session_storage.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/dashboard_repository.dart';
import 'data/repositories/department_repository.dart';
import 'data/repositories/permission_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/department_provider.dart';
import 'providers/permission_provider.dart';

void main() {
  // One ApiClient is shared by every repository, so they all use
  // the same session cookie.
  final sessionStorage = SessionStorage();
  final apiClient = ApiClient(sessionStorage: sessionStorage);

  final authRepository = AuthRepository(apiClient, sessionStorage);
  final permissionRepository = PermissionRepository(apiClient);
  final dashboardRepository = DashboardRepository(apiClient);
  final departmentRepository = DepartmentRepository(apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository)..restoreSession(),
        ),
        ChangeNotifierProvider(
          create: (_) => PermissionProvider(permissionRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(dashboardRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => DepartmentProvider(departmentRepository),
        ),
      ],
      child: const App(),
    ),
  );
}