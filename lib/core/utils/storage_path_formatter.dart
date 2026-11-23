import 'package:flutter/material.dart';

/// Utility class for formatting Android filesystem paths into human-readable breadcrumb labels.
///
/// Converts Unix/Android filesystem roots into clean, interactive breadcrumb navigation:
/// - `/storage/emulated/0/Music/Rock` -> `Internal › Music › Rock`
/// - `/storage/emulated/0` -> `Internal`
/// - `/sdcard/Music` -> `Internal › Music`
/// - `/storage/9C33-6BBD/FLAC` -> `SD Card › FLAC`
/// - `/storage/ABCD-1234/Music/Jazz` -> `SD Card › Music › Jazz`
abstract final class StoragePathFormatter {
  /// Converts a raw filesystem path into a human-readable breadcrumb string.
  static String formatBreadcrumb(String path) {
    if (path.isEmpty) return path;

    final normalized = path.replaceAll(r'\', '/');

    // 1. Internal Emulated Storage (/storage/emulated/0/...)
    final emulatedRegex = RegExp(r'^/storage/emulated/0(?:/(.*))?$');
    final emulatedMatch = emulatedRegex.firstMatch(normalized);
    if (emulatedMatch != null) {
      final subPath = emulatedMatch.group(1);
      if (subPath == null || subPath.isEmpty) return 'Internal';
      final parts = subPath.split('/').where((s) => s.isNotEmpty);
      return 'Internal › ${parts.join(' › ')}';
    }

    // 2. Legacy /sdcard symlink to internal storage
    if (normalized.startsWith('/sdcard')) {
      final subPath = normalized.substring('/sdcard'.length).replaceAll(RegExp(r'^/'), '');
      if (subPath.isEmpty) return 'Internal';
      final parts = subPath.split('/').where((s) => s.isNotEmpty);
      return 'Internal › ${parts.join(' › ')}';
    }

    // 3. Removable MicroSD Card (/storage/XXXX-XXXX/...)
    final sdRegex = RegExp(r'^/storage/([0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}|[^/]+)(?:/(.*))?$');
    final sdMatch = sdRegex.firstMatch(normalized);
    if (sdMatch != null) {
      final volumeId = sdMatch.group(1)!;
      if (volumeId != 'emulated' && volumeId != 'self') {
        final subPath = sdMatch.group(2);
        if (subPath == null || subPath.isEmpty) return 'SD Card';
        final parts = subPath.split('/').where((s) => s.isNotEmpty);
        return 'SD Card › ${parts.join(' › ')}';
      }
    }

    // Fallback: strip leading slash and join with breadcrumbs
    final trimmed = normalized.replaceFirst(RegExp(r'^/'), '');
    final parts = trimmed.split('/').where((s) => s.isNotEmpty);
    return parts.isEmpty ? normalized : parts.join(' › ');
  }

  /// Splits a path into individual breadcrumb segment strings.
  static List<String> toSegments(String path) {
    final breadcrumb = formatBreadcrumb(path);
    return breadcrumb
        .split(' › ')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Builds a list of interactive breadcrumb chip/pill widgets.
  static Widget buildBreadcrumbRow({
    required BuildContext context,
    required String path,
    ValueChanged<String>? onSegmentTap,
    TextStyle? textStyle,
    Color? iconColor,
  }) {
    final segments = toSegments(path);
    if (segments.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final style = textStyle ??
        theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.7),
          fontSize: 11.0,
          fontWeight: FontWeight.w500,
        );

    final dividerColor = iconColor ?? theme.colorScheme.primary.withOpacity(0.6);

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (int i = 0; i < segments.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 14.0,
                color: dividerColor,
              ),
            ),
          InkWell(
            borderRadius: BorderRadius.circular(4.0),
            onTap: onSegmentTap != null ? () => onSegmentTap(segments[i]) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 1.0),
              child: Text(
                segments[i],
                style: i == segments.length - 1
                    ? style?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      )
                    : style,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
