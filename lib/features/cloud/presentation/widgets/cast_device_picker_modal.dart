import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/glass_tokens.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../domain/models/cast_device.dart';
import '../../domain/models/cast_playback_state.dart';
import '../providers/cast_providers.dart';

/// Modal bottom sheet for discovering, connecting to, and controlling UPnP/DLNA audio renderers.
class CastDevicePickerModal extends ConsumerStatefulWidget {
  const CastDevicePickerModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CastDevicePickerModal(),
    );
  }

  @override
  ConsumerState<CastDevicePickerModal> createState() => _CastDevicePickerModalState();
}

class _CastDevicePickerModalState extends ConsumerState<CastDevicePickerModal> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _triggerScan();
  }

  Future<void> _triggerScan() async {
    setState(() => _isRefreshing = true);
    final discovery = ref.read(castDiscoveryServiceProvider);
    await discovery.startDiscovery(timeout: const Duration(seconds: 4));
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final devicesAsync = ref.watch(castDiscoveredDevicesProvider);
    final castStateAsync = ref.watch(castPlaybackStateProvider);
    final castState = castStateAsync.valueOrNull ?? const CastPlaybackState();
    final connectedDevice = castState.connectedDevice;

    final devices = devicesAsync.valueOrNull ??
        ref.read(castDiscoveryServiceProvider).currentDevices;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0D14).withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.25),
          width: 1.0,
        ),
      ),
      padding: EdgeInsets.only(
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withOpacity(0.15),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Icon(
                  Icons.cast_connected_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cast to Network Audio',
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      connectedDevice != null
                          ? 'Connected to ${connectedDevice.name}'
                          : 'Select a DLNA or Chromecast receiver',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const ValueKey('refresh_cast_devices_button'),
                icon: _isRefreshing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, color: Colors.white70),
                onPressed: _isRefreshing ? null : _triggerScan,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Active cast volume & playback controls (if connected)
          if (connectedDevice != null) ...[
            GlassCard(
              borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF00E676),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF00E676),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          connectedDevice.name,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        key: const ValueKey('disconnect_cast_button'),
                        onPressed: () async {
                          final controller = ref.read(castControllerProvider);
                          await controller.disconnect();
                        },
                        icon: const Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                        label: Text(
                          'Disconnect',
                          style: AppTypography.labelSmall.copyWith(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(Icons.volume_down_rounded, size: 18, color: Colors.white70),
                      Expanded(
                        child: Slider(
                          key: const ValueKey('cast_volume_slider'),
                          value: castState.volume,
                          onChanged: (val) {
                            final controller = ref.read(castControllerProvider);
                            controller.setVolume(val);
                          },
                          activeColor: colorScheme.primary,
                          inactiveColor: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      const Icon(Icons.volume_up_rounded, size: 18, color: Colors.white70),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Discovered devices list
          Text(
            'AVAILABLE SPEAKERS (${devices.length})',
            style: AppTypography.labelSmall.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          if (devices.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(
                    Icons.speaker_group_outlined,
                    size: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'No network speakers detected yet',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Ensure your DLNA renderer is powered on and connected to this Wi-Fi network.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            )
          else
            ...devices.map((device) {
              final isThisConnected = connectedDevice?.id == device.id;
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: ListTile(
                  key: ValueKey('cast_device_tile_${device.id}'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
                    side: BorderSide(
                      color: isThisConnected
                          ? colorScheme.primary.withOpacity(0.5)
                          : Colors.white.withOpacity(0.05),
                    ),
                  ),
                  tileColor: isThisConnected
                      ? colorScheme.primary.withOpacity(0.1)
                      : Colors.white.withOpacity(0.03),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isThisConnected
                          ? colorScheme.primary.withOpacity(0.2)
                          : Colors.white.withOpacity(0.08),
                    ),
                    child: Icon(
                      device.serviceType == CastServiceType.chromecast
                          ? Icons.cast_rounded
                          : Icons.speaker_rounded,
                      color: isThisConnected ? colorScheme.primary : Colors.white70,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    device.name,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: isThisConnected ? FontWeight.bold : FontWeight.normal,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    '${device.serviceType.name.toUpperCase()} • ${device.host}',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  trailing: isThisConnected
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Active',
                            style: AppTypography.labelSmall.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                  onTap: () async {
                    final controller = ref.read(castControllerProvider);
                    if (isThisConnected) {
                      await controller.disconnect();
                    } else {
                      await controller.connect(device);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    }
                  },
                ),
              );
            }),
        ],
      ),
    );
  }
}
