import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/design_system/glass_tokens.dart';
import 'package:nexa_player/shared/widgets/glass/glass.dart';

void main() {
  group('GlassCard Widget Tests', () {
    testWidgets('renders BackdropFilter and ClipRRect when blur is enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(
              blur: GlassTokens.blurStandard,
              child: Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      expect(find.byType(ClipRRect), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);

      final filter = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
      expect(
        filter.filter,
        equals(ImageFilter.blur(sigmaX: GlassTokens.blurStandard, sigmaY: GlassTokens.blurStandard)),
      );
    });

    testWidgets('suppresses BackdropFilter when enableBlur is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(
              enableBlur: false,
              child: Text('No Blur Content'),
            ),
          ),
        ),
      );

      expect(find.text('No Blur Content'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('triggers onTap and onLongPress callbacks', (tester) async {
      var tapped = false;
      var longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassCard(
              onTap: () => tapped = true,
              onLongPress: () => longPressed = true,
              child: const Text('Interactive Card'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Interactive Card'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);

      await tester.longPress(find.text('Interactive Card'));
      await tester.pumpAndSettle();
      expect(longPressed, isTrue);
    });
  });

  group('GlassAppBar Widget Tests', () {
    testWidgets('renders title text, preferredSize, and blur background', (tester) async {
      const appBar = GlassAppBar(
        titleText: 'Now Playing',
        toolbarHeight: 56.0,
      );

      expect(appBar.preferredSize.height, equals(56.0));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: appBar,
            body: SizedBox(),
          ),
        ),
      );

      expect(find.text('Now Playing'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('shows automatically implied back button and pops route', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const Scaffold(
                          appBar: GlassAppBar(titleText: 'Sub Screen'),
                        ),
                      ),
                    );
                  },
                  child: const Text('Navigate'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text('Sub Screen'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Navigate'), findsOneWidget);
    });
  });

  group('GlassBottomNav Widget Tests', () {
    testWidgets('renders 5 primary navigation destinations with keys and labels', (tester) async {
      int selectedTab = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: GlassBottomNav(
              currentIndex: selectedTab,
              onTap: (index) => selectedTab = index,
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('glass_bottom_nav')), findsOneWidget);
      expect(find.byKey(const ValueKey('tab_songs')), findsOneWidget);
      expect(find.byKey(const ValueKey('tab_albums')), findsOneWidget);
      expect(find.byKey(const ValueKey('tab_artists')), findsOneWidget);
      expect(find.byKey(const ValueKey('tab_playlists')), findsOneWidget);
      expect(find.byKey(const ValueKey('tab_settings')), findsOneWidget);

      expect(find.text('Songs'), findsOneWidget);
      expect(find.text('Albums'), findsOneWidget);
      expect(find.text('Artists'), findsOneWidget);
      expect(find.text('Playlists'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('tab_albums')));
      expect(selectedTab, equals(1));
    });
  });

  group('GlassFAB Widget Tests', () {
    testWidgets('renders icon, press scale animation, and tooltip', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: GlassFAB(
              tooltip: 'Play Music',
              icon: const Icon(Icons.play_arrow),
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      await tester.tap(find.byType(GlassFAB));
      await tester.pumpAndSettle();
      expect(pressed, isTrue);
    });

    testWidgets('extended GlassFAB renders icon and label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: GlassFAB(
              icon: const Icon(Icons.shuffle),
              label: const Text('Shuffle'),
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.shuffle), findsOneWidget);
      expect(find.text('Shuffle'), findsOneWidget);
    });
  });

  group('GlassButton Widget Tests', () {
    testWidgets('renders label and triggers onPressed', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassButton(
                label: 'Play',
                icon: Icons.play_arrow,
                onPressed: () => pressed = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Play'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      await tester.tap(find.text('Play'));
      await tester.pumpAndSettle();
      expect(pressed, isTrue);
    });

    testWidgets('loading state shows CircularProgressIndicator and ignores tap', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassButton(
                label: 'Loading',
                isLoading: true,
                onPressed: () => pressed = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsNothing);

      await tester.tap(find.byType(GlassButton));
      await tester.pump(const Duration(milliseconds: 100));
      expect(pressed, isFalse);
    });
  });

  group('GlassTextField Widget Tests', () {
    testWidgets('enters text, clear button appears and clears input', (tester) async {
      final controller = TextEditingController();
      String changedText = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassTextField(
                controller: controller,
                hintText: 'Search...',
                onChanged: (val) => changedText = val,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Search...'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Starlight');
      await tester.pump();

      expect(changedText, equals('Starlight'));
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(changedText, isEmpty);
    });

    testWidgets('renders error text when errorText is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassTextField(
                errorText: 'Invalid query',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Invalid query'), findsOneWidget);
    });
  });

  group('GlassChip Widget Tests', () {
    testWidgets('toggles selection and shows checkmark when selected', (tester) async {
      bool isSelected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) {
                  return GlassChip(
                    label: 'Rock',
                    selected: isSelected,
                    onSelected: (val) => setState(() => isSelected = val),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Rock'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNothing);

      await tester.tap(find.text('Rock'));
      await tester.pumpAndSettle();

      expect(isSelected, isTrue);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });
}
