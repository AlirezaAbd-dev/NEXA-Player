import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize service locator (SharedPreferences, TalkerLoggingService, etc.)
  // Explicitly ensure demo seeding is disabled in production so the user's library reflects real storage.
  await configureDependencies(seedDemoData: false);

  runApp(
    const ProviderScope(
      child: NexaPlayerApp(),
    ),
  );
}
