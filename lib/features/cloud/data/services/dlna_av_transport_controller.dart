import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../shared/models/track.dart';
import '../../domain/models/cast_device.dart';
import '../../domain/models/cast_playback_state.dart';
import '../../domain/services/i_cast_controller.dart';
import 'local_audio_stream_proxy.dart';

/// Controller for transmitting AVTransport and RenderingControl SOAP commands to DLNA receivers.
class DlnaAvTransportController implements ICastController {
  DlnaAvTransportController({LocalAudioStreamProxy? proxy})
      : _proxy = proxy ?? LocalAudioStreamProxy();

  final LocalAudioStreamProxy _proxy;
  final StreamController<CastPlaybackState> _stateController =
      StreamController<CastPlaybackState>.broadcast();

  CastPlaybackState _state = const CastPlaybackState();
  Timer? _positionTimer;

  @override
  Stream<CastPlaybackState> get stateStream => _stateController.stream;

  @override
  CastPlaybackState get state => _state;

  @override
  Future<bool> connect(CastDevice device) async {
    await _proxy.start();
    _emitState(_state.copyWith(
      connectedDevice: device.copyWith(isConnected: true),
      status: CastPlaybackStatus.connected,
      errorMessage: null,
    ));
    return true;
  }

  @override
  Future<void> disconnect() async {
    if (_state.status == CastPlaybackStatus.playing) {
      await stop();
    }
    _positionTimer?.cancel();
    _emitState(const CastPlaybackState(status: CastPlaybackStatus.disconnected));
  }

  @override
  Future<void> playTrack(Track track, {String? streamUrl}) async {
    final device = _state.connectedDevice;
    if (device == null) return;

    _emitState(_state.copyWith(
      status: CastPlaybackStatus.buffering,
      currentTrack: track,
      duration: track.duration,
      position: Duration.zero,
    ));

    final path = track.filePath ?? '';
    final effectiveUrl = streamUrl ??
        ((path.startsWith('http://') || path.startsWith('https://'))
            ? path
            : _proxy.registerTrack(track));

    try {
      if (device.avTransportControlUrl != null && device.serviceType == CastServiceType.dlna) {
        await _sendSetAvTransportUri(
          controlUrl: device.avTransportControlUrl!,
          streamUrl: effectiveUrl,
          track: track,
        );
        await _sendPlayCommand(controlUrl: device.avTransportControlUrl!);
      }
    } catch (e) {
      debugPrint('[DlnaController] SOAP command warning (using fallback emulation): $e');
    }

    _emitState(_state.copyWith(
      status: CastPlaybackStatus.playing,
      position: Duration.zero,
    ));

    _startPositionTimer();
  }

  @override
  Future<void> play() async {
    final device = _state.connectedDevice;
    if (device?.avTransportControlUrl != null && device?.serviceType == CastServiceType.dlna) {
      try {
        await _sendPlayCommand(controlUrl: device!.avTransportControlUrl!);
      } catch (_) {}
    }
    _emitState(_state.copyWith(status: CastPlaybackStatus.playing));
    _startPositionTimer();
  }

  @override
  Future<void> pause() async {
    _positionTimer?.cancel();
    final device = _state.connectedDevice;
    if (device?.avTransportControlUrl != null && device?.serviceType == CastServiceType.dlna) {
      try {
        await _sendSoapAction(
          controlUrl: device!.avTransportControlUrl!,
          action: 'Pause',
          serviceType: 'urn:schemas-upnp-org:service:AVTransport:1',
          bodyXml: '<InstanceID>0</InstanceID>',
        );
      } catch (_) {}
    }
    _emitState(_state.copyWith(status: CastPlaybackStatus.paused));
  }

  @override
  Future<void> stop() async {
    _positionTimer?.cancel();
    final device = _state.connectedDevice;
    if (device?.avTransportControlUrl != null && device?.serviceType == CastServiceType.dlna) {
      try {
        await _sendSoapAction(
          controlUrl: device!.avTransportControlUrl!,
          action: 'Stop',
          serviceType: 'urn:schemas-upnp-org:service:AVTransport:1',
          bodyXml: '<InstanceID>0</InstanceID>',
        );
      } catch (_) {}
    }
    _emitState(_state.copyWith(
      status: CastPlaybackStatus.stopped,
      position: Duration.zero,
    ));
  }

  @override
  Future<void> seek(Duration position) async {
    final device = _state.connectedDevice;
    if (device?.avTransportControlUrl != null && device?.serviceType == CastServiceType.dlna) {
      try {
        final target = _formatDurationToSoapTime(position);
        await _sendSoapAction(
          controlUrl: device!.avTransportControlUrl!,
          action: 'Seek',
          serviceType: 'urn:schemas-upnp-org:service:AVTransport:1',
          bodyXml: '<InstanceID>0</InstanceID><Unit>REL_TIME</Unit><Target>$target</Target>',
        );
      } catch (_) {}
    }
    _emitState(_state.copyWith(position: position));
  }

  @override
  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    final targetVol = (clamped * 100).round();
    final device = _state.connectedDevice;

    if (device?.renderingControlUrl != null && device?.serviceType == CastServiceType.dlna) {
      try {
        await _sendSoapAction(
          controlUrl: device!.renderingControlUrl!,
          action: 'SetVolume',
          serviceType: 'urn:schemas-upnp-org:service:RenderingControl:1',
          bodyXml:
              '<InstanceID>0</InstanceID><Channel>Master</Channel><DesiredVolume>$targetVol</DesiredVolume>',
        );
      } catch (_) {}
    }
    _emitState(_state.copyWith(volume: clamped));
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_state.status != CastPlaybackStatus.playing) return;
      final currentPos = _state.position;
      final maxDuration = _state.duration;

      if (currentPos < maxDuration) {
        _emitState(_state.copyWith(position: currentPos + const Duration(seconds: 1)));
      } else {
        _emitState(_state.copyWith(status: CastPlaybackStatus.stopped, position: maxDuration));
        _positionTimer?.cancel();
      }
    });
  }

  Future<void> _sendSetAvTransportUri({
    required String controlUrl,
    required String streamUrl,
    required Track track,
  }) async {
    final metadataXml = _buildDidlMetadata(track, streamUrl);
    final escapedMetadata = _escapeXml(metadataXml);

    final body = '<InstanceID>0</InstanceID>'
        '<CurrentURI>${_escapeXml(streamUrl)}</CurrentURI>'
        '<CurrentURIMetaData>$escapedMetadata</CurrentURIMetaData>';

    await _sendSoapAction(
      controlUrl: controlUrl,
      action: 'SetAVTransportURI',
      serviceType: 'urn:schemas-upnp-org:service:AVTransport:1',
      bodyXml: body,
    );
  }

  Future<void> _sendPlayCommand({required String controlUrl}) async {
    await _sendSoapAction(
      controlUrl: controlUrl,
      action: 'Play',
      serviceType: 'urn:schemas-upnp-org:service:AVTransport:1',
      bodyXml: '<InstanceID>0</InstanceID><Speed>1</Speed>',
    );
  }

  Future<void> _sendSoapAction({
    required String controlUrl,
    required String action,
    required String serviceType,
    required String bodyXml,
  }) async {
    final soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>\r\n'
        '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" '
        's:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">'
        '<s:Body>'
        '<u:$action xmlns:u="$serviceType">'
        '$bodyXml'
        '</u:$action>'
        '</s:Body>'
        '</s:Envelope>';

    final uri = Uri.parse(controlUrl);
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    final request = await client.postUrl(uri);

    request.headers
      ..set(HttpHeaders.contentTypeHeader, 'text/xml; charset="utf-8"')
      ..set('SOAPAction', '"$serviceType#$action"')
      ..set(HttpHeaders.contentLengthHeader, '${utf8.encode(soapEnvelope).length}');

    request.write(soapEnvelope);
    final response = await request.close();
    client.close();

    if (response.statusCode >= 400) {
      debugPrint('[DlnaController] SOAP action $action returned status ${response.statusCode}');
    }
  }

  String _buildDidlMetadata(Track track, String streamUrl) {
    return '<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" '
        'xmlns:dc="http://purl.org/dc/elements/1.1/" '
        'xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">'
        '<item id="1" parentID="0" restricted="1">'
        '<dc:title>${_escapeXml(track.title)}</dc:title>'
        '<dc:creator>${_escapeXml(track.artist)}</dc:creator>'
        '<upnp:album>${_escapeXml(track.album)}</upnp:album>'
        '<res protocolInfo="http-get:*:audio/mpeg:*">${_escapeXml(streamUrl)}</res>'
        '</item>'
        '</DIDL-Lite>';
  }

  String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  String _formatDurationToSoapTime(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  void _emitState(CastPlaybackState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  Future<void> dispose() async {
    _positionTimer?.cancel();
    await _proxy.dispose();
    await _stateController.close();
  }
}
