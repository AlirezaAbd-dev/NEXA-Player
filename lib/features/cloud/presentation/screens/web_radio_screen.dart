import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/glass_tokens.dart';
import '../../../../shared/models/track.dart';
import '../../../../shared/widgets/glass/app_ambient_background.dart';
import '../../../../shared/widgets/glass/glass_app_bar.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../player/presentation/providers/player_providers.dart';
import '../providers/cast_providers.dart';
import '../widgets/cast_device_picker_modal.dart';

/// Curated station model for audiophile internet radio streams.
class RadioStation {
  const RadioStation({
    required this.id,
    required this.name,
    required this.streamUrl,
    required this.qualityBadge,
    required this.genre,
    required this.description,
    this.badgeColor = const Color(0xFF00E676),
  });

  final String id;
  final String name;
  final String streamUrl;
  final String qualityBadge;
  final String genre;
  final String description;
  final Color badgeColor;

  Track toTrack() {
    return Track(
      id: 'radio_$id',
      title: name,
      artist: 'Live Web Radio',
      album: genre,
      duration: const Duration(hours: 24),
      filePath: streamUrl,
    );
  }
}

/// Screen showcasing curated high-definition lossless FLAC and high-bitrate AAC web radio broadcasts.
class WebRadioScreen extends ConsumerWidget {
  const WebRadioScreen({super.key});

  static const List<RadioStation> stations = [
    RadioStation(
      id: 'rp_main',
      name: 'Radio Paradise (Main Mix)',
      streamUrl: 'https://stream.radioparadise.com/flac',
      qualityBadge: 'FLAC LOSSLESS',
      genre: 'Eclectic / Progressive Rock',
      description: 'Handcrafted mix of modern & classic rock, world music, electronica, and jazz.',
      badgeColor: Color(0xFF00E676),
    ),
    RadioStation(
      id: 'rp_mellow',
      name: 'Radio Paradise (Mellow Mix)',
      streamUrl: 'https://stream.radioparadise.com/mellow-flac',
      qualityBadge: 'FLAC LOSSLESS',
      genre: 'Ambient / Acoustic / Chill',
      description: 'Warm, relaxed listening with rich acoustic timbre and zero compression.',
      badgeColor: Color(0xFF00E676),
    ),
    RadioStation(
      id: 'rp_rock',
      name: 'Radio Paradise (Rock Mix)',
      streamUrl: 'https://stream.radioparadise.com/rock-flac',
      qualityBadge: 'FLAC LOSSLESS',
      genre: 'High Energy Rock',
      description: 'Energetic rock classics, indie rock, and alternative in full bit-perfect audio.',
      badgeColor: Color(0xFF00E5FF),
    ),
    RadioStation(
      id: 'linn_jazz',
      name: 'Linn Jazz (Studio Master)',
      streamUrl: 'http://radio.linn.co.uk:8000/autodj',
      qualityBadge: 'FLAC 24-BIT',
      genre: 'Audiophile Jazz',
      description: 'Pristine Scottish jazz recordings direct from Linn Records analog master tapes.',
      badgeColor: Color(0xFFFFD700),
    ),
    RadioStation(
      id: 'linn_classic',
      name: 'Linn Classical',
      streamUrl: 'http://radio.linn.co.uk:8003/autodj',
      qualityBadge: 'FLAC 24-BIT',
      genre: 'Orchestral / Symphonic',
      description: 'World-class orchestral, chamber, and choral recordings with full dynamic range.',
      badgeColor: Color(0xFFFFD700),
    ),
    RadioStation(
      id: 'somafm_groove',
      name: 'SomaFM: Groove Salad',
      streamUrl: 'https://ice2.somafm.com/groovesalad-256-mp3',
      qualityBadge: '320K MP3',
      genre: 'Downtempo / Chillout',
      description: 'A nicely chilled plate of ambient/downtempo beats and sonic ear-candy.',
      badgeColor: Color(0xFFFF9100),
    ),
    RadioStation(
      id: 'somafm_drone',
      name: 'SomaFM: Drone Zone',
      streamUrl: 'https://ice2.somafm.com/dronezone-256-mp3',
      qualityBadge: '320K MP3',
      genre: 'Atmospheric Space Music',
      description: 'Served best with headphones. Deep atmospheric music for meditation and focus.',
      badgeColor: Color(0xFF7C4DFF),
    ),
  ];

  Future<void> _playStation(BuildContext context, WidgetRef ref, RadioStation station) async {
    final track = station.toTrack();
    final isCasting = ref.read(isCastingActiveProvider);
    final castController = ref.read(castControllerProvider);

    if (isCasting) {
      await castController.playTrack(track, streamUrl: station.streamUrl);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Streaming "${station.name}" to ${castController.state.connectedDevice?.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      await ref.read(playerNotifierProvider.notifier).playTrack(track);
      if (context.mounted) {
        context.push(Routes.nowPlaying);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCasting = ref.watch(isCastingActiveProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        titleText: 'Audiophile Web Radio',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            key: const ValueKey('cast_picker_radio_button'),
            icon: Icon(
              isCasting ? Icons.cast_connected_rounded : Icons.cast_rounded,
              color: isCasting ? const Color(0xFF00E676) : Colors.white70,
            ),
            onPressed: () => CastDevicePickerModal.show(context),
          ),
        ],
      ),
      body: AppAmbientBackground(
        child: SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            itemCount: stations.length,
            itemBuilder: (context, index) {
              final station = stations[index];
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: GlassCard(
                  borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: InkWell(
                    key: ValueKey('radio_station_${station.id}'),
                    onTap: () => _playStation(context, ref, station),
                    borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: station.badgeColor.withOpacity(0.15),
                            border: Border.all(
                              color: station.badgeColor.withOpacity(0.35),
                            ),
                          ),
                          child: Icon(
                            Icons.radio_rounded,
                            color: station.badgeColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      station.name,
                                      style: AppTypography.titleSmall.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: station.badgeColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: station.badgeColor.withOpacity(0.4),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      station.qualityBadge,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: station.badgeColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                station.genre,
                                style: AppTypography.bodySmall.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                station.description,
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
