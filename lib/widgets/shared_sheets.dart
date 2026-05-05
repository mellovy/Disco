import 'package:flutter/material.dart';
import '../pixel_colors.dart';
import '../models/song.dart';
import '../services/db_service.dart';

/// Shared pixel-style playlist bottom sheet used across the app.
class PixelPlaylistSheet extends StatefulWidget {
  final Song song;
  final int userId;
  final List<dynamic> playlists;
  final bool isDark;
  const PixelPlaylistSheet({
    super.key,
    required this.song,
    required this.userId,
    required this.playlists,
    required this.isDark,
  });
  @override
  State<PixelPlaylistSheet> createState() => _PixelPlaylistSheetState();
}

class _PixelPlaylistSheetState extends State<PixelPlaylistSheet> {
  late List<dynamic> _playlists;
  bool _creating = false;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _playlists = widget.playlists;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _addToPlaylist(int id, String name) async {
    final ok = await DBService.addSongToPlaylist(
        playlistId: id, songId: widget.song.id);
    if (!mounted) return;
    Navigator.pop(context);
    if (ok) {
      DBService.notifyPlaylistRefresh();
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? '${widget.song.title} added to $name' : 'Failed',
          style: const TextStyle(fontFamily: 'monospace')),
    ));
  }

  Future<void> _createAndAdd() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _creating = true);
    final pid =
        await DBService.createPlaylist(userId: widget.userId, name: name);
    if (!mounted) return;
    if (pid != null) {
      await _addToPlaylist(pid, name);
    } else {
      setState(() => _creating = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create playlist')));
    }
  }

  void _showDialog() {
    final accent =
        widget.isDark ? PixelColors.neonPink : PixelColors.accentPink;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            widget.isDark ? PixelColors.darkCard : PixelColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: accent, width: 2),
        ),
        title: Text('NEW PLAYLIST',
            style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: accent)),
        content: TextField(
          controller: _ctrl,
          autofocus: true,
          style: TextStyle(
              fontFamily: 'monospace',
              color: widget.isDark ? Colors.white : PixelColors.darkBg),
          decoration: InputDecoration(
            hintText: 'PLAYLIST NAME',
            hintStyle: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            filled: true,
            fillColor: widget.isDark
                ? PixelColors.darkSurface
                : PixelColors.lightCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: accent, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL',
                  style: TextStyle(fontFamily: 'monospace', letterSpacing: 1))),
          GestureDetector(
            onTap: _creating
                ? null
                : () {
                    Navigator.pop(ctx);
                    _createAndAdd();
                  },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: accent,
              child: const Text('CREATE & ADD',
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent =
        widget.isDark ? PixelColors.neonPink : PixelColors.accentPink;
    final bg =
        widget.isDark ? PixelColors.darkSurface : PixelColors.lightSurface;
    final border =
        widget.isDark ? PixelColors.darkBorder : PixelColors.lightBorder;
    final textPrimary = widget.isDark ? Colors.white : PixelColors.darkBg;
    final cardColor =
        widget.isDark ? PixelColors.darkCard : PixelColors.lightCard;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: accent, width: 3)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 18, color: accent),
              const SizedBox(width: 8),
              Text('ADD TO PLAYLIST',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: accent,
                      letterSpacing: 2,
                      fontFamily: 'monospace')),
            ],
          ),
          const SizedBox(height: 4),
          Text(widget.song.title,
              style: TextStyle(
                  color: border, fontSize: 11, fontFamily: 'monospace')),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _showDialog,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cardColor,
                border: Border.all(color: accent, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: accent.withOpacity(0.3),
                      blurRadius: 0,
                      offset: const Offset(3, 3))
                ],
              ),
              child: Row(children: [
                Icon(Icons.add, color: accent, size: 18),
                const SizedBox(width: 10),
                Text('CREATE NEW PLAYLIST',
                    style: TextStyle(
                        color: accent,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        fontSize: 11)),
              ]),
            ),
          ),
          if (_playlists.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('YOUR PLAYLISTS',
                style: TextStyle(
                    color: border,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontFamily: 'monospace')),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _playlists.length,
                itemBuilder: (context, i) {
                  final pl = _playlists[i];
                  final id = pl['playlist_id'] ?? pl['id'];
                  final name = pl['name'] ?? 'Untitled';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: cardColor,
                      border: Border.all(color: border, width: 2),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      leading:
                          Icon(Icons.playlist_play, color: accent, size: 24),
                      title: Text(name,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              fontSize: 12,
                              letterSpacing: 0.5,
                              color: textPrimary)),
                      trailing: Icon(Icons.add_circle_outline,
                          color: accent, size: 20),
                      onTap: () => _addToPlaylist(
                          id is int ? id : int.parse(id.toString()), name),
                    ),
                  );
                },
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('NO PLAYLISTS YET',
                    style: TextStyle(
                        color: border,
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                        fontSize: 10)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Shared pixel-style song thumbnail placeholder.
Widget pixelThumb(Color accent, {double size = 50}) {
  return Container(
    width: size,
    height: size,
    color: accent.withOpacity(0.1),
    child: Icon(Icons.music_note, color: accent, size: size * 0.5),
  );
}
