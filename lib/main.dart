import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/constants/app_colors.dart';
import 'core/storage/session_storage.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // Hold the native splash until the Dart splash has laid out, so the launch
  // never shows a half-sized first frame.
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  final prefs = await SharedPreferences.getInstance();
  final storage = SessionStorage(prefs);
  AppColors.apply(AppThemeMode.fromStorage(storage.getThemeMode()));

  runApp(
    ProviderScope(
      overrides: [
        sessionStorageProvider.overrideWithValue(storage),
      ],
      child: const StockShieldApp(),
    ),
  );
}
