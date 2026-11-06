import 'dart:ui';
import '../constants/app_constants.dart';

/// Extension on [String] providing utility methods for text formatting,
/// audio file identification, and hex color parsing.
extension StringX on String {
  /// Capitalizes the first letter of the string.
  /// Example: `'rock'.capitalize` -> `'Rock'`.
  String get capitalize {
    if (isEmpty) return this;
    if (length == 1) return toUpperCase();
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Converts string to Title Case (capitalizing every word).
  /// Example: `'dark side of the moon'.toTitleCase` -> `'Dark Side Of The Moon'`.
  String get toTitleCase {
    if (isEmpty) return this;
    return split(' ')
        .map((word) => word.isEmpty ? word : word.capitalize)
        .join(' ');
  }

  /// Extracts the file extension without the leading dot.
  /// Example: `'/music/track.flac'.fileExtension` -> `'flac'`.
  String get fileExtension {
    final dotIndex = lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == length - 1) return '';
    return substring(dotIndex + 1).toLowerCase();
  }

  /// Extracts the file name without extension from a path.
  /// Example: `'/music/track.flac'.fileNameWithoutExtension` -> `'track'`.
  String get fileNameWithoutExtension {
    final slashIndex = lastIndexOf('/');
    final backslashIndex = lastIndexOf(r'\');
    final lastSeparator = slashIndex > backslashIndex ? slashIndex : backslashIndex;
    final fileName = lastSeparator == -1 ? this : substring(lastSeparator + 1);

    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0) return fileName;
    return fileName.substring(0, dotIndex);
  }

  /// Checks if the file path has a supported audio extension.
  bool get isValidAudioExtension {
    return AppConstants.supportedAudioExtensions.contains(fileExtension);
  }

  /// Returns [fallback] if the string is empty or contains only whitespace.
  String ifBlank(String fallback) {
    return trim().isEmpty ? fallback : this;
  }

  /// Truncates string to [maxLength] characters, appending an ellipsis if truncated.
  String truncateWithEllipsis(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    if (maxLength <= ellipsis.length) {
      return substring(0, maxLength);
    }
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Shorthand alias for [truncateWithEllipsis].
  String truncate(int maxLength, {String ellipsis = '...'}) =>
      truncateWithEllipsis(maxLength, ellipsis: ellipsis);

  /// Parses a hex color string into a Flutter [Color].
  ///
  /// Accepts formats: `#RRGGBB`, `RRGGBB`, `#AARRGGBB`, `AARRGGBB`.
  /// Returns `null` if the string cannot be parsed.
  Color? toColorOrNull() {
    var hex = replaceAll('#', '').trim();
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    if (hex.length != 8) return null;
    final intValue = int.tryParse(hex, radix: 16);
    if (intValue == null) return null;
    return Color(intValue);
  }
}

/// Extension on nullable [String] providing null/empty convenience checks.
extension NullableStringX on String? {
  /// Returns `true` if this string is `null` or empty.
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Returns `true` if this string is not `null` and not empty.
  bool get isNotNullOrEmpty => this != null && this!.isNotEmpty;
}
