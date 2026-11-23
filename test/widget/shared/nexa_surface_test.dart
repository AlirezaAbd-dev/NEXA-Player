import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/design_system/nexa_surface_tokens.dart';
import 'package:nexa_player/shared/widgets/glass/glass_card.dart';
import 'package:nexa_player/shared/widgets/surfaces/nexa_surface.dart';

void main() {
  group('NexaSurface & Borderless Paradigm Widget Tests', () {
    testWidgets('default NexaSurface has NO border (border is null)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NexaSurface(
              child: Text('Borderless Surface'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(NexaSurface),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNull, reason: 'NexaSurface must be borderless by default');
    });

    testWidgets('GlassCard delegating to NexaSurface has NO border by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(
              child: Text('Borderless GlassCard'),
            ),
          ),
        ),
      );

      expect(find.byType(NexaSurface), findsOneWidget);

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(NexaSurface),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNull, reason: 'GlassCard must be borderless by default');
    });

    testWidgets('renders focusRing border outline when SurfaceBorderReason.focusRing is specified', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NexaSurface(
              borderReason: SurfaceBorderReason.focusRing,
              borderWidth: 2.0,
              child: Text('Focused Node'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(NexaSurface),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
      expect(decoration.border!.top.width, equals(2.0));
    });

    testWidgets('renders activeControlContrast border when SurfaceBorderReason.activeControlContrast is specified', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NexaSurface(
              borderReason: SurfaceBorderReason.activeControlContrast,
              customBorderColor: Color(0xFF00E5FF),
              child: Text('Active Swatch'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(NexaSurface),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
      expect(decoration.border!.top.color, equals(const Color(0xFF00E5FF)));
    });

    testWidgets('renders red destructive outline when SurfaceBorderReason.destructiveSecondary is specified', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NexaSurface(
              borderReason: SurfaceBorderReason.destructiveSecondary,
              child: Text('Clear Cache'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(NexaSurface),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
      expect(decoration.border!.top.color, equals(const Color(0xFFFF3B30)));
    });

    testWidgets('tier: L3 floating resolves diffuse shadow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NexaSurface(
              tier: NexaSurfaceTier.l3,
              child: Text('Floating Sheet'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(NexaSurface),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNotEmpty);
    });

    testWidgets('blurSigma > 0 adds BackdropFilter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NexaSurface(
              blurSigma: 16.0,
              child: Text('Blurred Surface'),
            ),
          ),
        ),
      );

      expect(find.byType(BackdropFilter), findsOneWidget);
      final filter = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
      expect(filter.filter, equals(ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0)));
    });

    testWidgets('NexaSurface tap and long press callbacks fire', (tester) async {
      var tapped = false;
      var longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NexaSurface(
              onTap: () => tapped = true,
              onLongPress: () => longPressed = true,
              child: const Text('Interactive Surface'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Interactive Surface'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);

      await tester.longPress(find.text('Interactive Surface'));
      await tester.pumpAndSettle();
      expect(longPressed, isTrue);
    });
  });
}
