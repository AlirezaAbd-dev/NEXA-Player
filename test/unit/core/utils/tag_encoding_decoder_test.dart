import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/core/theme/app_theme.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/core/utils/tag_encoding_decoder.dart';
import 'package:nexa_player/features/scanner/data/pure_dart_audio_metadata_reader.dart';
import 'package:nexa_player/features/search/data/repositories/sqlite_search_repository.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:nexa_player/shared/services/database/database_schema.dart';
import 'package:nexa_player/shared/services/storage/storage_service.dart';
import 'package:nexa_player/shared/widgets/cards/track_tile.dart';
import 'package:nexa_player/shared/widgets/typography/bidi_text.dart';

class _StubStorage implements IStorageService {
  final Map<String, String> _map = {};
  @override
  Future<Result<void, StorageFailure>> setString(String key, String value) async {
    _map[key] = value;
    return const Success(null);
  }

  @override
  Result<String?, StorageFailure> getString(String key) => Success(_map[key]);

  @override
  Future<Result<void, StorageFailure>> setBool(String key, bool value) async =>
      const Success(null);

  @override
  Result<bool?, StorageFailure> getBool(String key) => const Success(null);

  @override
  Future<Result<void, StorageFailure>> remove(String key) async =>
      const Success(null);

  @override
  Future<Result<void, StorageFailure>> clear() async => const Success(null);
}

Uint8List _encodeUtf16LeWithBom(String text) {
  final units = text.codeUnits;
  final out = <int>[0xFF, 0xFE];
  for (final u in units) {
    out.add(u & 0xFF);
    out.add((u >> 8) & 0xFF);
  }
  return Uint8List.fromList(out);
}

Uint8List _buildId3v2Buffer(List<(String, int, Uint8List)> frames) {
  final body = <int>[];
  for (final (id, enc, payload) in frames) {
    final frameData = [enc, ...payload];
    body.addAll(id.codeUnits);
    body.addAll([
      (frameData.length >> 24) & 0xFF,
      (frameData.length >> 16) & 0xFF,
      (frameData.length >> 8) & 0xFF,
      frameData.length & 0xFF,
      0x00,
      0x00,
    ]);
    body.addAll(frameData);
  }
  final tagSize = body.length;
  return Uint8List.fromList([
    0x49, 0x44, 0x33, 0x03, 0x00, 0x00,
    (tagSize >> 21) & 0x7F,
    (tagSize >> 14) & 0x7F,
    (tagSize >> 7) & 0x7F,
    tagSize & 0x7F,
    ...body,
    0xFF, 0xFB, 0x90, 0x00,
  ]);
}

void main() {
  group('TagEncodingDecoder - Persian / CP1256 / UTF-8 / UTF-16', () {
    test('decodes legacy Windows-1256 Persian bytes tagged with encoding 0x00 without mojibake', () {
      // CP1256 bytes for "پنجره" (0x81=پ, 0xE4=ن, 0xCC=ج, 0xD1=ر, 0xE5=ه)
      final cp1256Window = Uint8List.fromList([0x81, 0xE4, 0xCC, 0xD1, 0xE5]);
      final decoded = TagEncodingDecoder.decodeId3Text(0x00, cp1256Window);
      expect(decoded, 'پنجره');

      // Persian-specific CP1256 letters: پ چ ژ گ ک
      final cp1256Letters = Uint8List.fromList([0x81, 0x8D, 0x8E, 0x90, 0x98]);
      expect(TagEncodingDecoder.decodeWindows1256(cp1256Letters), 'پچژگک');
    });

    test('preserves valid UTF-8 tagged as 0x03 or mislabeled as 0x00, and decodes UTF-16LE BOM', () {
      const sample = 'عاشقانه - شادمهر عقیلی';
      final utf8Bytes = Uint8List.fromList(utf8.encode(sample));
      expect(TagEncodingDecoder.decodeId3Text(0x03, utf8Bytes), sample);
      expect(TagEncodingDecoder.decodeId3Text(0x00, utf8Bytes), sample);

      final utf16LeBytes = _encodeUtf16LeWithBom(sample);
      expect(TagEncodingDecoder.decodeId3Text(0x01, utf16LeBytes), sample);
    });

    test('repairs double-encoded UTF-8 and CP1256 mojibake strings from MediaStore', () {
      const original = 'شادمهر عقیلی';
      final latin1MangledUtf8 = latin1.decode(utf8.encode(original));
      expect(latin1MangledUtf8, isNot(equals(original)));
      expect(TagEncodingDecoder.repairMojibake(latin1MangledUtf8), original);

      // Clean Persian UTF-8 passes through untouched
      expect(TagEncodingDecoder.repairMojibake(original), original);
    });

    test('PureDartAudioMetadataReader extracts Persian CP1256 ID3v2 and ID3v1 tags cleanly', () {
      const reader = PureDartAudioMetadataReader();

      final mp3Cp1256 = _buildId3v2Buffer([
        ('TIT2', 0x00, TagEncodingDecoder.encodeWindows1256('تهران')),
        ('TPE1', 0x00, TagEncodingDecoder.encodeWindows1256('شادمهر')),
        ('TALB', 0x01, _encodeUtf16LeWithBom('طرفدار')),
      ]);
      final meta = reader.extractBytes(mp3Cp1256, 'fallback');
      expect(meta.title, 'تهران');
      expect(meta.artist, contains('شادمهر'));
      expect(meta.album, 'طرفدار');

      // ID3v1 at tail
      final id3v1 = Uint8List(128);
      id3v1.setRange(0, 3, 'TAG'.codeUnits);
      final titleBytes = TagEncodingDecoder.encodeWindows1256('باران');
      id3v1.setRange(3, 3 + titleBytes.length, titleBytes);
      final artistBytes = TagEncodingDecoder.encodeWindows1256('سياوش');
      id3v1.setRange(33, 33 + artistBytes.length, artistBytes);
      final v1Meta = reader.extractBytes(id3v1, 'fallback');
      expect(v1Meta.title, 'باران');
    });
  });

  group('QueryNormalizer & Persian Search', () {
    test('normalizes Arabic ي/ك/ة and ZWNJ transparently for Persian search queries', () {
      expect(
        QueryNormalizer.normalizeForSearch('شادمهر عقيلي'), // Arabic ي
        QueryNormalizer.normalizeForSearch('شادمهر عقیلی'), // Persian ی
      );
      expect(
        QueryNormalizer.normalizeForSearch('كوه كوير'), // Arabic ك
        QueryNormalizer.normalizeForSearch('کوه کویر'), // Persian ک
      );
      expect(
        QueryNormalizer.containsNormalized('می‌خواهم تو را', 'میخواهم'),
        isTrue,
      );
      expect(
        QueryNormalizer.normalizeForSearch('۱۲۳۴'),
        '1234',
      );
    });

    test('SqliteSearchRepository finds Persian tracks when queried with Arabic ي/ك or ZWNJ differences', () async {
      final db = AppDatabase.inMemory();
      addTearDown(db.close);
      final searchRepo = SqliteSearchRepository(database: db, storage: _StubStorage());

      db.execute('''
        INSERT INTO ${DatabaseSchema.tableTracks} (
          ${DatabaseSchema.colId}, ${DatabaseSchema.colTitle}, ${DatabaseSchema.colTrackArtist},
          ${DatabaseSchema.colTrackAlbum}, ${DatabaseSchema.colDurationMs}, ${DatabaseSchema.colTrackFilePath},
          ${DatabaseSchema.colDateAdded}
        ) VALUES (?, ?, ?, ?, ?, ?, ?);
      ''', [
        'trk-fa-1',
        'می‌خواهم برگردی',
        'شادمهر عقیلی',
        'طرفدار',
        210000,
        '/music/shadmehr.mp3',
        1000,
      ]);

      // Search using Arabic ي instead of Persian ی
      final resArabicYa = await searchRepo.search(query: 'عقيلي');
      expect(resArabicYa.valueOrNull?.tracks.length, 1);
      expect(resArabicYa.valueOrNull?.tracks.first.id, 'trk-fa-1');

      // Search omitting ZWNJ
      final resNoZwnj = await searchRepo.search(query: 'میخواهم');
      expect(resNoZwnj.valueOrNull?.tracks.length, 1);
    });
  });

  group('Bidi/RTL Directionality & Persian Typography Widget Rendering', () {
    test('detectBidiDirection resolves RTL vs LTR by first strong character', () {
      expect(TagEncodingDecoder.detectBidiDirection('شادمهر عقیلی - Starboy'), TextDirection.rtl);
      expect(TagEncodingDecoder.detectBidiDirection('01 - تهران (Live 2026)'), TextDirection.rtl);
      expect(TagEncodingDecoder.detectBidiDirection('Starboy - شادمهر'), TextDirection.ltr);
      expect(TagEncodingDecoder.detectBidiDirection('03:45'), TextDirection.ltr);
    });

    testWidgets('renders Persian & mixed RTL/LTR track titles cleanly at 360x780 without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const tracks = [
        Track(
          id: 'p1',
          title: 'عاشقانه - شادمهر عقیلی',
          artist: 'شادمهر عقیلی',
          album: 'تهران (Live 2026)',
          duration: Duration(minutes: 4, seconds: 12),
          bitrate: 320,
        ),
        Track(
          id: 'p2',
          title: 'Starboy - شادمهر',
          artist: 'The Weeknd',
          album: 'After Hours',
          duration: Duration(minutes: 3, seconds: 50),
          bitrate: 320,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: ListView(
              children: [
                for (final t in tracks) TrackTile.fromTrack(track: t),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('عاشقانه - شادمهر عقیلی'), findsOneWidget);
      expect(find.text('Starboy - شادمهر'), findsOneWidget);
      expect(find.byType(BidiText), findsWidgets);

      final bidiTitle = tester.widget<Text>(find.text('عاشقانه - شادمهر عقیلی'));
      expect(bidiTitle.textDirection, TextDirection.rtl);
      expect(bidiTitle.style?.fontFamilyFallback, equals(AppTypography.persianFontFallback));

      final ltrTitle = tester.widget<Text>(find.text('Starboy - شادمهر'));
      expect(ltrTitle.textDirection, TextDirection.ltr);

      expect(tester.takeException(), isNull);
    });
  });
}
