import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/features/playlists/presentation/providers/playlists_providers.dart';

/// Dialog allowing users to import standard M3U/M3U8 playlists into their library.
class M3uImportDialog extends ConsumerStatefulWidget {
  const M3uImportDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const M3uImportDialog(),
    );
  }

  @override
  ConsumerState<M3uImportDialog> createState() => _M3uImportDialogState();
}

class _M3uImportDialogState extends ConsumerState<M3uImportDialog> {
  final TextEditingController _nameController =
      TextEditingController(text: 'Imported Playlist');
  final TextEditingController _contentController = TextEditingController();
  bool _isImporting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleImport() async {
    final name = _nameController.text.trim();
    final content = _contentController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Please enter a playlist name');
      return;
    }
    if (content.isEmpty) {
      setState(() => _error = 'Please paste M3U playlist content');
      return;
    }

    setState(() {
      _isImporting = true;
      _error = null;
    });

    final m3u = ref.read(m3uServiceProvider);
    final res = await m3u.importM3u(name, content);

    if (mounted) {
      setState(() => _isImporting = false);
      if (res.isSuccess) {
        ref.invalidate(playlistsListNotifierProvider);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported playlist "$name" successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          _error = res.failureOrNull?.message ?? 'Failed to import playlist';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return AlertDialog(
      backgroundColor: const Color(0xFF141924),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      title: const Row(
        children: [
          Icon(Icons.file_download_outlined, color: Colors.tealAccent, size: 22),
          SizedBox(width: 10),
          Text(
            'Import M3U Playlist',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste or load standard M3U/M3U8 file contents to recreate the playlist.',
              style: TextStyle(fontSize: 12, color: Colors.white60),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'PLAYLIST NAME',
                labelStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                filled: true,
                fillColor: const Color(0xFF0F131D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: accent),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 6,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: '#EXTM3U\n#EXTINF:230,Daft Punk - Starboy\n/Music/Starboy.mp3',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                filled: true,
                fillColor: const Color(0xFF0F131D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: accent),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
          ),
        ),
        ElevatedButton(
          onPressed: _isImporting ? null : _handleImport,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isImporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Import'),
        ),
      ],
    );
  }
}
