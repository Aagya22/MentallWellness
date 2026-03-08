import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/app.dart';
import 'package:mentalwellness/core/services/hive/hive_service.dart';
import 'package:mentalwellness/core/services/storage/user_session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 4. Set System UI Styles
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  // Initialize Hive Service
  final hiveService = HiveService();
  final hiveInitFuture = hiveService.init();
  // 5. Initialize SharedPreferences instance
  final sharedPreferencesFuture = SharedPreferences.getInstance();

  await hiveInitFuture;
  final sharedPreferences = await sharedPreferencesFuture;

  runApp(
    ProviderScope(
      overrides: [
        // Inject initialized SharedPreferences into the provider
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const App(),
    ),
  );
}

