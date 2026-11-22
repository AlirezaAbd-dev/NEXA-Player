import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/theme/dynamic_palette_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DynamicPaletteService service;

  setUp(() {
    service = const DynamicPaletteService();
  });

  group('DynamicPaletteService', () {
    test('computeSeedPalette generates non-null and valid contrast colors', () {
      const seed = 'Starboy - The Weeknd - Starboy Album';
      final palette = service.computeSeedPalette(seed);

      expect(palette.dominant, isNotNull);
      expect(palette.vibrant, isNotNull);
      expect(palette.muted, isNotNull);
      expect(palette.darkVibrant, isNotNull);
      expect(palette.lightVibrant, isNotNull);

      // Verify convenience getters
      expect(palette.primary, equals(palette.vibrant));
      expect(palette.secondary, equals(palette.dominant));
      expect(palette.tertiary, equals(palette.muted));

      // Dark vibrant should have low luminance suitable for AMOLED backdrops
      expect(palette.darkVibrant.computeLuminance(), lessThan(0.35));
      // Light vibrant should have high luminance suitable for contrast
      expect(palette.lightVibrant.computeLuminance(), greaterThan(0.50));
    });

    test('computeSeedPalette is deterministic for the same seed string', () {
      const seed = 'Interstellar Overdrive - Pink Floyd';
      final palette1 = service.computeSeedPalette(seed);
      final palette2 = service.computeSeedPalette(seed);

      expect(palette1, equals(palette2));
      expect(palette1.hashCode, equals(palette2.hashCode));
      expect(palette1.vibrant, equals(palette2.vibrant));
      expect(palette1.dominant, equals(palette2.dominant));
    });

    test('computeSeedPalette produces distinct palettes for different seeds', () {
      final paletteA = service.computeSeedPalette('Track Alpha');
      final paletteB = service.computeSeedPalette('Track Omega');

      expect(paletteA.vibrant != paletteB.vibrant ||
             paletteA.dominant != paletteB.dominant, isTrue);
    });

    test('ExtractedPalette fallback is canonical neon cyan & orchid', () {
      const fallback = ExtractedPalette.fallback;

      expect(fallback.dominant, const Color(0xFF00E5FF));
      expect(fallback.vibrant, const Color(0xFFD946EF));
      expect(fallback.primary, const Color(0xFFD946EF));
      expect(fallback.secondary, const Color(0xFF00E5FF));
      expect(fallback.muted, const Color(0xFF334155));
    });

    test('extractPalette falls back gracefully to seed when file does not exist', () async {
      final palette = await service.extractPalette(
        trackId: 'test_track_123',
        albumArtPath: '/non/existent/album_art.png',
        seedText: 'Cyberpunk 2077 - Rebel Path',
      );

      expect(palette, isNotNull);
      expect(palette.primary, isNotNull);
      expect(palette.darkVibrant.computeLuminance(), lessThan(0.35));
    });

    test('extractPalette caches results for identical track and seed', () async {
      final p1 = await service.extractPalette(
        trackId: 'cached_track_1',
        seedText: 'Blinding Lights',
      );
      final p2 = await service.extractPalette(
        trackId: 'cached_track_1',
        seedText: 'Blinding Lights',
      );

      expect(identical(p1, p2), isTrue);
    });
  });
}
