import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:nexa_player/features/scanner/domain/audio_metadata_reader.dart';

/// Pure Dart audio metadata extractor capable of parsing ID3v2, WAV, and FLAC headers
/// across desktop (Linux, Windows, macOS) and mobile platforms without external C/FFI bindings.
class PureDartAudioMetadataReader implements IAudioMetadataReader {
  const PureDartAudioMetadataReader();

  @override
  Future<ExtractedMetadata> extract(File file) async {
    final bytes = await file.readAsBytes();
    if (bytes.length < 10) {
      throw const FormatException('File too short to be valid audio');
    }
    final ext = file.path.split('.').last.toLowerCase();
    final fallbackTitle = file.uri.pathSegments.last.replaceAll('.$ext', '');
    return extractBytes(bytes, fallbackTitle);
  }

  @override
  ExtractedMetadata extractBytes(Uint8List bytes, String fallbackTitle) {
    if (bytes.length >= 10 &&
        bytes[0] == 0x49 &&
        bytes[1] == 0x44 &&
        bytes[2] == 0x33) {
      return _parseId3v2(bytes, fallbackTitle);
    }
    if (bytes.length >= 44 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46) {
      return _parseWav(bytes, fallbackTitle);
    }
    if (bytes.length >= 42 &&
        bytes[0] == 0x66 &&
        bytes[1] == 0x4C &&
        bytes[2] == 0x61 &&
        bytes[3] == 0x43) {
      return _parseFlac(bytes, fallbackTitle);
    }
    return ExtractedMetadata(
      title: fallbackTitle,
      artist: 'Unknown Artist',
      album: 'Unknown Album',
      duration: const Duration(seconds: 180),
      bitrate: 320,
    );
  }

  ExtractedMetadata _parseId3v2(Uint8List bytes, String fallbackTitle) {
    var title = fallbackTitle;
    var artist = 'Unknown Artist';
    var album = 'Unknown Album';
    var duration = const Duration(seconds: 180);
    String? genre;
    int? year;
    int? trackNumber;
    int? discNumber;
    Uint8List? artwork;

    try {
      final tagSize = ((bytes[6] & 0x7F) << 21) |
          ((bytes[7] & 0x7F) << 14) |
          ((bytes[8] & 0x7F) << 7) |
          (bytes[9] & 0x7F);

      var offset = 10;
      final maxOffset = (10 + tagSize).clamp(10, bytes.length);

      while (offset + 10 <= maxOffset) {
        if (bytes[offset] == 0) break; // ID3 padding
        final frameId =
            ascii.decode(bytes.sublist(offset, offset + 4), allowInvalid: true);
        final frameSize = (bytes[offset + 4] << 24) |
            (bytes[offset + 5] << 16) |
            (bytes[offset + 6] << 8) |
            bytes[offset + 7];

        offset += 10;
        if (frameSize <= 0 || offset + frameSize > bytes.length) break;

        final frameData = bytes.sublist(offset, offset + frameSize);
        offset += frameSize;

        if (frameData.isEmpty) continue;
        final encoding = frameData[0];
        final textData = frameData.sublist(1);
        final text = (encoding == 0x03)
            ? utf8.decode(textData, allowMalformed: true).trim()
            : ascii.decode(textData, allowInvalid: true).trim();

        switch (frameId) {
          case 'TIT2':
            if (text.isNotEmpty) title = text;
            break;
          case 'TPE1':
            if (text.isNotEmpty) artist = text;
            break;
          case 'TALB':
            if (text.isNotEmpty) album = text;
            break;
          case 'TCON':
            if (text.isNotEmpty) genre = text;
            break;
          case 'TYER':
          case 'TDRC':
            year = int.tryParse(text);
            break;
          case 'TRCK':
            final clean = text.split('/').first;
            trackNumber = int.tryParse(clean);
            break;
          case 'TPOS':
            final clean = text.split('/').first;
            discNumber = int.tryParse(clean);
            break;
          case 'TLEN':
            final ms = int.tryParse(text);
            if (ms != null) {
              duration = Duration(milliseconds: ms);
            }
            break;
          case 'APIC':
            if (frameData.length > 5) {
              artwork = frameData;
            }
            break;
        }
      }
    } catch (_) {
      // Fall back gracefully with partial results
    }

    return ExtractedMetadata(
      title: title,
      artist: artist,
      album: album,
      duration: duration,
      year: year,
      trackNumber: trackNumber,
      discNumber: discNumber,
      genre: genre,
      bitrate: 320,
      artworkBytes: artwork,
    );
  }

  ExtractedMetadata _parseWav(Uint8List bytes, String fallbackTitle) {
    final byteRate =
        bytes[28] | (bytes[29] << 8) | (bytes[30] << 16) | (bytes[31] << 24);
    final dataSize = bytes.length - 44;
    final durationSeconds =
        byteRate > 0 ? (dataSize / byteRate).round() : 5;
    return ExtractedMetadata(
      title: fallbackTitle,
      artist: 'WAV Artist',
      album: 'WAV Album',
      duration: Duration(seconds: durationSeconds.clamp(1, 3600)),
      bitrate: (byteRate * 8) ~/ 1000,
    );
  }

  ExtractedMetadata _parseFlac(Uint8List bytes, String fallbackTitle) {
    final sampleRate =
        (bytes[18] << 12) | (bytes[19] << 4) | ((bytes[20] & 0xF0) >> 4);
    final totalSamples = ((bytes[21] & 0x0F) << 32) |
        (bytes[22] << 24) |
        (bytes[23] << 16) |
        (bytes[24] << 8) |
        bytes[25];
    final durationSeconds =
        sampleRate > 0 ? (totalSamples / sampleRate).round() : 10;

    return ExtractedMetadata(
      title: fallbackTitle,
      artist: 'FLAC Artist',
      album: 'FLAC Album',
      duration: Duration(seconds: durationSeconds.clamp(1, 7200)),
      bitrate: 1411,
    );
  }
}
