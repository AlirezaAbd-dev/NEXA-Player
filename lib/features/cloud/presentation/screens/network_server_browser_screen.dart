import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../shared/widgets/glass/app_ambient_background.dart';
import '../../../../shared/widgets/glass/glass_app_bar.dart';
import '../../../player/presentation/providers/player_providers.dart';
import '../../domain/models/network_server_config.dart';
import '../../domain/models/remote_media_item.dart';
import '../providers/cast_providers.dart';
import '../providers/network_servers_providers.dart';
import '../widgets/cast_device_picker_modal.dart';
import '../widgets/remote_file_tile.dart';

/// Interactive file manager and audio streamer for exploring remote WebDAV and NAS directories.
class NetworkServerBrowserScreen extends ConsumerStatefulWidget {
  const NetworkServerBrowserScreen({super.key, required this.serverId});

  final String serverId;

  @override
  ConsumerState<NetworkServerBrowserScreen> createState() =>
      _NetworkServerBrowserScreenState();
}

class _NetworkServerBrowserScreenState
    extends ConsumerState<NetworkServerBrowserScreen> {
  late String _currentPath;
  final Map<String, double> _downloadingProgress = {};

  @override
  void initState() {
    super.initState();
    _currentPath = ref.read(currentRemotePathProvider);
  }

  void _navigateToDirectory(String path) {
    setState(() {
      _currentPath = path;
    });
    ref.read(currentRemotePathProvider.notifier).state = path;
  }

  void _navigateUp() {
    if (_currentPath == '/' || _currentPath.isEmpty) {
      context.pop();
      return;
    }

    final trimmed = _currentPath.endsWith('/')
        ? _currentPath.substring(0, _currentPath.length - 1)
        : _currentPath;
    final lastSlash = trimmed.lastIndexOf('/');
    if (lastSlash <= 0) {
      _navigateToDirectory('/');
    } else {
      _navigateToDirectory(trimmed.substring(0, lastSlash));
    }
  }

  Future<void> _handleTrackTap(
    NetworkServerConfig server,
    RemoteMediaItem item,
    List<RemoteMediaItem> allItems,
  ) async {
    final client = ref.read(networkStorageClientProvider);
    final cacheManager = ref.read(networkCacheManagerProvider);
    final castController = ref.read(castControllerProvider);
    final isCasting = ref.read(isCastingActiveProvider);

    // Check if track is cached locally
    final cachedPath = await cacheManager.getCachedPath(item);
    final effectiveItem = cachedPath != null
        ? item.copyWith(isCached: true, cachedLocalPath: cachedPath)
        : item;

    final streamUrl = client.getStreamUrl(server: server, item: effectiveItem);
    final track = effectiveItem.toTrack(streamUrl: streamUrl);

    if (isCasting) {
      await castController.playTrack(track, streamUrl: streamUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Streaming "${track.title}" to ${castController.state.connectedDevice?.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Build playlist of all audio items in current folder
      final audioItems = allItems.where((i) => !i.isDirectory).toList();
      final playlist = audioItems.map((ai) {
        final u = client.getStreamUrl(server: server, item: ai);
        return ai.toTrack(streamUrl: u);
      }).toList();

      final idx = playlist.indexWhere((t) => t.id == track.id);
      await ref.read(playerNotifierProvider.notifier).playTrack(
            track,
            queue: playlist,
            initialIndex: idx != -1 ? idx : 0,
          );
      if (mounted) {
        context.push(Routes.nowPlaying);
      }
    }
  }

  Future<void> _downloadTrack(NetworkServerConfig server, RemoteMediaItem item) async {
    if (item.isCached) return;

    setState(() {
      _downloadingProgress[item.id] = 0.05;
    });

    final client = ref.read(networkStorageClientProvider);
    final cacheManager = ref.read(networkCacheManagerProvider);
    final streamUrl = client.getStreamUrl(server: server, item: item);
    final headers = client.getAuthHeaders(server);

    try {
      await cacheManager.cacheTrack(
        item: item,
        streamUrl: streamUrl,
        headers: headers,
        onProgress: (prog) {
          if (mounted) {
            setState(() {
              _downloadingProgress[item.id] = prog;
            });
          }
        },
      );
      ref.invalidate(networkCacheSizeBytesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cache track: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingProgress.remove(item.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final serversAsync = ref.watch(networkServersListProvider);
    final servers = serversAsync.valueOrNull ?? [];
    final server = servers.cast<NetworkServerConfig?>().firstWhere(
          (s) => s?.id == widget.serverId,
          orElse: () => null,
        );

    if (server == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: GlassAppBar(
          titleText: 'Server Not Found',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Text('The specified network storage server does not exist.',
              style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    final queryParams = (server: server, path: _currentPath);
    final directoryAsync = ref.watch(remoteDirectoryItemsProvider(queryParams));
    final isCasting = ref.watch(isCastingActiveProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        titleText: server.name,
        leading: IconButton(
          key: const ValueKey('navigate_up_button'),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: _navigateUp,
        ),
        actions: [
          IconButton(
            key: const ValueKey('cast_picker_browser_button'),
            icon: Icon(
              isCasting ? Icons.cast_connected_rounded : Icons.cast_rounded,
              color: isCasting ? const Color(0xFF00E676) : Colors.white70,
            ),
            onPressed: () => CastDevicePickerModal.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: () => ref.invalidate(remoteDirectoryItemsProvider(queryParams)),
          ),
        ],
      ),
      body: AppAmbientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Breadcrumb path header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                color: Colors.black.withOpacity(0.3),
                child: Row(
                  children: [
                    const Icon(Icons.folder_shared_rounded, size: 16, color: Colors.white54),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _currentPath.isEmpty ? '/' : _currentPath,
                        style: AppTypography.bodySmall.copyWith(
                          fontFamily: 'monospace',
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Directory contents
              Expanded(
                child: directoryAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (err, stack) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.redAccent),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Failed to read remote directory',
                            style: AppTypography.titleSmall.copyWith(color: Colors.white)),
                        const SizedBox(height: AppSpacing.xs),
                        Text('$err',
                            style: AppTypography.bodySmall.copyWith(color: Colors.white54)),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton.icon(
                          onPressed: () => ref.invalidate(remoteDirectoryItemsProvider(queryParams)),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.folder_open_rounded, size: 48, color: Colors.white24),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Directory is empty or contains no supported audio files',
                              style: AppTypography.bodyMedium.copyWith(color: Colors.white60),
                            ),
                          ],
                        ),
                      );
                    }

                    final audioTracks = items.where((i) => !i.isDirectory).toList();

                    return ListView.builder(
                      padding: nexaScrollPadding(
                        context,
                        horizontal: AppSpacing.md,
                        top: AppSpacing.sm,
                      ),
                      itemCount: items.length + (audioTracks.isNotEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Header play all action
                        if (audioTracks.isNotEmpty && index == 0) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    key: const ValueKey('play_all_folder_button'),
                                    onPressed: () => _handleTrackTap(server, audioTracks.first, items),
                                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                                    label: Text('Play Folder (${audioTracks.length})'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: colorScheme.onPrimary,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final itemIndex = audioTracks.isNotEmpty ? index - 1 : index;
                        final item = items[itemIndex];
                        final isDownloading = _downloadingProgress.containsKey(item.id);
                        final downloadProg = _downloadingProgress[item.id] ?? 0.0;

                        return RemoteFileTile(
                          item: item,
                          isDownloading: isDownloading,
                          downloadProgress: downloadProg,
                          onTap: () {
                            if (item.isDirectory) {
                              _navigateToDirectory(item.remotePath);
                            } else {
                              _handleTrackTap(server, item, items);
                            }
                          },
                          onDownloadTap: item.isDirectory
                              ? null
                              : () => _downloadTrack(server, item),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
