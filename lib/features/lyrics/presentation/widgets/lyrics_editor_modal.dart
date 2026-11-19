import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/features/lyrics/domain/models/lyrics.dart';
import 'package:nexa_player/features/lyrics/domain/models/lyrics_source.dart';
import 'package:nexa_player/features/lyrics/domain/services/lrc_parser.dart';
import 'package:nexa_player/features/lyrics/presentation/providers/lyrics_providers.dart';
import 'package:nexa_player/shared/models/track.dart';

/// Modal bottom sheet allowing users to view, manually edit, paste,
/// or re-fetch lyrics for a [track].
class LyricsEditorModal extends ConsumerStatefulWidget {
  const LyricsEditorModal({
    super.key,
    required this.track,
    this.initialLyrics,
  });

  final Track track;
  final Lyrics? initialLyrics;

  static Future<void> show(
    BuildContext context, {
    required Track track,
    Lyrics? currentLyrics,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LyricsEditorModal(
        track: track,
        initialLyrics: currentLyrics,
      ),
    );
  }

  @override
  ConsumerState<LyricsEditorModal> createState() => _LyricsEditorModalState();
}

class _LyricsEditorModalState extends ConsumerState<LyricsEditorModal> {
  late final TextEditingController _controller;
  bool _saveToLrcFile = false;
  bool _isSaving = false;
  bool _isFetchingOnline = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    final initialText = widget.initialLyrics?.rawLrc ??
        widget.initialLyrics?.plainLyrics ??
        '';
    _controller = TextEditingController(text: initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _statusMessage = 'Lyrics cannot be completely empty.');
      return;
    }

    setState(() {
      _isSaving = true;
      _statusMessage = null;
    });

    const parser = LrcParser();
    final parsed = parser.parse(
      text,
      trackId: widget.track.id,
      source: LyricsSource.manual,
    );

    final service = ref.read(lyricsServiceProvider);
    final res = await service.saveLyrics(
      widget.track,
      parsed,
      saveToLrcFile: _saveToLrcFile,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (res.isSuccess) {
        ref.invalidate(trackLyricsProvider(widget.track));
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lyrics saved successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          _statusMessage = res.failureOrNull?.message ?? 'Failed to save lyrics.';
        });
      }
    }
  }

  Future<void> _handleFetchOnline() async {
    setState(() {
      _isFetchingOnline = true;
      _statusMessage = null;
    });

    final service = ref.read(lyricsServiceProvider);
    final res = await service.fetchOnlineLyrics(widget.track);

    if (mounted) {
      setState(() => _isFetchingOnline = false);
      if (res.isSuccess && res.valueOrNull != null) {
        final onlineLyrics = res.valueOrNull!;
        final text = onlineLyrics.rawLrc ?? onlineLyrics.plainLyrics ?? '';
        _controller.text = text;
        setState(() {
          _statusMessage = 'Fetched online lyrics from LRCLIB (${onlineLyrics.lines.length} lines).';
        });
      } else {
        setState(() {
          _statusMessage = 'No lyrics found online for "${widget.track.title}".';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0D111A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lyrics Editor',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      widget.track.title,
                      style: TextStyle(
                        fontSize: 12,
                        color: accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _isFetchingOnline ? null : _handleFetchOnline,
                  icon: _isFetchingOnline
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_download_rounded, size: 16),
                  label: const Text('Fetch LRCLIB'),
                  style: TextButton.styleFrom(
                    foregroundColor: accent,
                    backgroundColor: accent.withOpacity(0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_statusMessage != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                _statusMessage!,
                style: TextStyle(
                  color: _statusMessage!.contains('Failed') || _statusMessage!.contains('cannot')
                      ? Colors.redAccent
                      : Colors.tealAccent,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Paste standard LRC format e.g.:\n[00:15.20] First lyric line\n[00:20.50] Second lyric line',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.25),
                    fontFamily: 'monospace',
                  ),
                  filled: true,
                  fillColor: const Color(0xFF131824),
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accent),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (widget.track.filePath != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CheckboxListTile(
                value: _saveToLrcFile,
                onChanged: (val) => setState(() => _saveToLrcFile = val ?? false),
                title: const Text(
                  'Also save as companion .lrc file on device',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                dense: true,
                activeColor: accent,
                checkColor: Colors.black,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.check_rounded),
                label: const Text('Save Lyrics', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
