import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/dlna_av_transport_controller.dart';
import '../../data/services/upnp_ssdp_discovery_service.dart';
import '../../domain/models/cast_device.dart';
import '../../domain/models/cast_playback_state.dart';
import '../../domain/services/i_cast_controller.dart';
import '../../domain/services/i_cast_discovery_service.dart';

/// Provides the active SSDP discovery engine.
final castDiscoveryServiceProvider = Provider<ICastDiscoveryService>((ref) {
  final service = UpnpSsdpDiscoveryService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Reactive stream of discovered network speakers and DLNA renderers.
final castDiscoveredDevicesProvider = StreamProvider<List<CastDevice>>((ref) {
  final discovery = ref.watch(castDiscoveryServiceProvider);
  return discovery.devicesStream;
});

/// Provides the UPnP/DLNA AVTransport casting controller.
final castControllerProvider = Provider<ICastController>((ref) {
  final controller = DlnaAvTransportController();
  ref.onDispose(() {
    controller.dispose();
  });
  return controller;
});

/// Real-time playback and volume state of active casting session.
final castPlaybackStateProvider = StreamProvider<CastPlaybackState>((ref) {
  final controller = ref.watch(castControllerProvider);
  return controller.stateStream;
});

/// Active connected casting device, or null if disconnected.
final activeCastDeviceProvider = Provider<CastDevice?>((ref) {
  final castStateAsync = ref.watch(castPlaybackStateProvider);
  return castStateAsync.valueOrNull?.connectedDevice;
});

/// Whether the app is actively streaming or paused on a network renderer.
final isCastingActiveProvider = Provider<bool>((ref) {
  final castStateAsync = ref.watch(castPlaybackStateProvider);
  final status = castStateAsync.valueOrNull?.status;
  return status == CastPlaybackStatus.playing ||
      status == CastPlaybackStatus.buffering ||
      status == CastPlaybackStatus.paused;
});
