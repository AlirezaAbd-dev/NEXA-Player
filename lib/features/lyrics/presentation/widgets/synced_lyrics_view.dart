import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/features/lyrics/domain/models/lyrics.dart';
import 'package:nexa_player/shared/widgets/typography/bidi_text.dart';

/// Interactive karaoke-style synchronized lyrics viewer.
///
/// Features Apple Music-style depth-of-field blur on inactive lines,
/// smooth centering auto-scroll, active line glow magnification,
/// and tap-to-seek timestamp jumping.
class SyncedLyricsView extends StatefulWidget {
  const SyncedLyricsView({
    super.key,
    required this.lyrics,
    required this.activeIndex,
    this.onSeekToTimestamp,
    this.autoScrollEnabled = true,
  });

  final Lyrics lyrics;
  final int activeIndex;
  final ValueChanged<Duration>? onSeekToTimestamp;
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
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeInOutCubic,
          alignment: 0.38, // Center slightly above midpoint for optimal reading
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
          textColor = Colors.white.withOpacity(0.40);
          fontSize = 17.5;
          fontWeight = FontWeight.w500;
        } else {
          textColor = Colors.white.withOpacity(0.60);
          fontSize = 18.5;
          fontWeight = FontWeight.w500;
        }

        // Apple Music-style depth of field optical blur on inactive lines
        // Disabled automatically under reduced-motion preference
        final disableAnim = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
        final distance = (index - widget.activeIndex).abs();
        final blurSigma = (isActive || disableAnim) ? 0.0 : (distance * 0.75).clamp(0.0, 3.2);

        Widget lineContent = Semantics(
          selected: isActive,
          label: isActive ? 'Current lyric: ${line.text}' : line.text,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BidiText(
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
                            color: accent.withOpacity(0.55),
                            blurRadius: 18.0,
                          ),
                        ]
                      : null,
                ),
              ),
              if (line.translation != null && line.translation!.isNotEmpty) ...[
                const SizedBox(height: 4),
                BidiText(
                  line.translation!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(isActive ? 0.8 : 0.35),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );

        if (blurSigma > 0.01) {
          lineContent = ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: lineContent,
          );
        }

        return Padding(
          key: _lineKeys[index],
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onSeekToTimestamp?.call(line.timestamp);
            },
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? accent.withOpacity(0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: lineContent,
            ),
          ),
        );
      },
    );
  }
}
