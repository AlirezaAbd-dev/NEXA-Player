import 'package:path/path.dart' as p;

import '../../shared/models/track.dart';

/// Deterministic, null-safe formatter for audio quality badges and studio telemetry.
///
/// Enforces the Task #5 invariant: `"0 KBPS"` is NEVER rendered in the UI.
/// Normalizes both raw bps (`320000`) and kbps (`320`), computes average kbps from
/// `fileSize` + `duration` when container tags omit bitrate (API 29 / VBR / FLAC),
/// and renders tabular codec / sample-rate / bit-depth details cleanly.
abstract final class AudioQualityFormatter {
  AudioQualityFormatter._();

  /// Normalizes an input [bitrate] (`bps` if `> 10000`, `kbps` if `1..10000`) to `kbps`.
  /// Returns `null` if [bitrate] is null or `<= 0`.
  static int? normalizeKbps(int? bitrate) {
    if (bitrate == null || bitrate <= 0) return null;
    if (bitrate > 10000) {
      final kbps = (bitrate / 1000.0).round();
      return kbps > 0 ? kbps : null;
    }
    return bitrate;
  }

  /// Resolves effective bitrate in `kbps` from explicit [bitrate] first, falling back
  /// mathematically to `((fileSize * 8) / (durationMs / 1000.0) / 1000.0).round()`.
  /// Never returns `<= 0`.
  static int? resolveEffectiveKbps({
    int? bitrate,
    int? fileSize,
    Duration? duration,
  }) {
    final normalized = normalizeKbps(bitrate);
    if (normalized != null) return normalized;

    if (fileSize != null &&
        fileSize > 0 &&
        duration != null &&
        duration.inMilliseconds > 0) {
      final seconds = duration.inMilliseconds / 1000.0;
      final computed = ((fileSize * 8.0) / seconds / 1000.0).round();
      if (computed > 0) return computed;
    }
    return null;
  }

  /// Resolves track kbps directly from [track.bitrate], [track.fileSize], and [track.duration].
  static int? resolveTrackKbps(Track? track) {
    if (track == null) return null;
    return resolveEffectiveKbps(
      bitrate: track.bitrate,
      fileSize: track.fileSize,
      duration: track.duration,
    );
  }

  /// Infers normalized uppercase codec label (e.g. `'FLAC'`, `'MP3'`, `'AAC'`, `'OPUS'`, `'WAV'`).
  static String? inferCodec(Track? track) {
    if (track == null) return null;
    if (track.codec != null && track.codec!.trim().isNotEmpty) {
      return _normalizeCodecName(track.codec!);
    }
    final path = track.filePath;
    if (path == null || path.isEmpty) return null;
    final ext = p.extension(path).toLowerCase().replaceFirst('.', '');
    if (ext.isEmpty) return null;
    return _normalizeCodecName(ext);
  }

  static String _normalizeCodecName(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.contains('flac')) return 'FLAC';
    if (lower.contains('mpeg') || lower == 'mp3') return 'MP3';
    if (lower.contains('mp4a') || lower == 'm4a' || lower == 'aac') {
      return 'AAC';
    }
    if (lower.contains('opus')) return 'OPUS';
    if (lower.contains('vorbis') || lower == 'ogg') return 'OGG';
    if (lower.contains('raw') || lower == 'wav') return 'WAV';
    if (lower.contains('alac')) return 'ALAC';
    if (lower.contains('wma')) return 'WMA';
    return lower.toUpperCase();
  }

  /// Formats integer kbps with thousands comma separators (`2840` -> `'2,840'`).
  static String formatNumberWithCommas(int value) {
    final s = value.toString();
    if (s.length <= 3) return s;
    final buf = StringBuffer();
    final mod = s.length % 3;
    if (mod > 0) buf.write(s.substring(0, mod));
    for (var i = mod; i < s.length; i += 3) {
      if (buf.isNotEmpty) buf.write(',');
      buf.write(s.substring(i, i + 3));
    }
    return buf.toString();
  }

  /// Formats sample rate Hz cleanly (`44100` -> `'44.1 kHz'`, `96000` -> `'96 kHz'`).
  static String formatSampleRate(int sampleRateHz) {
    if (sampleRateHz <= 0) return '44.1 kHz';
    final khz = sampleRateHz / 1000.0;
    if ((khz - khz.roundToDouble()).abs() < 0.05) {
      return '${khz.round()} kHz';
    }
    return '${khz.toStringAsFixed(1)} kHz';
  }

  static String formatChannels(int? channels) {
    if (channels == 1) return 'MONO';
    if (channels != null && channels > 2) return '$channels CH';
    return 'STEREO';
  }

  /// Formats compact Now Playing telemetry pill text. Never produces `"0 KBPS"`.
  /// Examples:
  /// - `Track(bitrate: 320000)` -> `'320 KBPS • STEREO'`
  /// - `Track(codec: 'FLAC', sampleRate: 96000, bitDepth: 24, bitrate: 2840)` -> `'FLAC · 96 kHz / 24-bit · 2,840 KBPS'`
  /// - `Track(bitrate: 0, filePath: 'song.flac')` (no size/duration) -> `'FLAC • STEREO'`
  static String formatNowPlayingBadge(Track? track) {
    if (track == null) return 'AUDIO • STEREO';
    final kbps = resolveTrackKbps(track);
    final codec = inferCodec(track);
    final channels = formatChannels(track.channels);

    if (track.sampleRate != null &&
        track.sampleRate! > 0 &&
        codec != null &&
        kbps != null) {
      final sr = formatSampleRate(track.sampleRate!);
      final depth = track.bitDepth != null && track.bitDepth! > 0
          ? ' / ${track.bitDepth}-bit'
          : '';
      return '$codec · $sr$depth · ${formatNumberWithCommas(kbps)} KBPS';
    }

    if (kbps != null) {
      final kbpsLabel = '${formatNumberWithCommas(kbps)} KBPS';
      if (track.codec != null && track.codec!.isNotEmpty && codec != null) {
        return '$codec · $kbpsLabel • $channels';
      }
      return '$kbpsLabel • $channels';
    }

    if (codec != null) {
      return '$codec • $channels';
    }
    return channels;
  }

  /// Formats the Format / Bitrate row inside the flipped 3D Signal Chain card.
  static String formatSignalChainFormat(Track? track) {
    if (track == null) return 'Audio Stream';
    final kbps = resolveTrackKbps(track);
    final explicitCodec =
        track.codec != null && track.codec!.isNotEmpty ? inferCodec(track) : null;
    if (kbps != null && explicitCodec != null) {
      return '$explicitCodec · ${formatNumberWithCommas(kbps)} kbps';
    }
    if (kbps != null) {
      return '${formatNumberWithCommas(kbps)} kbps';
    }
    return inferCodec(track) ?? 'Lossy Audio';
  }

  /// Formats the Sample Precision row inside the flipped 3D Signal Chain card.
  static String formatSamplePrecision(Track? track) {
    final sr = track?.sampleRate;
    final depth = track?.bitDepth;
    if (sr != null && sr > 0 && depth != null && depth > 0) {
      return '${formatSampleRate(sr)} / $depth-bit';
    }
    if (sr != null && sr > 0) {
      return formatSampleRate(sr);
    }
    if (depth != null && depth > 0) {
      return '44.1 kHz / $depth-bit';
    }
    final codec = inferCodec(track);
    if (codec == 'FLAC' || codec == 'WAV' || codec == 'ALAC') {
      return '44.1 kHz / 16-bit Lossless';
    }
    return '44.1 kHz / 16-bit';
  }
}
