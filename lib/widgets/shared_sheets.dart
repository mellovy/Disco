import 'package:flutter/material.dart';
import '../pixel_colors.dart';
import '../models/song.dart';
import '../services/db_service.dart';
import '../services/audio_manager.dart';

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



/// Shared pixel section label used across the app.
class PixelSectionLabel extends StatelessWidget {
  final String text;
  final Color accent;
  const PixelSectionLabel(this.text, {required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 18, color: accent),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: accent,
            letterSpacing: 2,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

/// Shared pixel-style song popup menu used across the app.
class PixelSongMenu extends StatefulWidget {
  final Song song;
  final bool hasOngoingQueue;
  final int userId;
  final Color accent;
  final Color textPrimary;
  final Color cardColor;
  final VoidCallback onAddToPlaylist;

  const PixelSongMenu({
    required this.song,
    required this.hasOngoingQueue,
    required this.userId,
    required this.accent,
    required this.textPrimary,
    required this.cardColor,
    required this.onAddToPlaylist,
  });

  @override
  State<PixelSongMenu> createState() => _PixelSongMenuState();
}

class _PixelSongMenuState extends State<PixelSongMenu> {
  bool _toggling = false;

  Future<void> _toggleFavorite() async {
    if (_toggling) return;
    setState(() {
      _toggling = true;
      widget.song.isFavorite = !widget.song.isFavorite;
    });
    final success = await DBService.toggleFavorite(widget.userId, widget.song.id);
    if (!mounted) return;
    if (!success) {
      setState(() => widget.song.isFavorite = !widget.song.isFavorite);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update favorite')),
      );
    } else {
      DBService.notifyPlaylistRefresh();
    }
    setState(() => _toggling = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert,
          color: widget.accent.withOpacity(0.6), size: 20),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      color: widget.cardColor,
      onSelected: (value) {
        if (value == 'queue') {
          AudioManager.instance.addToQueue(widget.song);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${widget.song.title} added to queue',
                style: const TextStyle(fontFamily: 'monospace')),
            duration: const Duration(seconds: 1),
          ));
        } else if (value == 'playlist') {
          widget.onAddToPlaylist();
        } else if (value == 'favorite') {
          _toggleFavorite();
        }
      },
      itemBuilder: (_) => [
        if (widget.hasOngoingQueue)
          PopupMenuItem(
            value: 'queue',
            child: Row(children: [
              Icon(Icons.playlist_add, color: widget.accent, size: 18),
              const SizedBox(width: 10),
              Text('ADD TO QUEUE',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      letterSpacing: 1,
                      color: widget.textPrimary)),
            ]),
          ),
        PopupMenuItem(
          value: 'favorite',
          child: Row(children: [
            Icon(
              widget.song.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: widget.song.isFavorite ? Colors.red : widget.accent,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              widget.song.isFavorite ? 'REMOVE FROM FAVORITES' : 'ADD TO FAVORITES',
              style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  letterSpacing: 1,
                  color: widget.textPrimary),
            ),
          ]),
        ),
        PopupMenuItem(
          value: 'playlist',
          child: Row(children: [
            Icon(Icons.library_add, color: widget.accent, size: 18),
            const SizedBox(width: 10),
            Text('ADD TO PLAYLIST',
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    letterSpacing: 1,
                    color: widget.textPrimary)),
          ]),
        ),
      ],
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
