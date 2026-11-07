import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Pure Dart programmatic synthetic audio and media library generator.
/// Enables 100% hermetic scanner, parser, and database E2E testing without external dependencies.
class SyntheticAudioGenerator {
  /// Generates a valid binary MP3 file buffer with ID3v2.3 metadata header and MPEG audio frames.
  static Uint8List createMp3Bytes({
    String title = 'Synthetic Track',
    String artist = 'Synthetic Artist',
    String album = 'Synthetic Album',
    String genre = 'Electronic',
    int year = 2026,
    int trackNumber = 1,
    Duration duration = const Duration(seconds: 180),
    int bitrateKbps = 320,
    Uint8List? artworkBytes,
  }) {
    final builder = BytesBuilder();

    // 1. Build ID3v2 Frames
    final framesBuilder = BytesBuilder();

    // Helper to write text frame (TIT2, TPE1, TALB, etc.)
    void writeTextFrame(String frameId, String text) {
      final textBytes = utf8.encode(text);
      framesBuilder.add(ascii.encode(frameId)); // 4 bytes ID
      final frameSize = 1 + textBytes.length; // 1 byte encoding + text
      framesBuilder.add(_int32BigEndian(frameSize));
      framesBuilder.add(const [0x00, 0x00]); // 2 bytes flags
      framesBuilder.addByte(0x03); // UTF-8 encoding flag in ID3v2
      framesBuilder.add(textBytes);
    }

    writeTextFrame('TIT2', title);
    writeTextFrame('TPE1', artist);
    writeTextFrame('TALB', album);
    writeTextFrame('TCON', genre);
    writeTextFrame('TYER', year.toString());
    writeTextFrame('TRCK', '$trackNumber');
    writeTextFrame('TLEN', '${duration.inMilliseconds}');

    // Embedded artwork (APIC frame)
    if (artworkBytes != null && artworkBytes.isNotEmpty) {
      framesBuilder.add(ascii.encode('APIC'));
      final mime = ascii.encode('image/jpeg');
      // encoding(1) + mime(mime.length + 1 null) + picType(1) + desc(1 null) + artworkBytes
      final apicPayloadSize = 1 + mime.length + 1 + 1 + 1 + artworkBytes.length;
      framesBuilder.add(_int32BigEndian(apicPayloadSize));
      framesBuilder.add(const [0x00, 0x00]); // flags
      framesBuilder.addByte(0x00); // ISO-8859-1
      framesBuilder.add(mime);
      framesBuilder.addByte(0x00); // null terminator for mime
      framesBuilder.addByte(0x03); // Cover front
      framesBuilder.addByte(0x00); // empty description
      framesBuilder.add(artworkBytes);
    }

    final frameData = framesBuilder.toBytes();

    // ID3v2 Header (10 bytes)
    builder.add(ascii.encode('ID3')); // "ID3"
    builder.add(const [0x03, 0x00]); // Version 2.3.0
    builder.addByte(0x00); // Flags
    builder.add(_encodeSyncSafeInt(frameData.length)); // 4 syncsafe bytes
    builder.add(frameData);

    // 2. Synthesize MPEG-1 Audio Layer III frames
    // Frame header: 0xFF, 0xFB (MPEG-1 Layer 3, no CRC), 0x90 (128kbps, 44.1kHz), 0x64 (Stereo)
    final frameCount = (duration.inMilliseconds / 26.122).ceil().clamp(1, 100);
    final dummyFrameData = Uint8List(414); // Standard 128kbps 44.1kHz frame length - 4
    for (var i = 0; i < frameCount; i++) {
      builder.add(const [0xFF, 0xFB, 0x90, 0x64]);
      builder.add(dummyFrameData);
    }

    return builder.toBytes();
  }

  /// Generates a valid binary WAV (RIFF/WAVE PCM) audio buffer.
  static Uint8List createWavBytes({
    Duration duration = const Duration(seconds: 15),
    int sampleRate = 8000,
    int channels = 1,
    int bitsPerSample = 8,
  }) {
    final byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
    final blockAlign = channels * (bitsPerSample ~/ 8);
    final dataSize = (duration.inSeconds * byteRate).clamp(2048, 500000);
    final totalFileSize = 36 + dataSize;

    final builder = BytesBuilder();
    // RIFF chunk descriptor
    builder.add(ascii.encode('RIFF'));
    builder.add(_int32LittleEndian(totalFileSize));
    builder.add(ascii.encode('WAVE'));

    // fmt subchunk
    builder.add(ascii.encode('fmt '));
    builder.add(_int32LittleEndian(16)); // Subchunk1Size for PCM
    builder.add(_int16LittleEndian(1)); // AudioFormat 1 = PCM
    builder.add(_int16LittleEndian(channels));
    builder.add(_int32LittleEndian(sampleRate));
    builder.add(_int32LittleEndian(byteRate));
    builder.add(_int16LittleEndian(blockAlign));
    builder.add(_int16LittleEndian(bitsPerSample));

    // data subchunk
    builder.add(ascii.encode('data'));
    builder.add(_int32LittleEndian(dataSize));
    builder.add(Uint8List(dataSize)); // zero audio samples

    return builder.toBytes();
  }

  /// Generates a valid binary FLAC header and streaminfo block.
  static Uint8List createFlacBytes({
    Duration duration = const Duration(seconds: 15),
    int sampleRate = 44100,
    int channels = 2,
    int bitsPerSample = 16,
  }) {
    final builder = BytesBuilder();
    // fLaC magic bytes
    builder.add(ascii.encode('fLaC'));

    // STREAMINFO metadata block (last metadata block flag 0x80 | block type 0 = 0x80)
    builder.addByte(0x80); // Last block, type 0
    builder.add(const [0x00, 0x00, 0x22]); // 34 bytes block length

    // 34 bytes STREAMINFO block
    final streamInfo = Uint8List(34);
    // Min block size: 4096 (2 bytes)
    streamInfo[0] = 0x10;
    streamInfo[1] = 0x00;
    // Max block size: 4096 (2 bytes)
    streamInfo[2] = 0x10;
    streamInfo[3] = 0x00;
    // Sample rate (20 bits), channels - 1 (3 bits), bits per sample - 1 (5 bits)
    // 44100 = 0x0AC44
    streamInfo[10] = 0x0A;
    streamInfo[11] = 0xC4;
    streamInfo[12] = 0x40 | ((channels - 1) << 1) | ((bitsPerSample - 1) >> 4);
    streamInfo[13] = ((bitsPerSample - 1) & 0x0F) << 4;

    // Total samples (36 bits)
    final totalSamples = duration.inSeconds * sampleRate;
    streamInfo[14] = (totalSamples >> 24) & 0xFF;
    streamInfo[15] = (totalSamples >> 16) & 0xFF;
    streamInfo[16] = (totalSamples >> 8) & 0xFF;
    streamInfo[17] = totalSamples & 0xFF;

    builder.add(streamInfo);
    // Audio frame data (> 2KB to exceed minFileSizeBytes)
    builder.add(const [0xFF, 0xF8, 0x00, 0x00]);
    builder.add(Uint8List(2048));

    return builder.toBytes();
  }

  /// Generates synthetic JPEG image bytes for embedded artwork testing.
  static Uint8List createSyntheticJpegBytes({int width = 100, int height = 100}) {
    final builder = BytesBuilder();
    // SOI
    builder.add(const [0xFF, 0xD8]);
    // APP0 marker
    builder.add(const [0xFF, 0xE0, 0x00, 0x10]);
    builder.add(ascii.encode('JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00'));
    // DQT (Quantization table)
    builder.add(const [0xFF, 0xDB, 0x00, 0x43, 0x00]);
    builder.add(Uint8List(64));
    // SOF0 (Baseline DCT)
    builder.add(const [0xFF, 0xC0, 0x00, 0x0B, 0x08]);
    builder.add(_int16BigEndian(height));
    builder.add(_int16BigEndian(width));
    builder.add(const [0x01, 0x01, 0x11, 0x00]); // 1 component
    // SOS & Scan data
    builder.add(const [0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F, 0x00]);
    builder.add(const [0x00, 0x01, 0x02, 0x03]);
    // EOI
    builder.add(const [0xFF, 0xD9]);
    return builder.toBytes();
  }

  /// Generates a corrupt audio file with arbitrary garbage data.
  static Uint8List createCorruptAudioBytes({int size = 128}) {
    final list = Uint8List(size);
    for (var i = 0; i < size; i++) {
      list[i] = (i * 37 + 13) % 256;
    }
    return list;
  }

  // --- Helper Encoders ---

  static List<int> _encodeSyncSafeInt(int value) {
    return [
      (value >> 21) & 0x7F,
      (value >> 14) & 0x7F,
      (value >> 7) & 0x7F,
      value & 0x7F,
    ];
  }

  static List<int> _int32BigEndian(int value) {
    return [
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ];
  }

  static List<int> _int16BigEndian(int value) {
    return [
      (value >> 8) & 0xFF,
      value & 0xFF,
    ];
  }

  static List<int> _int32LittleEndian(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];
  }

  static List<int> _int16LittleEndian(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
    ];
  }
}

/// Hermetic temporary music library builder on disk.
/// Automatically handles directory creation, synthetic media files, .nomedia files,
/// and deterministic cleanup.
class SyntheticLibraryBuilder {
  SyntheticLibraryBuilder({Directory? baseDir})
      : rootDir = baseDir ?? Directory.systemTemp.createTempSync('nexa_e2e_lib_');

  final Directory rootDir;
  final List<File> createdFiles = [];
  final List<Directory> createdDirs = [];

  String get path => rootDir.path;

  /// Creates a synthetic MP3 audio file at the specified relative subpath.
  File addMp3(
    String relativePath, {
    String title = 'Synthetic Track',
    String artist = 'Synthetic Artist',
    String album = 'Synthetic Album',
    String genre = 'Electronic',
    int year = 2026,
    int trackNumber = 1,
    Duration duration = const Duration(minutes: 3, seconds: 30),
    Uint8List? artwork,
  }) {
    final file = _resolveFile(relativePath);
    final bytes = SyntheticAudioGenerator.createMp3Bytes(
      title: title,
      artist: artist,
      album: album,
      genre: genre,
      year: year,
      trackNumber: trackNumber,
      duration: duration,
      artworkBytes: artwork,
    );
    file.writeAsBytesSync(bytes, flush: true);
    createdFiles.add(file);
    return file;
  }

  /// Creates a synthetic WAV audio file.
  File addWav(String relativePath, {Duration duration = const Duration(seconds: 15)}) {
    final file = _resolveFile(relativePath);
    final bytes = SyntheticAudioGenerator.createWavBytes(duration: duration);
    file.writeAsBytesSync(bytes, flush: true);
    createdFiles.add(file);
    return file;
  }

  /// Creates a synthetic FLAC audio file.
  File addFlac(String relativePath, {Duration duration = const Duration(seconds: 45)}) {
    final file = _resolveFile(relativePath);
    final bytes = SyntheticAudioGenerator.createFlacBytes(duration: duration);
    file.writeAsBytesSync(bytes, flush: true);
    createdFiles.add(file);
    return file;
  }

  /// Creates a .nomedia exclusion marker in the specified relative directory.
  File addNoMedia(String relativeDir) {
    final dir = _resolveDir(relativeDir);
    final file = File('${dir.path}/.nomedia');
    file.writeAsStringSync('', flush: true);
    createdFiles.add(file);
    return file;
  }

  /// Creates a corrupt or truncated audio file for negative resilience testing.
  File addCorruptFile(String relativePath, {int size = 64}) {
    final file = _resolveFile(relativePath);
    file.writeAsBytesSync(SyntheticAudioGenerator.createCorruptAudioBytes(size: size), flush: true);
    createdFiles.add(file);
    return file;
  }

  /// Creates a non-audio file (e.g. .jpg, .txt, .pdf, .nfo) that scanner should ignore.
  File addNonAudioFile(String relativePath, [String content = 'Ignored non-audio content']) {
    final file = _resolveFile(relativePath);
    file.writeAsStringSync(content, flush: true);
    createdFiles.add(file);
    return file;
  }

  /// Creates an empty directory.
  Directory addDirectory(String relativeDir) {
    return _resolveDir(relativeDir);
  }

  File _resolveFile(String relativePath) {
    final fullPath = '${rootDir.path}/$relativePath';
    final file = File(fullPath);
    file.parent.createSync(recursive: true);
    return file;
  }

  Directory _resolveDir(String relativeDir) {
    final fullPath = relativeDir.isEmpty ? rootDir.path : '${rootDir.path}/$relativeDir';
    final dir = Directory(fullPath);
    dir.createSync(recursive: true);
    createdDirs.add(dir);
    return dir;
  }

  /// Cleans up all generated files and removes the temporary root directory.
  void dispose() {
    try {
      if (rootDir.existsSync()) {
        rootDir.deleteSync(recursive: true);
      }
    } catch (_) {
      // Ignore cleanup errors on OS temp
    }
  }
}
