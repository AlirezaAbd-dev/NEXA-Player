import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:nexa_player/features/playlists/domain/models/editable_track_metadata.dart';
import 'package:path/path.dart' as p;

/// Result status from attempting to embed metadata back into an audio file.
enum Id3WriteStatus {
  written,
  skippedUnsupportedFormat,
  fileMissing,
  readOnlyOrPermissionDenied,
}

class Id3WriteResult {
  const Id3WriteResult({
    required this.status,
    this.errorMessage,
  });

  final Id3WriteStatus status;
  final String? errorMessage;

  bool get isSuccess => status == Id3WriteStatus.written;
}

/// Pure-Dart atomic UTF-8 ID3v2.4 tag writer for MP3 audio files.
///
/// Writes `TIT2`, `TPE1`, `TALB`, `TCON`, `TDRC`, `TRCK`, `COMM`, and `APIC`
/// frames with UTF-8 (`0x03`) encoding so Persian/Arabic/UTF-8 text is preserved.
/// Preserves existing embedded `APIC` artwork unless overridden or cleared.
/// Never throws or corrupts the audio payload when filesystem access is read-only.
class Id3TagWriter {
  const Id3TagWriter();

  Future<Id3WriteResult> writeTags(
    String filePath,
    EditableTrackMetadata metadata,
  ) async {
    final ext = p.extension(filePath).toLowerCase();
    if (ext != '.mp3') {
      return const Id3WriteResult(
        status: Id3WriteStatus.skippedUnsupportedFormat,
      );
    }

    final file = File(filePath);
    if (!await file.exists()) {
      return const Id3WriteResult(status: Id3WriteStatus.fileMissing);
    }

    try {
      final originalBytes = await file.readAsBytes();
      final parsed = _extractAudioPayloadAndExistingApic(originalBytes);

      final frames = <Uint8List>[
        _buildTextFrame('TIT2', metadata.title),
        _buildTextFrame('TPE1', metadata.artist),
        _buildTextFrame(
          'TALB',
          metadata.album.trim().isEmpty ? 'Unknown Album' : metadata.album,
        ),
        if (metadata.genre != null && metadata.genre!.trim().isNotEmpty)
          _buildTextFrame('TCON', metadata.genre!.trim()),
        if (metadata.year != null)
          _buildTextFrame('TDRC', metadata.year.toString()),
        if (metadata.trackNumber != null)
          _buildTextFrame('TRCK', metadata.trackNumber.toString()),
        if (metadata.comment != null && metadata.comment!.trim().isNotEmpty)
          _buildCommentFrame(metadata.comment!.trim()),
      ];

      if (!metadata.clearArtwork) {
        if (metadata.artworkBytes != null && metadata.artworkBytes!.isNotEmpty) {
          frames.add(_buildApicFrame(metadata.artworkBytes!));
        } else if (parsed.existingApicFrame != null) {
          frames.add(parsed.existingApicFrame!);
        }
      }

      final framesSize =
          frames.fold<int>(0, (sum, frame) => sum + frame.length);
      final tagBuilder = BytesBuilder(copy: false);
      // ID3v2.4 header (10 bytes): "ID3", v2.4.0, flags=0, synchsafe size
      tagBuilder.add(const [0x49, 0x44, 0x33, 0x04, 0x00, 0x00]);
      tagBuilder.add(_encodeSynchsafe(framesSize));
      for (final frame in frames) {
        tagBuilder.add(frame);
      }

      final tmpFile = File('$filePath.nexatag.tmp');
      final sink = tmpFile.openWrite();
      try {
        sink.add(tagBuilder.takeBytes());
        sink.add(parsed.audioPayload);
        await sink.flush();
      } finally {
        await sink.close();
      }

      await tmpFile.rename(filePath);
      return const Id3WriteResult(status: Id3WriteStatus.written);
    } on FileSystemException catch (e) {
      await _cleanupTemp(filePath);
      return Id3WriteResult(
        status: Id3WriteStatus.readOnlyOrPermissionDenied,
        errorMessage: e.message,
      );
    } catch (e) {
      await _cleanupTemp(filePath);
      return Id3WriteResult(
        status: Id3WriteStatus.readOnlyOrPermissionDenied,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _cleanupTemp(String filePath) async {
    try {
      final tmp = File('$filePath.nexatag.tmp');
      if (await tmp.exists()) {
        await tmp.delete();
      }
    } catch (_) {}
  }

  _ParsedId3Parts _extractAudioPayloadAndExistingApic(Uint8List bytes) {
    if (bytes.length < 10 ||
        bytes[0] != 0x49 ||
        bytes[1] != 0x44 ||
        bytes[2] != 0x33) {
      return _ParsedId3Parts(audioPayload: bytes);
    }

    final majorVersion = bytes[3];
    final flags = bytes[5];
    final tagBodySize = _decodeSynchsafe(bytes, 6);
    final hasFooter = majorVersion == 4 && (flags & 0x10) != 0;
    final totalHeaderBytes =
        (10 + tagBodySize + (hasFooter ? 10 : 0)).clamp(10, bytes.length);

    Uint8List? existingApic;
    if (majorVersion == 3 || majorVersion == 4) {
      existingApic = _findFirstApicFrame(
        bytes,
        start: 10,
        end: (10 + tagBodySize).clamp(10, bytes.length),
        isV24: majorVersion == 4,
      );
    }

    return _ParsedId3Parts(
      audioPayload: Uint8List.sublistView(bytes, totalHeaderBytes),
      existingApicFrame: existingApic,
    );
  }

  Uint8List? _findFirstApicFrame(
    Uint8List bytes, {
    required int start,
    required int end,
    required bool isV24,
  }) {
    var offset = start;
    // Skip extended header if present (bit 0x40 of tag flags)
    if ((bytes[5] & 0x40) != 0 && offset + 4 <= end) {
      final extSize = isV24 ? _decodeSynchsafe(bytes, offset) : _readUint32(bytes, offset);
      offset += isV24 ? extSize : (extSize + 4);
    }

    while (offset + 10 <= end) {
      if (bytes[offset] == 0) break; // Padding
      final frameId = ascii.decode(
        bytes.sublist(offset, offset + 4),
        allowInvalid: true,
      );
      final frameSize = isV24
          ? _decodeSynchsafe(bytes, offset + 4)
          : _readUint32(bytes, offset + 4);
      if (frameSize <= 0 || offset + 10 + frameSize > end) break;

      if (frameId == 'APIC') {
        final payload = Uint8List.sublistView(
          bytes,
          offset + 10,
          offset + 10 + frameSize,
        );
        // Re-encode with ID3v2.4 synchsafe frame size header
        return _wrapFrame('APIC', payload);
      }
      offset += 10 + frameSize;
    }
    return null;
  }

  Uint8List _buildTextFrame(String frameId, String value) {
    final textBytes = utf8.encode(value);
    final payload = Uint8List(1 + textBytes.length)
      ..[0] = 0x03 // UTF-8
      ..setRange(1, 1 + textBytes.length, textBytes);
    return _wrapFrame(frameId, payload);
  }

  Uint8List _buildCommentFrame(String comment) {
    final textBytes = utf8.encode(comment);
    final payload = BytesBuilder(copy: false)
      ..addByte(0x03) // UTF-8
      ..add(const [0x65, 0x6E, 0x67]) // "eng"
      ..addByte(0x00) // empty short description null-terminator
      ..add(textBytes);
    return _wrapFrame('COMM', payload.takeBytes());
  }

  Uint8List _buildApicFrame(Uint8List imageBytes) {
    final mime = _detectMimeType(imageBytes);
    final mimeBytes = ascii.encode(mime);
    final payload = BytesBuilder(copy: false)
      ..addByte(0x00) // ISO-8859-1 for MIME & empty description
      ..add(mimeBytes)
      ..addByte(0x00)
      ..addByte(0x03) // Picture type 0x03: Cover (front)
      ..addByte(0x00) // Empty description terminator
      ..add(imageBytes);
    return _wrapFrame('APIC', payload.takeBytes());
  }

  String _detectMimeType(Uint8List bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  Uint8List _wrapFrame(String frameId, Uint8List payload) {
    final idBytes = ascii.encode(frameId);
    final sizeBytes = _encodeSynchsafe(payload.length);
    return (BytesBuilder(copy: false)
          ..add(idBytes)
          ..add(sizeBytes)
          ..add(const [0x00, 0x00])
          ..add(payload))
        .takeBytes();
  }

  List<int> _encodeSynchsafe(int value) => [
        (value >> 21) & 0x7F,
        (value >> 14) & 0x7F,
        (value >> 7) & 0x7F,
        value & 0x7F,
      ];

  int _decodeSynchsafe(Uint8List bytes, int offset) =>
      ((bytes[offset] & 0x7F) << 21) |
      ((bytes[offset + 1] & 0x7F) << 14) |
      ((bytes[offset + 2] & 0x7F) << 7) |
      (bytes[offset + 3] & 0x7F);

  int _readUint32(Uint8List bytes, int offset) =>
      (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}

class _ParsedId3Parts {
  const _ParsedId3Parts({
    required this.audioPayload,
    this.existingApicFrame,
  });

  final Uint8List audioPayload;
  final Uint8List? existingApicFrame;
}
