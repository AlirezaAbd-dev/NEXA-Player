/// Extension on [Duration] providing audio player formatting methods.
extension DurationX on Duration {
  /// Formats duration as `mm:ss` (e.g. `03:42` or `00:05`).
  ///
  /// If the duration is negative, preserves the leading minus sign (e.g. `-00:05`).
  String toMinutesSeconds({bool padMinutes = true}) {
    final negative = isNegative;
    final absDuration = abs();
    final minutes = absDuration.inMinutes;
    final seconds = absDuration.inSeconds % 60;

    final minutesStr = padMinutes ? minutes.toString().padLeft(2, '0') : minutes.toString();
    final secondsStr = seconds.toString().padLeft(2, '0');
    final formatted = '$minutesStr:$secondsStr';

    return negative ? '-$formatted' : formatted;
  }

  /// Formats duration as `hh:mm:ss` (e.g. `01:23:45`).
  String toHoursMinutesSeconds() {
    final negative = isNegative;
    final absDuration = abs();
    final hours = absDuration.inHours.toString().padLeft(2, '0');
    final minutes = (absDuration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (absDuration.inSeconds % 60).toString().padLeft(2, '0');
    final formatted = '$hours:$minutes:$seconds';

    return negative ? '-$formatted' : formatted;
  }

  /// Formats duration adaptively for audio player scrubbers and track labels.
  ///
  /// Returns `h:mm:ss` if hours > 0, otherwise `mm:ss` (e.g. `03:42`).
  String formatAdaptive({bool padHours = false}) {
    final negative = isNegative;
    final absDuration = abs();
    final hours = absDuration.inHours;
    final minutes = (absDuration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (absDuration.inSeconds % 60).toString().padLeft(2, '0');

    String formatted;
    if (hours > 0) {
      final hoursStr = padHours ? hours.toString().padLeft(2, '0') : hours.toString();
      formatted = '$hoursStr:$minutes:$seconds';
    } else {
      formatted = '$minutes:$seconds';
    }

    return negative ? '-$formatted' : formatted;
  }

  /// Shorthand getter for adaptive audio formatting (`mm:ss` or `h:mm:ss`).
  String get formatted => formatAdaptive();

  /// Shorthand getter for strict `mm:ss` format.
  String get mmSs => toMinutesSeconds();

  /// Shorthand getter for strict `hh:mm:ss` format.
  String get hhMmSs => toHoursMinutesSeconds();
}
