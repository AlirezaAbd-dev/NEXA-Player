import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/di/service_providers.dart' hide playbackQueueProvider;
import '../../../../core/extensions/duration_x.dart';
import '../../../../core/l10n/locale_controller.dart';
import '../../../../core/utils/audio_quality_formatter.dart';
import '../../../../core/theme/dynamic_palette_providers.dart';
import '../../../../core/theme/dynamic_palette_service.dart';
import '../../../../shared/models/track.dart';
import '../../../../shared/widgets/glass/app_ambient_background.dart';
import '../../../../shared/widgets/surfaces/nexa_surface.dart';
import '../../../../shared/widgets/typography/bidi_text.dart';
import '../../../playlists/presentation/widgets/add_to_playlist_bottom_sheet.dart';
import '../../../playlists/presentation/widgets/track_tag_editor_modal.dart';
import '../../../cloud/cloud.dart';
import '../../../visualizer/visualizer.dart';
import '../../domain/services/playback_queue.dart';
import '../providers/player_providers.dart';
import '../widgets/hero_artwork_card.dart';
import '../widgets/playing_queue_sheet.dart';
import '../widgets/sleep_timer_bottom_sheet.dart';
import '../widgets/stellio_repeat_picker_sheet.dart';
import '../widgets/waveform_visualizer.dart';

/// Layout modes supported by the Now Playing hero screen.
enum NowPlayingLayoutMode {
  /// Standard modern layout with hero artwork, waveform seeker, and controls.
  standard,

  /// Full-size vinyl turntable display with rotating grooves.
  vinyl,

  /// Clean immersive artwork layout with floating controls.
  art,
}

/// Full-screen showstopper Now Playing screen featuring:
/// - Edge-slide gestures: Right edge = DVC volume, Left edge = playback speed.
/// - Variable-speed tactile waveform gearshift scrubber (1x -> 0.5x -> 0.1x).
/// - Double-tap artwork seek (+/- 10s).
/// - 3D Perspective Card Flip revealing the 3D Signal Chain studio telemetry.
/// - Compact L2 bottom utility dock housing secondary controls in the thumb zone.
class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen>
    with SingleTickerProviderStateMixin {
  NowPlayingLayoutMode _layoutMode = NowPlayingLayoutMode.standard;
  bool _showSpectrumVisualizer = false;
  List<double>? _cachedWaveform;

  // Interactive pull-down dismiss & drag-up queue gesture state with diagonal arbitration
  double _dragY = 0.0;
  double _upDragY = 0.0;
  bool _isDismissing = false;
  Offset? _dragStartPoint;
  bool _verticalDismissLocked = false;
  bool _verticalQueueLocked = false;
  bool _diagonalRejected = false;
  bool _queueOpenedForDrag = false;
  late final AnimationController _snapBackController;
  Animation<double>? _snapBackAnimation;

  // Stellio 3D cover flow fractional scroll position
  double? _carouselPageOffset;

  void _handlePageScrolled(double pageOffset) {
    if (mounted) {
      setState(() {
        _carouselPageOffset = pageOffset;
      });
    }
  }

  void _handlePageSettled(int newIndex) {
    if (mounted) {
      setState(() {
        _carouselPageOffset = null;
      });
    }
    ref.read(playerNotifierProvider.notifier).skipToIndex(newIndex);
  }

  // Edge HUD gesture state
  String? _edgeHudText;
  IconData? _edgeHudIcon;
  Timer? _edgeHudTimer;

  void _showEdgeHud(
    String text,
    IconData icon, {
    Duration duration = const Duration(milliseconds: 1400),
  }) {
    _edgeHudTimer?.cancel();
    setState(() {
      _edgeHudText = text;
      _edgeHudIcon = icon;
    });
    _edgeHudTimer = Timer(duration, () {
      if (mounted) {
        setState(() {
          _edgeHudText = null;
          _edgeHudIcon = null;
        });
      }
    });
  }

  void _handleLeftEdgeDrag(DragUpdateDetails details) {
    final player = ref.read(playerNotifierProvider);
    final currentSpeed = player.speed;
    final delta = -(details.primaryDelta ?? 0.0) / 250.0;
    final newSpeed = (currentSpeed + delta).clamp(0.5, 2.0);
    final rounded = (newSpeed * 10).round() / 10.0;
    ref.read(playerNotifierProvider.notifier).setSpeed(rounded);
    _showEdgeHud('Speed: ${rounded.toStringAsFixed(1)}×', Icons.speed_rounded);
  }

  void _handleRightEdgeDrag(DragUpdateDetails details) {
    final player = ref.read(playerNotifierProvider);
    final currentVol = player.volume;
    final delta = -(details.primaryDelta ?? 0.0) / 200.0;
    final newVol = (currentVol + delta).clamp(0.0, 1.0);
    ref.read(playerNotifierProvider.notifier).setVolume(newVol);
    _showEdgeHud(
      'Volume: ${(newVol * 100).round()}%',
      newVol == 0 ? Icons.volume_mute_rounded : Icons.volume_up_rounded,
    );
  }

  void _seekRelative(Duration delta) {
    final player = ref.read(playerNotifierProvider);
    final currentPos = player.position;
    final dur = player.duration;
    final target = (currentPos + delta).clamp(Duration.zero, dur);
    ref.read(playerNotifierProvider.notifier).seek(target);
    _showEdgeHud(
      delta.isNegative ? '-10s' : '+10s',
      delta.isNegative ? Icons.replay_10_rounded : Icons.forward_10_rounded,
    );
  }

  void _cycleLayoutMode() {
    HapticFeedback.selectionClick();
    setState(() {
      switch (_layoutMode) {
        case NowPlayingLayoutMode.standard:
          _layoutMode = NowPlayingLayoutMode.vinyl;
          break;
        case NowPlayingLayoutMode.vinyl:
          _layoutMode = NowPlayingLayoutMode.art;
          break;
        case NowPlayingLayoutMode.art:
          _layoutMode = NowPlayingLayoutMode.standard;
          break;
      }
    });
  }

  void _showDisplayModesSheet(BuildContext context, bool isCasting) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                isCasting ? Icons.cast_connected_rounded : Icons.cast_rounded,
                color: isCasting ? const Color(0xFF00E676) : null,
              ),
              title: Text(l10n.castAudio),
              onTap: () {
                Navigator.of(ctx).pop();
                CastDevicePickerModal.show(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.nightlight_round),
              title: Text(l10n.bedsideStandbyMode),
              onTap: () {
                Navigator.of(ctx).pop();
                context.push(AppRoutes.standby);
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_car_rounded),
              title: Text(l10n.carDrivingMode),
              onTap: () {
                Navigator.of(ctx).pop();
                context.push(AppRoutes.carMode);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _loadWaveformIfAvailable(String? trackId, String? filePath) {
    if (trackId == null) return;
    if (!getIt.isRegistered<IWaveformPreProcessor>()) return;
    final preProcessor = ref.read(waveformPreProcessorProvider);
    preProcessor
        .getOrAnalyzeWaveform(
          trackId: trackId,
          filePath: filePath ?? '',
          sampleCount: 56,
        )
        .then((amplitudes) {
      if (mounted && amplitudes.isNotEmpty) {
        setState(() {
          _cachedWaveform = amplitudes;
        });
      }
    });
  }

  void _handlePullDownDragStart(DragStartDetails details) {
    if (_isDismissing) return;
    _dragStartPoint = details.globalPosition;
    _verticalDismissLocked = false;
    _verticalQueueLocked = false;
    _diagonalRejected = false;
    _queueOpenedForDrag = false;
    _upDragY = 0.0;
    if (_snapBackController.isAnimating) {
      _snapBackController.stop();
    }
  }

  void _handlePullDownDragUpdate(DragUpdateDetails details) {
    if (_isDismissing || _diagonalRejected) return;
    if (!_verticalDismissLocked &&
        !_verticalQueueLocked &&
        _dragStartPoint != null) {
      final totalDelta = details.globalPosition - _dragStartPoint!;
      if (totalDelta.distance < 12.0) return;
      if (totalDelta.dx.abs() > totalDelta.dy.abs()) {
        _diagonalRejected = true;
        return;
      }
      if (totalDelta.dy > 0) {
        _verticalDismissLocked = true;
      } else if (totalDelta.dy < 0) {
        _verticalQueueLocked = true;
      }
    }
    if (_verticalQueueLocked) {
      _upDragY += details.primaryDelta ?? 0.0;
      if (_upDragY < -40.0 && !_queueOpenedForDrag) {
        _queueOpenedForDrag = true;
        HapticFeedback.lightImpact();
        PlayingQueueSheet.show(context);
      }
      return;
    }
    final screenHeight = MediaQuery.of(context).size.height;
    final delta = details.primaryDelta ?? 0.0;
    setState(() {
      _dragY = (_dragY + delta).clamp(0.0, screenHeight);
    });
  }

  void _handlePullDownDragEnd(DragEndDetails details) {
    _dragStartPoint = null;
    if (_isDismissing) return;
    if (_verticalQueueLocked) {
      final velocity = details.primaryVelocity ?? 0.0;
      if (!_queueOpenedForDrag && (velocity < -600.0 || _upDragY < -40.0)) {
        _queueOpenedForDrag = true;
        HapticFeedback.lightImpact();
        PlayingQueueSheet.show(context);
      }
      _verticalQueueLocked = false;
      _upDragY = 0.0;
      return;
    }
    if (_diagonalRejected) {
      _diagonalRejected = false;
      _verticalDismissLocked = false;
      _animateSnapBack();
      return;
    }
    _verticalDismissLocked = false;
    final velocity = details.primaryVelocity ?? 0.0;
    final shouldDismiss = _dragY > 150.0 || velocity > 800.0;

    if (shouldDismiss) {
      _isDismissing = true;
      HapticFeedback.lightImpact();
      _dismissScreen();
    } else {
      _animateSnapBack();
    }
  }

  void _dismissScreen() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.pop();
    }
  }

  void _handlePullDownDragCancel() {
    _dragStartPoint = null;
    _diagonalRejected = false;
    _verticalDismissLocked = false;
    _verticalQueueLocked = false;
    _upDragY = 0.0;
    if (_isDismissing) return;
    _animateSnapBack();
  }

  void _handleDockUpDragStart(DragStartDetails details) {
    _upDragY = 0.0;
    _queueOpenedForDrag = false;
  }

  void _handleDockUpDragUpdate(DragUpdateDetails details) {
    _upDragY += details.primaryDelta ?? 0.0;
    if (_upDragY < -40.0 && !_queueOpenedForDrag) {
      _queueOpenedForDrag = true;
      HapticFeedback.lightImpact();
      PlayingQueueSheet.show(context);
    }
  }

  void _handleDockUpDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    if (!_queueOpenedForDrag && (velocity < -600.0 || _upDragY < -40.0)) {
      _queueOpenedForDrag = true;
      HapticFeedback.lightImpact();
      PlayingQueueSheet.show(context);
    }
    _upDragY = 0.0;
  }

  void _animateSnapBack() {
    if (!mounted || _dragY == 0.0) return;
    if (MediaQuery.of(context).disableAnimations) {
      setState(() {
        _dragY = 0.0;
      });
      return;
    }
    _snapBackAnimation = Tween<double>(
      begin: _dragY,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _snapBackController,
        curve: Curves.easeOutCubic,
      ),
    );
    _snapBackController.forward(from: 0.0);
  }

  @override
  void initState() {
    super.initState();
    _snapBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _snapBackController.addListener(() {
      if (_snapBackAnimation != null && mounted) {
        setState(() {
          _dragY = _snapBackAnimation!.value;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentTrack = ref.read(playerNotifierProvider).currentTrack;
      if (currentTrack != null) {
        _loadWaveformIfAvailable(currentTrack.id, currentTrack.filePath);
      }
    });
  }

  @override
  void dispose() {
    _snapBackController.dispose();
    _edgeHudTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isDynamicEnabled = ref.watch(dynamicThemeEnabledProvider);
    final dynamicPalette = ref.watch(activeDynamicPaletteProvider);

    final playerState = ref.watch(playerNotifierProvider);
    final currentTrack = playerState.currentTrack;
    final isPlaying = playerState.isPlaying;

    PlaybackQueueState queueState = const PlaybackQueueState();
    try {
      final q = ref.watch(playbackQueueProvider);
      queueState =
          ref.watch(playbackQueueStateStreamProvider).valueOrNull ?? q.state;
    } catch (_) {
      queueState = const PlaybackQueueState();
    }
    final queueTracks = queueState.tracks;
    final queueCurrentIndex = (queueState.currentIndex >= 0 && queueState.currentIndex < queueTracks.length)
        ? queueState.currentIndex
        : 0;
    final effectiveTracks = queueTracks.isNotEmpty
        ? queueTracks
        : (currentTrack != null ? [currentTrack] : const <Track>[]);

    final activeOffset = (_carouselPageOffset ?? queueCurrentIndex.toDouble())
        .clamp(0.0, effectiveTracks.isEmpty ? 0.0 : (effectiveTracks.length - 1).toDouble());
    ExtractedPalette currentDisplayPalette = dynamicPalette;
    if (effectiveTracks.isNotEmpty) {
      final floorIndex = activeOffset.floor().clamp(0, effectiveTracks.length - 1);
      final ceilIndex = activeOffset.ceil().clamp(0, effectiveTracks.length - 1);
      final t = (activeOffset - floorIndex).clamp(0.0, 1.0);

      final palA = (floorIndex == queueCurrentIndex && isDynamicEnabled)
          ? dynamicPalette
          : const DynamicPaletteService().computeSeedPalette(
              '${effectiveTracks[floorIndex].title} ${effectiveTracks[floorIndex].artist} ${effectiveTracks[floorIndex].album}',
            );
      final palB = (ceilIndex == queueCurrentIndex && isDynamicEnabled)
          ? dynamicPalette
          : const DynamicPaletteService().computeSeedPalette(
              '${effectiveTracks[ceilIndex].title} ${effectiveTracks[ceilIndex].artist} ${effectiveTracks[ceilIndex].album}',
            );
      if (isDynamicEnabled) {
        currentDisplayPalette = ExtractedPalette.lerp(palA, palB, t);
      } else if (_carouselPageOffset != null && floorIndex != ceilIndex) {
        currentDisplayPalette = ExtractedPalette.lerp(palA, palB, t);
      }
    }

    final dragTintPrimary = (_carouselPageOffset != null &&
            effectiveTracks.length > 1 &&
            !isDynamicEnabled)
        ? Color.lerp(colorScheme.primary, currentDisplayPalette.primary, 0.45) ??
            colorScheme.primary
        : (isDynamicEnabled ? currentDisplayPalette.primary : colorScheme.primary);
    final primary = dragTintPrimary;
    final surfaceTokens = NexaSurfaceTokens.of(context);

    final title = currentTrack?.title ?? 'Starboy';
    final artistAndAlbum = currentTrack?.artistAndAlbum ?? 'The Weeknd • Daft Punk';
    final albumHeader = (currentTrack != null && currentTrack.album.isNotEmpty)
        ? currentTrack.album
        : 'Starboy';

    final isFavorite = currentTrack?.isFavorite ?? false;
    final isShuffle = playerState.isShuffled;
    final repeatMode = playerState.repeatMode;
    final isCasting = ref.watch(isCastingActiveProvider);

    final screenHeight = MediaQuery.of(context).size.height;
    final progress = (screenHeight > 0 ? (_dragY / screenHeight) : 0.0).clamp(0.0, 1.0);
    final scale = (1.0 - progress * 0.04).clamp(0.90, 1.0);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: Stack(
      children: [
        // Backdrop dimming scrim modulating over the route barrier
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: Colors.black.withOpacity(
                (0.20 * (1.0 - progress)).clamp(0.0, 0.20),
              ),
            ),
          ),
        ),

        // Sliding and scaling player sheet
        Transform.translate(
          offset: Offset(0.0, _dragY),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topCenter,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(progress > 0 ? 24.0 : 0.0),
              ),
              child: Scaffold(
                backgroundColor: theme.scaffoldBackgroundColor,
                body: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. Ambient Background Glow
                    AppAmbientBackground(
                      primaryColor: isDynamicEnabled ? currentDisplayPalette.primary : null,
                      secondaryColor: isDynamicEnabled ? currentDisplayPalette.secondary : null,
                      tertiaryColor: isDynamicEnabled ? currentDisplayPalette.darkVibrant : null,
                    ),

                    // 2. Main Sculptural Content
                    SafeArea(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final availableHeight = constraints.maxHeight;
                          final availableWidth = constraints.maxWidth;
                          final double maxArt = math.min(
                            availableWidth - 40.0,
                            _layoutMode == NowPlayingLayoutMode.art ? 300.0 : 272.0,
                          );
                          final double artworkSize =
                              (availableHeight * 0.39).clamp(132.0, maxArt.clamp(140.0, 310.0));
                          final isCompactHeight = availableHeight < 640.0;
                          final playButtonSize = isCompactHeight ? 56.0 : 64.0;
                          final queueSourceLabel = queueState.queueContext?.collectionTitle ?? albumHeader;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Zone 1: Top Header Region (~56dp)
                                GestureDetector(
                                  key: const ValueKey('now_playing_pull_down_header'),
                                  behavior: HitTestBehavior.translucent,
                                  onVerticalDragStart: _handlePullDownDragStart,
                                  onVerticalDragUpdate: _handlePullDownDragUpdate,
                                  onVerticalDragEnd: _handlePullDownDragEnd,
                                  onVerticalDragCancel: _handlePullDownDragCancel,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 0.0, bottom: 4.0),
                                          child: Container(
                                            key: const ValueKey('now_playing_grabber_pill'),
                                            width: 36.0,
                                            height: 4.0,
                                            decoration: BoxDecoration(
                                              color: colorScheme.onSurface.withOpacity(0.35),
                                              borderRadius: BorderRadius.circular(2.0),
                                            ),
                                          ),
                                        ),
                                      ),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                                            onPressed: _dismissScreen,
                                            tooltip: 'Minimize',
                                            padding: const EdgeInsets.all(6),
                                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                          ),
                                          Expanded(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  context.l10n.playingFrom,
                                                  style: surfaceTokens.telemetryTextStyle.copyWith(
                                                    letterSpacing: effectiveLetterSpacing(context, 1.2),
                                                    color: colorScheme.onSurface.withOpacity(0.6),
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 10.0,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                BidiText(
                                                  queueSourceLabel,
                                                  style: AppTypography.titleSmall.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  _layoutMode == NowPlayingLayoutMode.standard
                                                      ? Icons.view_carousel_rounded
                                                      : _layoutMode == NowPlayingLayoutMode.vinyl
                                                          ? Icons.album_rounded
                                                          : Icons.image_rounded,
                                                  size: 20,
                                                ),
                                                onPressed: _cycleLayoutMode,
                                                tooltip: 'Switch Layout Mode',
                                                padding: const EdgeInsets.all(4),
                                                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  isCasting
                                                      ? Icons.cast_connected_rounded
                                                      : Icons.devices_other_rounded,
                                                  size: 20,
                                                  color: isCasting ? const Color(0xFF00E676) : null,
                                                ),
                                                onPressed: () => _showDisplayModesSheet(context, isCasting),
                                                tooltip: 'Output & Display Modes',
                                                padding: const EdgeInsets.all(4),
                                                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                              ),
                                              PopupMenuButton<String>(
                                                key: const ValueKey('now_playing_more_menu'),
                                                icon: const Icon(Icons.more_vert_rounded, size: 20),
                                                tooltip: 'Track Actions',
                                                padding: const EdgeInsets.all(4),
                                                onSelected: (value) {
                                                  switch (value) {
                                                    case 'add_to_playlist':
                                                      if (currentTrack != null) {
                                                        AddToPlaylistBottomSheet.show(
                                                          context,
                                                          track: currentTrack,
                                                        );
                                                      }
                                                      break;
                                                    case 'edit_tags':
                                                      if (currentTrack != null) {
                                                        TrackTagEditorModal.show(
                                                          context,
                                                          track: currentTrack,
                                                        );
                                                      }
                                                      break;
                                                  }
                                                },
                                                itemBuilder: (_) => [
                                                  if (currentTrack != null) ...[
                                                    const PopupMenuItem(
                                                      value: 'add_to_playlist',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.playlist_add_rounded, size: 18),
                                                          SizedBox(width: 8),
                                                          Text('Add to playlist'),
                                                        ],
                                                      ),
                                                    ),
                                                    const PopupMenuItem(
                                                      value: 'edit_tags',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.edit_note_rounded, size: 18),
                                                          SizedBox(width: 8),
                                                          Text('Edit tags & cover'),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Zone 2: Center Hero Artwork with Radial Ambient Wash & Diagonal Arbitration
                                Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    IgnorePointer(
                                      child: Container(
                                        width: artworkSize * 1.45,
                                        height: artworkSize * 1.45,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            radius: 0.5,
                                            colors: [
                                              primary.withOpacity(isDark ? 0.20 : 0.12),
                                              primary.withOpacity(isDark ? 0.06 : 0.03),
                                              primary.withOpacity(0.0),
                                            ],
                                            stops: const [0.0, 0.55, 1.0],
                                          ),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      key: const ValueKey('now_playing_pull_down_artwork'),
                                      behavior: HitTestBehavior.translucent,
                                      onVerticalDragStart: _handlePullDownDragStart,
                                      onVerticalDragUpdate: _handlePullDownDragUpdate,
                                      onVerticalDragEnd: _handlePullDownDragEnd,
                                      onVerticalDragCancel: _handlePullDownDragCancel,
                                      child: Hero(
                                        tag: 'now_playing_art',
                                        child: HeroArtworkCard(
                                          track: currentTrack,
                                          tracks: effectiveTracks,
                                          currentIndex: queueCurrentIndex,
                                          queueVersion: queueState.queueVersion,
                                          isPlaying: isPlaying,
                                          breathingEnergy:
                                              ref.watch(subBassEnergyProvider),
                                          size: artworkSize,
                                          onPageSettled: _handlePageSettled,
                                          onPageScrolled: _handlePageScrolled,
                                          onSwipeLeft: () {
                                            ref.read(playerNotifierProvider.notifier).skipNext();
                                          },
                                          onSwipeRight: () {
                                            ref.read(playerNotifierProvider.notifier).skipPrevious();
                                          },
                                          onDoubleTapSeekForward: () =>
                                              _seekRelative(const Duration(seconds: 10)),
                                          onDoubleTapSeekBackward: () =>
                                              _seekRelative(const Duration(seconds: -10)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Zone 3: Synchronized Metadata Parallax Row + Quality Telemetry Badge
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: _buildSynchronizedMetadataBlock(
                                            context: context,
                                            effectiveTracks: effectiveTracks,
                                            activeOffset: activeOffset,
                                            fallbackTitle: title,
                                            fallbackSubtitle: artistAndAlbum,
                                            isCompactHeight: isCompactHeight,
                                            onSurface: colorScheme.onSurface,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            isFavorite
                                                ? Icons.favorite_rounded
                                                : Icons.favorite_border_rounded,
                                            color: isFavorite
                                                ? Colors.redAccent.shade200
                                                : colorScheme.onSurface.withOpacity(0.65),
                                            size: 26,
                                          ),
                                          onPressed: () {
                                            HapticFeedback.lightImpact();
                                            ref.read(playerNotifierProvider.notifier).toggleFavorite();
                                          },
                                          tooltip: 'Favorite',
                                          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    NexaSurface(
                                      level: NexaSurfaceLevel.l2,
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                          vertical: 3.0,
                                        ),
                                        child: Text(
                                          AudioQualityFormatter.formatNowPlayingBadge(currentTrack),
                                          style: surfaceTokens.telemetryTextStyle.copyWith(
                                            color: primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10.0,
                                            fontFeatures: const [FontFeature.tabularFigures()],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Zone 4: Tactile 56-Bar Waveform / Spectrum Visualizer
                                _showSpectrumVisualizer
                                    ? SizedBox(
                                        height: isCompactHeight ? 52 : 64,
                                        child: GestureDetector(
                                          onTap: () => context.push(AppRoutes.visualizerSettings),
                                          child: SpectrumVisualizerWidget(
                                            height: isCompactHeight ? 52 : 64,
                                          ),
                                        ),
                                      )
                                    : WaveformVisualizer(
                                        position: playerState.position,
                                        duration: playerState.duration.inSeconds > 0
                                            ? playerState.duration
                                            : const Duration(seconds: 230),
                                        isPlaying: isPlaying,
                                        trackSeed: currentTrack?.id ?? 'default_seed',
                                        cachedAmplitudes: _cachedWaveform,
                                        activeColor: primary,
                                        height: isCompactHeight ? 44.0 : 52.0,
                                        onSeek: (newPos) {
                                          ref.read(playerNotifierProvider.notifier).seek(newPos);
                                        },
                                      ),

                                // Zone 5: Primary Playback Controls Row (Thumb Zone)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        isShuffle
                                            ? Icons.shuffle_on_rounded
                                            : Icons.shuffle_rounded,
                                        color: isShuffle
                                            ? primary
                                            : colorScheme.onSurface.withOpacity(0.65),
                                      ),
                                      onPressed: () {
                                        HapticFeedback.selectionClick();
                                        ref.read(playerNotifierProvider.notifier).toggleShuffle();
                                      },
                                      tooltip: 'Shuffle',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.skip_previous_rounded, size: 36),
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        ref.read(playerNotifierProvider.notifier).skipPrevious();
                                      },
                                      tooltip: 'Previous',
                                    ),
                                    Container(
                                      width: playButtonSize,
                                      height: playButtonSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: primary,
                                        boxShadow: [
                                          BoxShadow(
                                            color: primary.withOpacity(0.36),
                                            blurRadius: 18.0,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          isPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          size: isCompactHeight ? 32 : 36,
                                          color: colorScheme.onPrimary,
                                        ),
                                        onPressed: () {
                                          HapticFeedback.mediumImpact();
                                          ref
                                              .read(playerNotifierProvider.notifier)
                                              .togglePlayPause();
                                        },
                                        tooltip: isPlaying ? 'Pause' : 'Play',
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.skip_next_rounded, size: 36),
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        ref.read(playerNotifierProvider.notifier).skipNext();
                                      },
                                      tooltip: 'Next',
                                    ),
                                    Semantics(
                                      button: true,
                                      label: 'Repeat: ${repeatMode.label}',
                                      hint: 'Tap to cycle repeat mode, long press for options',
                                      child: Material(
                                        type: MaterialType.transparency,
                                        child: InkResponse(
                                          key: const Key('now_playing_repeat_button'),
                                          radius: 24.0,
                                          containedInkWell: false,
                                          onLongPress: () {
                                            HapticFeedback.mediumImpact();
                                            showStellioRepeatPickerSheet(
                                              context: context,
                                              activeMode: repeatMode,
                                              onSelected: (selected) {
                                                ref
                                                    .read(playerNotifierProvider.notifier)
                                                    .setRepeatMode(selected);
                                                _showEdgeHud(
                                                  selected.shortLabel,
                                                  iconForNexaRepeatMode(selected),
                                                  duration: const Duration(milliseconds: 1600),
                                                );
                                              },
                                            );
                                          },
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            final nextMode = repeatMode.nextMode;
                                            ref
                                                .read(playerNotifierProvider.notifier)
                                                .cycleRepeatMode();
                                            _showEdgeHud(
                                              nextMode.shortLabel,
                                              iconForNexaRepeatMode(nextMode),
                                              duration: const Duration(milliseconds: 1600),
                                            );
                                          },
                                          child: SizedBox(
                                            width: 48.0,
                                            height: 48.0,
                                            child: Center(
                                              child: Icon(
                                                iconForNexaRepeatMode(repeatMode),
                                                color: repeatMode.isRepeating
                                                    ? primary
                                                    : colorScheme.onSurface.withOpacity(0.65),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Zone 6: Borderless L2 Bottom Action Dock (Drag-Up Opens Queue Sheet)
                                GestureDetector(
                                  key: const ValueKey('now_playing_drag_up_dock'),
                                  behavior: HitTestBehavior.translucent,
                                  onVerticalDragStart: _handleDockUpDragStart,
                                  onVerticalDragUpdate: _handleDockUpDragUpdate,
                                  onVerticalDragEnd: _handleDockUpDragEnd,
                                  child: NexaSurface(
                                    level: NexaSurfaceLevel.l2,
                                    borderRadius: BorderRadius.circular(20.0),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: 4.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.lyrics_rounded, size: 20),
                                            onPressed: () => context.push(AppRoutes.lyrics),
                                            tooltip: context.l10n.lyrics,
                                            padding: const EdgeInsets.all(6),
                                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.equalizer_rounded, size: 20),
                                            onPressed: () => context.push(AppRoutes.equalizer),
                                            tooltip: context.l10n.equalizerAndDsp,
                                            padding: const EdgeInsets.all(6),
                                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              _showSpectrumVisualizer
                                                  ? Icons.graphic_eq_rounded
                                                  : Icons.waterfall_chart_rounded,
                                              size: 20,
                                              color: _showSpectrumVisualizer ? primary : null,
                                            ),
                                            onPressed: () {
                                              HapticFeedback.selectionClick();
                                              setState(() {
                                                _showSpectrumVisualizer = !_showSpectrumVisualizer;
                                              });
                                            },
                                            tooltip: 'Toggle Spectrum Visualizer',
                                            padding: const EdgeInsets.all(6),
                                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.playlist_add_rounded, size: 20),
                                            onPressed: currentTrack == null
                                                ? null
                                                : () => AddToPlaylistBottomSheet.show(
                                                      context,
                                                      track: currentTrack,
                                                    ),
                                            tooltip: 'Add to Playlist',
                                            padding: const EdgeInsets.all(6),
                                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.bedtime_rounded, size: 20),
                                            onPressed: () => SleepTimerBottomSheet.show(context),
                                            tooltip: 'Sleep Timer',
                                            padding: const EdgeInsets.all(6),
                                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.queue_music_rounded, size: 20),
                                            onPressed: () => PlayingQueueSheet.show(context),
                                            tooltip: 'Queue',
                                            padding: const EdgeInsets.all(6),
                                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
        ),
      ),

          // 3. Edge Gesture Touch Zones (Left = Speed, Right = Volume)
          Positioned(
            left: 0,
            top: 120,
            bottom: 120,
            width: 32.0,
            child: GestureDetector(
              key: const ValueKey('now_playing_left_edge_rail'),
              behavior: HitTestBehavior.translucent,
              onVerticalDragUpdate: _handleLeftEdgeDrag,
            ),
          ),
          Positioned(
            right: 0,
            top: 120,
            bottom: 120,
            width: 32.0,
            child: GestureDetector(
              key: const ValueKey('now_playing_right_edge_rail'),
              behavior: HitTestBehavior.translucent,
              onVerticalDragUpdate: _handleRightEdgeDrag,
            ),
          ),

          // 4. Floating Edge HUD Toast
          if (_edgeHudText != null)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: NexaSurface(
                  level: NexaSurfaceLevel.l3,
                  borderRadius: BorderRadius.circular(20.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_edgeHudIcon != null) ...[
                          Icon(_edgeHudIcon, color: primary, size: 18),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _edgeHudText!,
                          style: surfaceTokens.telemetryTextStyle.copyWith(
                            color: primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  ),
),
),
],
),
    );
  }

  Widget _buildSynchronizedMetadataBlock({
    required BuildContext context,
    required List<Track> effectiveTracks,
    required double activeOffset,
    required String fallbackTitle,
    required String fallbackSubtitle,
    required bool isCompactHeight,
    required Color onSurface,
  }) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final titleStyle =
        (isCompactHeight ? AppTypography.titleLarge : AppTypography.headlineMedium)
            .copyWith(
      color: onSurface,
      fontWeight: FontWeight.bold,
    );
    final subtitleStyle = AppTypography.bodyLarge.copyWith(
      color: onSurface.withOpacity(0.72),
    );

    Widget buildPair(String t, String sub) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          BidiText(
            t,
            style: titleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          BidiText(
            sub,
            style: subtitleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    if (effectiveTracks.length <= 1) {
      return buildPair(fallbackTitle, fallbackSubtitle);
    }

    final floorIdx = activeOffset.floor().clamp(0, effectiveTracks.length - 1);
    final ceilIdx = activeOffset.ceil().clamp(0, effectiveTracks.length - 1);
    final frac = (activeOffset - floorIdx).clamp(0.0, 1.0);

    if (floorIdx == ceilIdx || frac == 0.0) {
      final track = effectiveTracks[floorIdx];
      return buildPair(track.title, track.artistAndAlbum);
    }

    final trackA = effectiveTracks[floorIdx];
    final trackB = effectiveTracks[ceilIdx];
    final parallaxShiftA = disableAnimations ? 0.0 : -frac * 24.0;
    final parallaxShiftB = disableAnimations ? 0.0 : (1.0 - frac) * 24.0;

    return Stack(
      key: const ValueKey('now_playing_metadata_parallax'),
      clipBehavior: Clip.hardEdge,
      children: [
        Transform.translate(
          offset: Offset(parallaxShiftA, 0.0),
          child: Opacity(
            opacity: (1.0 - frac).clamp(0.0, 1.0),
            child: buildPair(trackA.title, trackA.artistAndAlbum),
          ),
        ),
        Transform.translate(
          offset: Offset(parallaxShiftB, 0.0),
          child: Opacity(
            opacity: frac.clamp(0.0, 1.0),
            child: buildPair(trackB.title, trackB.artistAndAlbum),
          ),
        ),
      ],
    );
  }
}
