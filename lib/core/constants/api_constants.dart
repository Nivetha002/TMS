/// All backend URL details in ONE place.
/// Later if the server IP changes, only this file needs editing.
class ApiConstants {
  ApiConstants._(); // private constructor: this class is never instantiated

  // Android emulator: 10.0.2.2 = your PC's localhost.
  // (Real phone later: use http://<PC-LAN-IP>:5051/api)
  static const String baseUrl = 'http://10.0.2.2:5051/api';

  static const String loginEndpoint = '/Login/login';
  static const String logoutEndpoint = '/Login/logout';

  // Used only to check "is my saved session still valid?"
  static const String sessionCheckEndpoint = '/Access/my-permissions';

  static const String dashboardEndpoint = '/Dashboard/dashboard';
  static const String permissionsEndpoint = '/Access/my-permissions';

    // Department module (the id is added at the end for update and delete)
  static const String departmentListEndpoint = '/Department/get-alldepartment';
  static const String departmentAddEndpoint = '/Department/add-department';
  static const String departmentUpdateEndpoint = '/Department/update';
  static const String departmentDeleteEndpoint = '/Department/delete';

  static const Duration requestTimeout = Duration(seconds: 15);
}