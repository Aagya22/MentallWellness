class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'http://localhost:5050/';

  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // -------------------------- AUTH -------------------------
  static const String user = '/auth';
  static const userLogin = '/auth/login';
  static const userRegister = '/auth/register';
}