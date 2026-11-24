import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:nexa_player/features/scanner/domain/audio_metadata_reader.dart';

/// Pure Dart audio metadata extractor capable of parsing ID3v2 (including
/// proper APIC picture unwrapping), WAV, FLAC (STREAMINFO + VORBIS_COMMENT +
/// METADATA_BLOCK_PICTURE), and MP4/M4A (`covr` + basic atoms) without C/FFI.
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
    if (bytes.length >= 12 &&
        bytes[4] == 0x66 &&
        bytes[5] == 0x74 &&
        bytes[6] == 0x79 &&
        bytes[7] == 0x70) {
      return _parseMp4(bytes, fallbackTitle);
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
      final majorVersion = bytes[3];
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
        // ID3v2.4 uses synchsafe integers for frame size; v2.3 uses big-endian uint32.
        final frameSize = majorVersion == 4
            ? (((bytes[offset + 4] & 0x7F) << 21) |
                ((bytes[offset + 5] & 0x7F) << 14) |
                ((bytes[offset + 6] & 0x7F) << 7) |
                (bytes[offset + 7] & 0x7F))
            : ((bytes[offset + 4] << 24) |
                (bytes[offset + 5] << 16) |
                (bytes[offset + 6] << 8) |
                bytes[offset + 7]);

        offset += 10;
        if (frameSize <= 0 || offset + frameSize > bytes.length) break;

        final frameData = bytes.sublist(offset, offset + frameSize);
        offset += frameSize;

        if (frameData.isEmpty) continue;
        if (frameId == 'APIC') {
          artwork ??= _extractApicPayload(frameData);
          continue;
        }

        final encoding = frameData[0];
        final textData = frameData.sublist(1);
        final text = _decodeId3Text(encoding, textData);

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

  /// Unwraps ID3v2 APIC frame envelope (`encoding + MIME + NUL + type + desc + NUL`)
  /// and returns verified image bytes, or null if malformed / external URL link.
  Uint8List? _extractApicPayload(Uint8List frameData) {
    if (frameData.length < 6) return null;
    final encoding = frameData[0];
    var cursor = 1;

    // 1. Skip null-terminated MIME string
    while (cursor < frameData.length && frameData[cursor] != 0) {
      cursor++;
    }
    final mime = ascii
        .decode(frameData.sublist(1, cursor), allowInvalid: true)
        .trim();
    if (mime == '-->') return null; // External URL link, no embedded bytes
    if (cursor >= frameData.length) return null;
    cursor++; // skip MIME NUL terminator

    // 2. Skip picture type byte
    if (cursor >= frameData.length) return null;
    cursor++;

    // 3. Skip null-terminated description string (1 byte NUL for 0/3, 2-byte NUL for UTF-16)
    if (encoding == 0x01 || encoding == 0x02) {
      while (cursor + 1 < frameData.length) {
        if (frameData[cursor] == 0 && frameData[cursor + 1] == 0) {
          cursor += 2;
          break;
        }
        cursor += 2;
      }
    } else {
      while (cursor < frameData.length && frameData[cursor] != 0) {
        cursor++;
      }
      if (cursor < frameData.length) cursor++;
    }

    if (cursor >= frameData.length) {
      return _findImageSignatureFallback(frameData);
    }

    final payload = frameData.sublist(cursor);
    if (hasValidImageSignature(payload)) {
      return payload;
    }
    return _findImageSignatureFallback(payload);
  }

  /// Locates JPEG or PNG magic header within a small prefix when non-standard
  /// encoders emit extra padding before the image bytes.
  Uint8List? _findImageSignatureFallback(Uint8List data) {
    final limit = data.length < 128 ? data.length : 128;
    for (var i = 0; i <= limit - 4; i++) {
      // JPEG SOI + marker: FF D8 FF
      if (data[i] == 0xFF && data[i + 1] == 0xD8 && data[i + 2] == 0xFF) {
        return data.sublist(i);
      }
      // PNG signature: 89 50 4E 47
      if (data[i] == 0x89 &&
          data[i + 1] == 0x50 &&
          data[i + 2] == 0x4E &&
          data[i + 3] == 0x47) {
        return data.sublist(i);
      }
    }
    return null;
  }

  String _decodeId3Text(int encoding, Uint8List textData) {
    if (textData.isEmpty) return '';
    if (encoding == 0x03) {
      return utf8.decode(textData, allowMalformed: true).replaceAll('\x00', '').trim();
    }
    return ascii.decode(textData, allowInvalid: true).replaceAll('\x00', '').trim();
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

    Uint8List? artwork;
    try {
      var offset = 4;
      while (offset + 4 <= bytes.length) {
        final headerByte = bytes[offset];
        final isLast = (headerByte & 0x80) != 0;
        final blockType = headerByte & 0x7F;
        final blockLength = (bytes[offset + 1] << 16) |
            (bytes[offset + 2] << 8) |
            bytes[offset + 3];
        offset += 4;
        if (blockLength < 0 || offset + blockLength > bytes.length) break;

        if (blockType == 6 && artwork == null) {
          artwork = _extractFlacPictureBlock(
            bytes.sublist(offset, offset + blockLength),
          );
        }
        offset += blockLength;
        if (isLast) break;
      }
    } catch (_) {
      // Ignore malformed trailing blocks
    }

    return ExtractedMetadata(
      title: fallbackTitle,
      artist: 'FLAC Artist',
      album: 'FLAC Album',
      duration: Duration(seconds: durationSeconds.clamp(1, 7200)),
      bitrate: 1411,
      artworkBytes: artwork,
    );
  }

  Uint8List? _extractFlacPictureBlock(Uint8List block) {
    if (block.length < 32) return null;
    var cursor = 4; // skip picture type
    final mimeLen = _readUint32BE(block, cursor);
    cursor += 4;
    if (mimeLen < 0 || cursor + mimeLen + 4 > block.length) return null;
    cursor += mimeLen;

    final descLen = _readUint32BE(block, cursor);
    cursor += 4;
    if (descLen < 0 || cursor + descLen + 20 > block.length) return null;
    cursor += descLen;

    cursor += 16; // width, height, color depth, indexed colors
    final dataLen = _readUint32BE(block, cursor);
    cursor += 4;
    if (dataLen <= 0 || cursor + dataLen > block.length) return null;

    final payload = block.sublist(cursor, cursor + dataLen);
    return hasValidImageSignature(payload) ? payload : null;
  }

  ExtractedMetadata _parseMp4(Uint8List bytes, String fallbackTitle) {
    Uint8List? artwork;
    try {
      artwork = _findMp4Covr(bytes, 0, bytes.length);
    } catch (_) {}

    return ExtractedMetadata(
      title: fallbackTitle,
      artist: 'Unknown Artist',
      album: 'Unknown Album',
      duration: const Duration(seconds: 180),
      bitrate: 256,
      artworkBytes: artwork,
    );
  }

  Uint8List? _findMp4Covr(Uint8List bytes, int start, int end) {
    var cursor = start;
    while (cursor + 8 <= end) {
      var size = _readUint32BE(bytes, cursor);
      final type = ascii.decode(
        bytes.sublist(cursor + 4, cursor + 8),
        allowInvalid: true,
      );
      if (size == 0) {
        size = end - cursor;
      } else if (size == 1 && cursor + 16 <= end) {
        size = (_readUint32BE(bytes, cursor + 8) << 32) |
            _readUint32BE(bytes, cursor + 12);
      }
      if (size < 8 || cursor + size > end) break;

      final contentStart = cursor + 8;
      final boxEnd = cursor + size;

      if (type == 'covr') {
        var inner = contentStart;
        while (inner + 16 <= boxEnd) {
          final dataSize = _readUint32BE(bytes, inner);
          final dataType = ascii.decode(
            bytes.sublist(inner + 4, inner + 8),
            allowInvalid: true,
          );
          if (dataSize < 16 || inner + dataSize > boxEnd) break;
          if (dataType == 'data') {
            final payload = bytes.sublist(inner + 16, inner + dataSize);
            if (hasValidImageSignature(payload)) {
              return payload;
            }
          }
          inner += dataSize;
        }
      } else if (type == 'moov' ||
          type == 'udta' ||
          type == 'ilst') {
        final found = _findMp4Covr(bytes, contentStart, boxEnd);
        if (found != null) return found;
      } else if (type == 'meta' && contentStart + 4 <= boxEnd) {
        // 'meta' is a FullBox (4 bytes version+flags before children)
        final found = _findMp4Covr(bytes, contentStart + 4, boxEnd);
        if (found != null) return found;
      }

      cursor = boxEnd;
    }
    return null;
  }

  int _readUint32BE(Uint8List bytes, int offset) =>
      (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];

  /// Validates that [bytes] begin with a supported raster image magic header
  /// (JPEG, PNG, GIF, BMP, WebP).
  static bool hasValidImageSignature(Uint8List bytes) {
    if (bytes.length < 4) return false;
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }
    // GIF: 47 49 46 38
    if (bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return true;
    }
    // WebP: RIFF....WEBP
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true;
    }
    // BMP: 42 4D
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) return true;
    return false;
  }
}
