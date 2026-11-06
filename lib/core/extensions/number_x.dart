import 'dart:math' as math;
import 'package:flutter/widgets.dart';

/// Extension on [num] providing audio metadata formatting and layout spacing.
///
/// NOTE: Does NOT define `.ms` or `.seconds` to prevent conflict with `flutter_animate`.
extension NumberX on num {
  /// Converts a byte size into a human-readable string (e.g. `10.5 MB`, `850 KB`).
  String toFileSize({int decimals = 1}) {
    if (this <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (math.log(this) / math.log(1024)).floor();
    final clampedIndex = i.clamp(0, suffixes.length - 1);
    final size = this / math.pow(1024, clampedIndex);
    return '${size.toStringAsFixed(clampedIndex == 0 ? 0 : decimals)} ${suffixes[clampedIndex]}';
  }

  /// Converts a bitrate integer/number into a human-readable string (e.g. `320 kbps`).
  /// Handles both raw bits per second (`320000`) and kilobits per second (`320`).
  String toBitrateString() {
    if (this <= 0) return '0 kbps';
    final kbps = this > 10000 ? (this / 1000).round() : round();
    return '$kbps kbps';
  }

  /// Converts a sample rate in Hz or kHz into a string (e.g. `44.1 kHz`, `96.0 kHz`).
  String toSampleRateString({int decimals = 1}) {
    if (this <= 0) return '0 kHz';
    final khz = this > 1000 ? this / 1000.0 : toDouble();
    return '${khz.toStringAsFixed(decimals)} kHz';
  }

  /// Formats an item count with singular or plural noun.
  /// Example: `1.formatCount('track')` -> `'1 track'`, `5.formatCount('track')` -> `'5 tracks'`.
  String formatCount(String singular, [String? plural]) {
    final p = plural ?? '${singular}s';
    return this == 1 ? '$this $singular' : '$this $p';
  }

  /// Formats large numbers compactly (e.g., `1500` -> `'1.5K'`, `1200000` -> `'1.2M'`).
  String toCompact({int decimals = 1}) {
    if (abs() < 1000) return toString();
    if (abs() < 1000000) {
      final value = this / 1000.0;
      return '${value.toStringAsFixed(decimals)}K';
    }
    if (abs() < 1000000000) {
      final value = this / 1000000.0;
      return '${value.toStringAsFixed(decimals)}M';
    }
    final value = this / 1000000000.0;
    return '${value.toStringAsFixed(decimals)}B';
  }

  /// Converts a normalized float [0.0, 1.0] to a percentage string (e.g. `0.75` -> `'75%'`).
  String toPercentageString({int decimals = 0}) {
    final percent = (this * 100.0).clamp(0.0, 100.0);
    return '${percent.toStringAsFixed(decimals)}%';
  }

  /// Clamps a number to a progress fraction between `0.0` and `1.0`.
  double get toProgressFraction => (toDouble() / 100.0).clamp(0.0, 1.0);

  /// Vertical spacing widget.
  Widget get verticalSpace => SizedBox(height: toDouble());

  /// Horizontal spacing widget.
  Widget get horizontalSpace => SizedBox(width: toDouble());
}
