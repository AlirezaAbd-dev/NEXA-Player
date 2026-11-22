import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/glass_tokens.dart';
import '../../../../shared/widgets/glass/app_ambient_background.dart';
import '../../../../shared/widgets/glass/glass_app_bar.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../domain/models/cast_playback_state.dart';
import '../../domain/models/network_server_config.dart';
import '../providers/cast_providers.dart';
import '../providers/cloud_settings_providers.dart';
import '../providers/network_servers_providers.dart';
import '../widgets/cast_device_picker_modal.dart';
import '../widgets/network_cache_quota_bar.dart';
import '../widgets/server_config_dialog.dart';

/// Master hub for DLNA/Chromecast casting, remote NAS/WebDAV server management, and audiophile web radio.
class CloudStreamingHubScreen extends ConsumerWidget {
  const CloudStreamingHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final castState = ref.watch(castPlaybackStateProvider).valueOrNull ?? const CastPlaybackState();
    final connectedDevice = castState.connectedDevice;
    final isCasting = ref.watch(isCastingActiveProvider);

    final serversAsync = ref.watch(networkServersListProvider);
    final servers = serversAsync.valueOrNull ?? [];
    final settings = ref.watch(cloudSettingsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        titleText: 'Cloud & Network Hub',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            key: const ValueKey('open_cast_picker_action'),
            icon: Icon(
              connectedDevice != null ? Icons.cast_connected_rounded : Icons.cast_rounded,
              color: connectedDevice != null ? const Color(0xFF00E676) : Colors.white70,
            ),
            tooltip: 'Cast Audio',
            onPressed: () => CastDevicePickerModal.show(context),
          ),
        ],
      ),
      body: AppAmbientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            children: [
              // 1. Casting Target Card
              GlassCard(
                borderRadius: BorderRadius.circular(GlassTokens.radiusLg),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (connectedDevice != null
                                ? const Color(0xFF00E676)
                                : colorScheme.primary)
                            .withOpacity(0.15),
                        border: Border.all(
                          color: (connectedDevice != null
                                  ? const Color(0xFF00E676)
                                  : colorScheme.primary)
                              .withOpacity(0.35),
                        ),
                      ),
                      child: Icon(
                        connectedDevice != null
                            ? Icons.cast_connected_rounded
                            : Icons.speaker_group_rounded,
                        color: connectedDevice != null
                            ? const Color(0xFF00E676)
                            : colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                connectedDevice != null ? 'Active Casting Target' : 'Audio Output',
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (isCasting) ...[
                                const SizedBox(width: AppSpacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E676).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'STREAMING',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: const Color(0xFF00E676),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            connectedDevice != null
                                ? '${connectedDevice.name} (${connectedDevice.host})'
                                : 'Local Device Audio (Phone Speaker / DAC)',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      key: const ValueKey('manage_cast_button'),
                      onPressed: () => CastDevicePickerModal.show(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(
                        connectedDevice != null ? 'Change' : 'Connect',
                        style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 2. Network Storage & NAS Servers Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'NETWORK STORAGE & SERVERS',
                    style: AppTypography.labelSmall.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  TextButton.icon(
                    key: const ValueKey('add_server_header_button'),
                    onPressed: () => ServerConfigDialog.show(context),
                    icon: Icon(Icons.add_rounded, size: 16, color: colorScheme.primary),
                    label: Text(
                      'Add Endpoint',
                      style: AppTypography.labelSmall.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              // Servers list
              if (servers.isEmpty)
                GlassCard(
                  borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      const Icon(Icons.dns_outlined, size: 36, color: Colors.white38),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'No Remote Servers Configured',
                        style: AppTypography.titleSmall.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Connect your Synology, QNAP, TrueNAS, or Nextcloud repository to stream lossless music directly over Wi-Fi.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...servers.map((server) => _buildServerTile(context, ref, server)),

              const SizedBox(height: AppSpacing.lg),

              // 3. Lossless Web Radio Banner
              GlassCard(
                borderRadius: BorderRadius.circular(GlassTokens.radiusLg),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: InkWell(
                  key: const ValueKey('open_web_radio_card'),
                  onTap: () => context.push(Routes.cloudRadio),
                  borderRadius: BorderRadius.circular(GlassTokens.radiusLg),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00E5FF).withOpacity(0.15),
                          border: Border.all(
                            color: const Color(0xFF00E5FF).withOpacity(0.35),
                          ),
                        ),
                        child: const Icon(
                          Icons.radio_rounded,
                          color: Color(0xFF00E5FF),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Audiophile Web Radio',
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E5FF).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'FLAC 24-BIT',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: const Color(0xFF00E5FF),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Radio Paradise, Linn Jazz, and curated broadcast streams',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 4. Cache & Streaming Settings
              Text(
                'STREAMING & CACHE ENGINE',
                style: AppTypography.labelSmall.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              const NetworkCacheQuotaBar(),
              const SizedBox(height: AppSpacing.sm),

              // Toggles Card
              GlassCard(
                borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                child: Column(
                  children: [
                    SwitchListTile(
                      key: const ValueKey('cloud_lossless_toggle'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Prefer Lossless FLAC/DSD',
                        style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Streams uncompressed master audio when available',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      value: settings.losslessStreaming,
                      activeColor: colorScheme.primary,
                      onChanged: (val) {
                        ref.read(cloudSettingsProvider.notifier).toggleLossless(val);
                      },
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    SwitchListTile(
                      key: const ValueKey('cloud_auto_discover_toggle'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Auto-Discover Cast Devices',
                        style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Background SSDP scanner for local DLNA speakers',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      value: settings.autoDiscoverCast,
                      activeColor: colorScheme.primary,
                      onChanged: (val) {
                        ref.read(cloudSettingsProvider.notifier).toggleAutoDiscoverCast(val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServerTile(BuildContext context, WidgetRef ref, NetworkServerConfig server) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: ListTile(
          key: ValueKey('server_tile_${server.id}'),
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
            ),
            child: Icon(
              server.type == NetworkServerType.nextcloud
                  ? Icons.cloud_rounded
                  : Icons.dns_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Text(
            server.name,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            '${server.type.name.toUpperCase()} • ${server.host}:${server.port}',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white60),
                color: const Color(0xFF1E2430),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 16, color: Colors.white70),
                        SizedBox(width: 8),
                        Text('Edit', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
                onSelected: (val) {
                  if (val == 'edit') {
                    ServerConfigDialog.show(context, initialConfig: server);
                  } else if (val == 'delete') {
                    ref.read(networkServersRepositoryProvider).deleteServer(server.id);
                  }
                },
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white38),
            ],
          ),
          onTap: () {
            ref.read(selectedServerIdProvider.notifier).state = server.id;
            ref.read(currentRemotePathProvider.notifier).state = server.path;
            context.push('${Routes.cloudBrowse}?serverId=${server.id}');
          },
        ),
      ),
    );
  }
}
