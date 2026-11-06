import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';

void main() {
  group('AppSpacing Unit Tests', () {
    test('verifies 8-step spacing scale constants (4, 8, 12, 16, 24, 32, 48, 64 dp)', () {
      expect(AppSpacing.space4, equals(4.0));
      expect(AppSpacing.space8, equals(8.0));
      expect(AppSpacing.space12, equals(12.0));
      expect(AppSpacing.space16, equals(16.0));
      expect(AppSpacing.space24, equals(24.0));
      expect(AppSpacing.space32, equals(32.0));
      expect(AppSpacing.space48, equals(48.0));
      expect(AppSpacing.space64, equals(64.0));

      expect(AppSpacing.xxs, equals(4.0));
      expect(AppSpacing.xs, equals(8.0));
      expect(AppSpacing.sm, equals(12.0));
      expect(AppSpacing.md, equals(16.0));
      expect(AppSpacing.lg, equals(24.0));
      expect(AppSpacing.xl, equals(32.0));
      expect(AppSpacing.xxl, equals(48.0));
      expect(AppSpacing.xxxl, equals(64.0));
    });

    test('verifies gap square widgets match dimension constants', () {
      expect(AppSpacing.gap4.width, equals(4.0));
      expect(AppSpacing.gap4.height, equals(4.0));
      expect(AppSpacing.gap8.width, equals(8.0));
      expect(AppSpacing.gap8.height, equals(8.0));
      expect(AppSpacing.gap16.width, equals(16.0));
      expect(AppSpacing.gap16.height, equals(16.0));
      expect(AppSpacing.gap24.width, equals(24.0));
      expect(AppSpacing.gap24.height, equals(24.0));
      expect(AppSpacing.gap32.width, equals(32.0));
      expect(AppSpacing.gap32.height, equals(32.0));
      expect(AppSpacing.gap48.width, equals(48.0));
      expect(AppSpacing.gap48.height, equals(48.0));
      expect(AppSpacing.gap64.width, equals(64.0));
      expect(AppSpacing.gap64.height, equals(64.0));
    });

    test('verifies directional helpers', () {
      final h = AppSpacing.horizontal(20.0);
      final v = AppSpacing.vertical(30.0);
      expect(h.width, equals(20.0));
      expect(h.height, isNull);
      expect(v.height, equals(30.0));
      expect(v.width, isNull);
    });
  });
}
