import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'models/song.dart';
import 'pixel_colors.dart';
import 'services/db_service.dart';
import 'services/audio_manager.dart';

class SearchPage extends StatefulWidget {
  final Function(Song) onOpenPlayer;
  final VoidCallback onProfileTap;
  final String username;
  final Color avatarColor;
  final Uint8List? avatarImageBytes;
  final int userId;

  const SearchPage({
    super.key,
    required this.onOpenPlayer,
    required this.onProfileTap,
    required this.username,
    required this.avatarColor,
    required this.userId,
    this.avatarImageBytes,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Song> _allSongs = [];
  List<Song> _filteredSongs = [];
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final songs = await DBService.fetchAllSongs(widget.userId);
    if (mounted) setState(() => _allSongs = songs);
  }

  void _filter(String val) {
    setState(() {
      _hasSearched = val.isNotEmpty;
      _filteredSongs = _allSongs
          .where((s) =>
              s.title.toLowerCase().contains(val.toLowerCase()) ||
              (s.artist?.toLowerCase().contains(val.toLowerCase()) ?? false))
          .toList();
    });
  }

  void _showAddToPlaylist(Song song) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final playlists = await DBService.getPlaylists(widget.userId);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _PixelPlaylistSheet(
        song: song,
        userId: widget.userId,
        playlists: playlists,
        isDark: isDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final accent = isDark ? PixelColors.neonPink : PixelColors.accentPink;
    final textPrimary = isDark ? Colors.white : PixelColors.darkBg;
    final borderColor = isDark ? PixelColors.darkBorder : PixelColors.lightBorder;
    final cardColor = isDark ? PixelColors.darkCard : PixelColors.lightCard;
    final fillColor = isDark ? PixelColors.darkSurface : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Pixel search bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: fillColor,
                        border: Border.all(color: accent, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.25),
                            blurRadius: 0,
                            offset: const Offset(3, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: _filter,
                        style: TextStyle(
                          color: textPrimary,
                          fontFamily: 'monospace',
                          fontSize: 13,
                          letterSpacing: 1,
                        ),
                        decoration: InputDecoration(
                          hintText: 'SEARCH SONGS...',
                          hintStyle: TextStyle(
                            color: accent.withOpacity(0.5),
                            fontSize: 11,
                            letterSpacing: 2,
                            fontFamily: 'monospace',
                          ),
                          prefixIcon: Icon(Icons.search, color: accent, size: 20),
                          filled: true,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Pixel avatar button
                  GestureDetector(
                    onTap: widget.onProfileTap,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: widget.avatarColor,
                        border: Border.all(color: accent, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.3),
                            blurRadius: 0,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: widget.avatarImageBytes != null
                          ? Image.memory(widget.avatarImageBytes!,
                              fit: BoxFit.cover)
                          : Center(
                              child: Text(
                                widget.username.isNotEmpty
                                    ? widget.username[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'monospace',
                                  fontSize: 16,
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Results ───────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<Song?>(
                stream: AudioManager.instance.currentSongStream,
                builder: (context, snapshot) {
                  final hasOngoingQueue =
                      snapshot.hasData && snapshot.data != null;

                  if (!_hasSearched) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 56, color: borderColor),
                          const SizedBox(height: 12),
                          Text(
                            'SEARCH YOUR LIBRARY',
                            style: TextStyle(
                              color: borderColor,
                              fontFamily: 'monospace',
                              letterSpacing: 2,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (_filteredSongs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.music_off, size: 56, color: borderColor),
                          const SizedBox(height: 12),
                          Text(
                            'NO SONGS FOUND',
                            style: TextStyle(
                              color: borderColor,
                              fontFamily: 'monospace',
                              letterSpacing: 2,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 12, bottom: 120),
                    itemCount: _filteredSongs.length,
                    itemBuilder: (context, i) {
                      final song = _filteredSongs[i];
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: cardColor,
                          border: Border.all(color: borderColor, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(0.12),
                              blurRadius: 0,
                              offset: const Offset(3, 3),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          leading: song.imageUrl != null
                              ? Image.network(
                                  song.imageUrl!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => _thumbPlaceholder(accent),
                                )
                              : _thumbPlaceholder(accent),
                          title: Text(
                            song.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: textPrimary,
                              fontFamily: 'monospace',
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            song.artist ?? '',
                            style: TextStyle(
                              color: isDark
                                  ? PixelColors.neonPurple
                                  : PixelColors.accentLavender,
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert,
                                color: borderColor, size: 20),
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero),
                            color: cardColor,
                            onSelected: (value) {
                              if (value == 'queue') {
                                AudioManager.instance.addToQueue(song);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                      '${song.title} added to queue',
                                      style: const TextStyle(
                                          fontFamily: 'monospace')),
                                  duration: const Duration(seconds: 1),
                                ));
                              } else if (value == 'playlist') {
                                _showAddToPlaylist(song);
                              }
                            },
                            itemBuilder: (_) => [
                              if (hasOngoingQueue)
                                PopupMenuItem(
                                  value: 'queue',
                                  child: Row(children: [
                                    Icon(Icons.playlist_add,
                                        color: accent, size: 18),
                                    const SizedBox(width: 10),
                                    Text('ADD TO QUEUE',
                                        style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 11,
                                            letterSpacing: 1,
                                            color: textPrimary)),
                                  ]),
                                ),
                              PopupMenuItem(
                                value: 'playlist',
                                child: Row(children: [
                                  Icon(Icons.library_add,
                                      color: accent, size: 18),
                                  const SizedBox(width: 10),
                                  Text('ADD TO PLAYLIST',
                                      style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11,
                                          letterSpacing: 1,
                                          color: textPrimary)),
                                ]),
                              ),
                            ],
                          ),
                          onTap: () => widget.onOpenPlayer(song),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder(Color accent) {
    return Container(
      width: 48,
      height: 48,
      color: accent.withOpacity(0.1),
      child: Icon(Icons.music_note, color: accent, size: 22),
    );
  }
}

// ── Shared pixel playlist bottom sheet ────────────────────────────────────
class _PixelPlaylistSheet extends StatefulWidget {
  final Song song;
  final int userId;
  final List<dynamic> playlists;
  final bool isDark;

  const _PixelPlaylistSheet({
    required this.song,
    required this.userId,
    required this.playlists,
    required this.isDark,
  });

  @override
  State<_PixelPlaylistSheet> createState() => _PixelPlaylistSheetState();
}

class _PixelPlaylistSheetState extends State<_PixelPlaylistSheet> {
  final _ctrl = TextEditingController();
  bool _creating = false;

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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          if (widget.playlists.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('YOUR PLAYLISTS',
                style: TextStyle(
                    color: border,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontFamily: 'monospace')),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.playlists.length,
                itemBuilder: (ctx, i) {
                  final pl = widget.playlists[i];
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
          ],
        ],
      ),
    );
  }
}