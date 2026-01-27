class ApiEndpoints {
  ApiEndpoints._();

  // static const String baseUrl = 'http://10.0.2.2:5050/';
  // For Physical Device use your computer's IP: 'http://192.168.x.x:5000/api/v1'
  static const String baseUrl = 'http://192.168.1.6:5050/';

  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // -------------------------- AUTH -------------------------
  static const String user = '/api/auth';
  static const userLogin = '/api/auth/login';
  static const userRegister = '/api/auth/register';
}