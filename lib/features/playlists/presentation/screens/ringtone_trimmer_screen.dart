import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/features/playlists/domain/models/ringtone_trim_range.dart';
import 'package:nexa_player/features/playlists/presentation/providers/playlists_providers.dart';
import 'package:nexa_player/shared/models/track.dart';

/// Interactive audio trimmer screen allowing users to precision slice a track
/// and set it as a ringtone, notification, or alarm.
class RingtoneTrimmerScreen extends ConsumerStatefulWidget {
  const RingtoneTrimmerScreen({
    super.key,
    required this.track,
  });

  final Track track;

  @override
  ConsumerState<RingtoneTrimmerScreen> createState() =>
      _RingtoneTrimmerScreenState();
}

class _RingtoneTrimmerScreenState extends ConsumerState<RingtoneTrimmerScreen> {
  late double _startSeconds;
  late double _endSeconds;
  late double _maxSeconds;
  bool _isPlayingPreview = false;
  bool _isExporting = false;
  RingtoneTarget _target = RingtoneTarget.ringtone;

  @override
  void initState() {
    super.initState();
    _maxSeconds = (widget.track.duration.inMilliseconds / 1000.0).clamp(5.0, 3600.0);
    _startSeconds = 0.0;
    // Default ringtone length: 30 seconds or max duration
    _endSeconds = (_maxSeconds > 30.0 ? 30.0 : _maxSeconds).clamp(1.0, _maxSeconds);
  }

  void _togglePreview() {
    HapticFeedback.selectionClick();
    setState(() {
      _isPlayingPreview = !_isPlayingPreview;
    });
  }

  Future<void> _handleExport() async {
    HapticFeedback.mediumImpact();
    setState(() => _isExporting = true);

    final range = RingtoneTrimRange(
      startMs: (_startSeconds * 1000).toInt(),
      endMs: (_endSeconds * 1000).toInt(),
    );

    final service = ref.read(ringtoneServiceProvider);
    final res = await service.trimAudio(
      track: widget.track,
      range: range,
      target: _target,
    );

    if (mounted) {
      setState(() => _isExporting = false);
      if (res.isSuccess) {
        final path = res.valueOrNull!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_target.label} exported successfully!\n$path'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.failureOrNull?.message ?? 'Failed to export audio'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatTime(double sec) {
    final s = sec.toInt();
    final mins = s ~/ 60;
    final remainingSecs = s % 60;
    return '$mins:${remainingSecs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final selectedDurationSec = (_endSeconds - _startSeconds).clamp(0.0, _maxSeconds);

    return Scaffold(
      backgroundColor: const Color(0xFF090C13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringtone Trimmer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.track.title} • ${widget.track.artist}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.5),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Waveform & Trimmer Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF10141E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  children: [
                    // Mock waveform visualization bars
                    SizedBox(
                      height: 110,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: List.generate(48, (i) {
                          final barFraction = i / 48.0;
                          final barSec = barFraction * _maxSeconds;
                          final isInRange =
                              barSec >= _startSeconds && barSec <= _endSeconds;
                          final heightNorm =
                              (0.25 + 0.75 * (((i * 13 + 7) % 19) / 19.0));

                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1.2),
                              height: 100 * heightNorm,
                              decoration: BoxDecoration(
                                color: isInRange
                                    ? accent
                                    : Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: isInRange
                                    ? [
                                        BoxShadow(
                                          color: accent.withOpacity(0.4),
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Range Slider
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4.0,
                        activeTrackColor: accent,
                        inactiveTrackColor: Colors.white.withOpacity(0.1),
                        thumbColor: Colors.white,
                        overlayColor: accent.withOpacity(0.2),
                        rangeThumbShape: const RoundRangeSliderThumbShape(
                          enabledThumbRadius: 8.0,
                        ),
                      ),
                      child: RangeSlider(
                        values: RangeValues(_startSeconds, _endSeconds),
                        min: 0.0,
                        max: _maxSeconds,
                        onChanged: (values) {
                          // Enforce minimum 1 second duration
                          if (values.end - values.start >= 1.0) {
                            setState(() {
                              _startSeconds = values.start;
                              _endSeconds = values.end;
                            });
                          }
                        },
                      ),
                    ),

                    // Timing readouts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Start: ${_formatTime(_startSeconds)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontFamily: 'Roboto',
                            fontSize: 12,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accent.withOpacity(0.3)),
                          ),
                          child: Text(
                            'Duration: ${_formatTime(selectedDurationSec)} (${selectedDurationSec.toInt()}s)',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto',
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          'End: ${_formatTime(_endSeconds)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontFamily: 'Roboto',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Audition Playback Button
              Center(
                child: IconButton.filled(
                  onPressed: _togglePreview,
                  iconSize: 36,
                  style: IconButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(16),
                  ),
                  icon: Icon(
                    _isPlayingPreview
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  tooltip: _isPlayingPreview ? 'Pause Preview' : 'Play Selection',
                ),
              ),
              const SizedBox(height: 24),

              // Target Selection
              Text(
                'EXPORT DESTINATION',
                style: AppTypography.labelMedium.copyWith(
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: RingtoneTarget.values.map((target) {
                  final isSelected = target == _target;
                  return InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _target = target);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accent.withOpacity(0.12)
                            : const Color(0xFF131722),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? accent.withOpacity(0.4)
                              : Colors.white.withOpacity(0.04),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            target == RingtoneTarget.ringtone
                                ? Icons.ring_volume_rounded
                                : target == RingtoneTarget.notification
                                    ? Icons.notifications_active_rounded
                                    : target == RingtoneTarget.alarm
                                        ? Icons.alarm_rounded
                                        : Icons.audio_file_rounded,
                            color: isSelected ? accent : Colors.white38,
                            size: 20,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              target.label,
                              style: TextStyle(
                                color: isSelected ? accent : Colors.white,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded,
                                color: accent, size: 20),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Export Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _handleExport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.content_cut_rounded),
                  label: Text(
                    _isExporting
                        ? 'Exporting Trimmed Audio...'
                        : 'Set as ${_target.label}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
