import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/design_system/glass_tokens.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/features/settings/presentation/screens/about_settings_screen.dart';
import 'package:nexa_player/features/settings/presentation/screens/audio_settings_screen.dart';
import 'package:nexa_player/features/settings/presentation/screens/privacy_storage_settings_screen.dart';
import 'package:nexa_player/features/settings/presentation/screens/scanner_settings_screen.dart';
import 'package:nexa_player/features/settings/presentation/widgets/settings_tiles.dart';
import 'package:nexa_player/shared/widgets/glass/glass_card.dart';
import 'package:nexa_player/shared/widgets/surfaces/nexa_surface.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await configureDependencies(seedDemoData: false);
  });

  tearDown(() async {
    await resetDependencies();
  });
  group('HW-v1.1.1 PR 3/5 (DEF-05) — GlassCard & SettingsGroupCard Padding Tests', () {
    testWidgets('GlassCard default padding is EdgeInsets.all(16.0)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(
              child: Text('Padded Card'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final surface = tester.widget<NexaSurface>(find.byType(NexaSurface));
      expect(surface.padding, equals(const EdgeInsets.all(AppSpacing.md)));
      expect(surface.borderRadius, equals(BorderRadius.circular(GlassTokens.radiusMedium)));
    });

    testWidgets('GlassCard.raw renders with EdgeInsets.zero padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard.raw(
              child: Text('Raw Card'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final surface = tester.widget<NexaSurface>(find.byType(NexaSurface));
      expect(surface.padding, equals(EdgeInsets.zero));
    });

    testWidgets('SettingsGroupCard defaults to 16dp horizontal & 12dp vertical padding with 16dp corner radius', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingsGroupCard(
              title: 'Test Group',
              children: [
                Text('Tile 1'),
                Text('Tile 2'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final surface = tester.widget<NexaSurface>(find.byType(NexaSurface));
      expect(
        surface.padding,
        equals(const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12.0)),
      );
      expect(surface.borderRadius, equals(BorderRadius.circular(16.0)));
    });
  });

  group('HW-v1.1.1 PR 3/5 (DEF-05) — Settings Screens Responsive & Overflow Tests', () {
    final viewports = [
      const Size(360, 780), // Compact mobile (Huawei Y9s, Kirin 710F)
      const Size(412, 915), // Standard Android phone
    ];

    for (final size in viewports) {
      testWidgets('ScannerSettingsScreen renders with zero overflow at ${size.width}x${size.height} (1.3x text scale)', (tester) async {
        tester.view.physicalSize = size * 2.0;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: const TextScaler.linear(1.3),
                ),
                child: const ScannerSettingsScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Media Scanner'), findsOneWidget);
        expect(find.text('Skip Heuristics & Filtering'), findsOneWidget);
      });

      testWidgets('AboutSettingsScreen renders with zero overflow at ${size.width}x${size.height} (1.3x text scale)', (tester) async {
        tester.view.physicalSize = size * 2.0;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: const TextScaler.linear(1.3),
                ),
                child: const AboutSettingsScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('NEXA PLAYER'), findsOneWidget);
        expect(find.text('INFORMATION & LEGAL'), findsOneWidget);
      });

      testWidgets('AudioSettingsScreen renders with zero overflow at ${size.width}x${size.height} (1.3x text scale)', (tester) async {
        tester.view.physicalSize = size * 2.0;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: const TextScaler.linear(1.3),
                ),
                child: const AudioSettingsScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Audio Settings'), findsOneWidget);
        expect(find.text('PLAYBACK & TRANSITIONS'), findsOneWidget);
      });

      testWidgets('PrivacyStorageSettingsScreen renders with zero overflow at ${size.width}x${size.height} (1.3x text scale)', (tester) async {
        tester.view.physicalSize = size * 2.0;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: const TextScaler.linear(1.3),
                ),
                child: const PrivacyStorageSettingsScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Privacy & Storage'), findsOneWidget);
        expect(find.text('PRIVACY & DIAGNOSTICS'), findsOneWidget);
      });
    }
  });
}
