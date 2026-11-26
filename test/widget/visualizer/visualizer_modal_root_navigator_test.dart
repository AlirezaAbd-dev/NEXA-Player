import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/visualizer/domain/models/visualizer_settings.dart';
import 'package:nexa_player/features/visualizer/presentation/providers/visualizer_providers.dart';
import 'package:nexa_player/features/visualizer/presentation/screens/visualizer_settings_screen.dart';

class _TestVisualizerNotifier extends VisualizerSettingsNotifier {
  _TestVisualizerNotifier(super.ref);

  @override
  Future<void> update(VisualizerSettings next) async {
    state = next;
  }

  @override
  Future<bool> requestLiveFftPermissionIfActivated() async => true;
}

void main() {
  testWidgets(
    'VisualizerSettingsScreen selector modals render on root navigator above MiniPlayer overlay',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            visualizerSettingsProvider.overrideWith(
              (ref) => _TestVisualizerNotifier(ref),
            ),
            liveMagnitudesProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: MaterialApp(
            home: Stack(
              children: [
                // Nested Navigator mimicking StatefulNavigationShell
                Navigator(
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                    builder: (_) => const VisualizerSettingsScreen(),
                  ),
                ),
                // Persistent MiniPlayer overlay sitting above the nested Navigator
                const Positioned(
                  left: 12,
                  right: 12,
                  bottom: 16,
                  height: 76,
                  child: Material(
                    key: ValueKey('mock_mini_player'),
                    color: Colors.black,
                    child: Center(child: Text('MiniPlayer Playing')),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Visualization Mode selector modal
      await tester.ensureVisible(find.text('Visualization Mode'));
      await tester.tap(find.text('Visualization Mode'));
      await tester.pumpAndSettle();

      // The bottom-most option ("Disabled") must be rendered ABOVE the MiniPlayer
      // on the root navigator and be directly tappable (not obscured).
      final disabledOption = find.text('Disabled');
      expect(disabledOption, findsOneWidget);
      await tester.tap(disabledOption);
      await tester.pumpAndSettle();

      // Modal closed and setting updated to VisualizerStyle.off
      await tester.drag(find.byType(ListView).first, const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(find.text('Mode: OFF'), findsOneWidget);
    },
  );
}
