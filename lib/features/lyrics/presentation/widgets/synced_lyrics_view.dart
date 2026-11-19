import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/features/lyrics/domain/models/lyrics.dart';

/// Interactive karaoke-style synchronized lyrics viewer.
///
/// Features smooth centering auto-scroll, active line glow magnification,
/// dim inactive lines, and tap-to-seek timestamp jumping.
class SyncedLyricsView extends StatefulWidget {
  const SyncedLyricsView({
    super.key,
    required this.lyrics,
    required this.activeIndex,
    required this.onSeekToTimestamp,
    this.autoScrollEnabled = true,
  });

  final Lyrics lyrics;
  final int activeIndex;
  final ValueChanged<Duration> onSeekToTimestamp;
  final bool autoScrollEnabled;

  @override
  State<SyncedLyricsView> createState() => _SyncedLyricsViewState();
}

class _SyncedLyricsViewState extends State<SyncedLyricsView> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _lineKeys = [];

  @override
  void initState() {
    super.initState();
    _rebuildKeys();
  }

  @override
  void didUpdateWidget(SyncedLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lyrics.lines.length != _lineKeys.length) {
      _rebuildKeys();
    }

    if (widget.activeIndex != oldWidget.activeIndex && widget.autoScrollEnabled) {
      _scrollToActiveLine();
    }
  }

  void _rebuildKeys() {
    _lineKeys.clear();
    for (int i = 0; i < widget.lyrics.lines.length; i++) {
      _lineKeys.add(GlobalKey());
    }
  }

  void _scrollToActiveLine() {
    if (widget.activeIndex < 0 || widget.activeIndex >= _lineKeys.length) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _lineKeys[widget.activeIndex];
      final context = key.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
          alignment: 0.4, // Center slightly above midpoint
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    if (!widget.lyrics.isSynced || widget.lyrics.lines.isEmpty) {
      final plainText = widget.lyrics.plainLyrics ?? 'No lyrics available for this track.';
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          physics: const BouncingScrollPhysics(),
          child: Text(
            plainText,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(
              color: Colors.white.withOpacity(0.85),
              height: 2.0,
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 120),
      physics: const BouncingScrollPhysics(),
      itemCount: widget.lyrics.lines.length,
      itemBuilder: (context, index) {
        final line = widget.lyrics.lines[index];
        final isActive = index == widget.activeIndex;
        final isPast = index < widget.activeIndex;

        final Color textColor;
        final double fontSize;
        final FontWeight fontWeight;

        if (isActive) {
          textColor = Colors.white;
          fontSize = 24.0;
          fontWeight = FontWeight.bold;
        } else if (isPast) {
          textColor = Colors.white.withOpacity(0.35);
          fontSize = 17.0;
          fontWeight = FontWeight.w500;
        } else {
          textColor = Colors.white.withOpacity(0.55);
          fontSize = 18.0;
          fontWeight = FontWeight.w500;
        }

        return Padding(
          key: _lineKeys[index],
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onSeekToTimestamp(line.timestamp);
            },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? accent.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isActive
                    ? Border.all(color: accent.withOpacity(0.3), width: 1.0)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.text.isEmpty ? '♪' : line.text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: fontSize,
                      fontWeight: fontWeight,
                      height: 1.35,
                      letterSpacing: -0.2,
                      shadows: isActive
                          ? [
                              Shadow(
                                color: accent.withOpacity(0.5),
                                blurRadius: 16.0,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  if (line.translation != null && line.translation!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      line.translation!,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.white.withOpacity(isActive ? 0.7 : 0.3),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
