import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../providers/auto_providers.dart';

/// Dedicated configuration screen for Android Auto, Car Mode driving HUD, and Wear OS companion.
class AutoWearableSettingsScreen extends ConsumerWidget {
  const AutoWearableSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(autoSettingsProvider);
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFF090D14),
      appBar: AppBar(
        title: const Text('Auto & Wearables'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: nexaScrollPadding(context, horizontal: 16.0, top: 12.0),
        children: [
          // 1. In-App Car Mode Banner & Launcher
          InkWell(
            onTap: () => context.push(AppRoutes.carMode),
            borderRadius: BorderRadius.circular(16.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withOpacity(0.20),
                    const Color(0xFF121927),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: accent.withOpacity(0.40)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.directions_car_rounded,
                      color: accent,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Launch Car Mode HUD',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Distraction-free oversized controls for car cradle',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 2. In-App Car Driving Mode Preferences
          _buildSectionHeader('CAR MODE SETTINGS'),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F1420),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Keep Screen Awake',
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    'Prevent device screen from turning off while in Car Mode',
                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
                  ),
                  value: settings.keepScreenAwake,
                  activeColor: accent,
                  onChanged: (val) {
                    ref.read(autoSettingsProvider.notifier).toggleKeepScreenAwake(val);
                  },
                ),
                const Divider(color: Colors.white10, height: 1),
                SwitchListTile(
                  title: const Text('Oversized 72dp Buttons',
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    'Enlarge tap targets to prevent accidental mis-taps while driving',
                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
                  ),
                  value: settings.largeButtons,
                  activeColor: accent,
                  onChanged: (val) {
                    ref.read(autoSettingsProvider.notifier).toggleLargeButtons(val);
                  },
                ),
                const Divider(color: Colors.white10, height: 1),
                SwitchListTile(
                  title: const Text('Bluetooth Car Auto-Launch',
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    'Automatically open Car Mode when paired with car audio Bluetooth',
                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
                  ),
                  value: settings.bluetoothAutoLaunch,
                  activeColor: accent,
                  onChanged: (val) {
                    ref.read(autoSettingsProvider.notifier).toggleBluetoothAutoLaunch(val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. Android Auto / Automotive OS Integration
          _buildSectionHeader('ANDROID AUTO & INFOTAINMENT'),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F1420),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Android Auto MediaBrowser',
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    'Expose library, playlists, and voice search to car head unit',
                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
                  ),
                  value: settings.androidAutoEnabled,
                  activeColor: accent,
                  onChanged: (val) {
                    ref.read(autoSettingsProvider.notifier).toggleAndroidAuto(val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 4. Wear OS & Smartwatches
          _buildSectionHeader('WEAR OS & SMARTWATCHES'),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F1420),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Wear OS Companion Sync',
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    'Broadcast real-time playback & rotary crown scrubbing to watches',
                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
                  ),
                  value: settings.wearCompanionEnabled,
                  activeColor: accent,
                  onChanged: (val) {
                    ref.read(autoSettingsProvider.notifier).toggleWearCompanion(val);
                  },
                ),
                const Divider(color: Colors.white10, height: 1),
                ListTile(
                  title: const Text('Preview Smartwatch Hub',
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    'Test circular bezel rotary scrubber and compact controls',
                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: Colors.white54),
                  onTap: () => context.push(AppRoutes.wear),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(
          fontSize: 11,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
          color: Colors.white60,
        ),
      ),
    );
  }
}
