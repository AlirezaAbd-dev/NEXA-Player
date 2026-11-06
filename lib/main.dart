import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize service locator (SharedPreferences, TalkerLoggingService, etc.)
  await configureDependencies();

  runApp(
    const ProviderScope(
      child: NexaPlayerApp(),
    ),
  );
}
