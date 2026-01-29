import 'dart:io';
import 'package:flutter/foundation.dart';


class ApiEndpoints {
ApiEndpoints._();


static const bool isPhysicalDevice = true;
static const String _ipAddress = '192.168.1.5';
static const int _port = 5050;


static String get baseUrl {
if (kIsWeb) return 'http://$_ipAddress:$_port/';
if (isPhysicalDevice) return 'http://$_ipAddress:$_port/';
if (Platform.isAndroid) return 'http://10.0.2.2:$_port/';
if (Platform.isIOS) return 'http://localhost:$_port/';
return 'http://localhost:$_port/';
}

static const Duration connectionTimeout = Duration(seconds: 30);
static const Duration receiveTimeout = Duration(seconds: 30);


static const String user = '/api/auth';
static const String userLogin = '/api/auth/login';
static const String userRegister = '/api/auth/register';
static const String userUpdateProfile = '/api/auth/update-profile';


static String getImageUrl(String? imagePath) {
if (imagePath == null || imagePath.isEmpty) return '';
final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
final path = imagePath.startsWith('/') ? imagePath : '/$imagePath';
return '$base$path';
}
}