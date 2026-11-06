import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/app/app.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await configureDependencies();
  });

  tearDown(() async {
    await resetDependencies();
  });

  testWidgets('NexaPlayerApp boots cleanly and renders Songs shell tab', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: NexaPlayerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Songs'), findsWidgets);
    expect(find.text('Starboy'), findsWidgets);
  });
}
