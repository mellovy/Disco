import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'models/song.dart';
import 'pixel_colors.dart';
import 'services/db_service.dart';
import 'services/audio_manager.dart';
import 'widgets/shared_sheets.dart';

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
      builder: (ctx) => PixelPlaylistSheet(
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
                          trailing: _SearchSongMenu(
                            song: song,
                            hasOngoingQueue: hasOngoingQueue,
                            userId: widget.userId,
                            accent: accent,
                            textPrimary: textPrimary,
                            cardColor: cardColor,
                            onAddToPlaylist: () => _showAddToPlaylist(song),
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

class _SearchSongMenu extends StatefulWidget {
  final Song song;
  final bool hasOngoingQueue;
  final int userId;
  final Color accent;
  final Color textPrimary;
  final Color cardColor;
  final VoidCallback onAddToPlaylist;

  const _SearchSongMenu({
    required this.song,
    required this.hasOngoingQueue,
    required this.userId,
    required this.accent,
    required this.textPrimary,
    required this.cardColor,
    required this.onAddToPlaylist,
  });

  @override
  State<_SearchSongMenu> createState() => _SearchSongMenuState();
}

class _SearchSongMenuState extends State<_SearchSongMenu> {
  bool _toggling = false;

  Future<void> _toggleFavorite() async {
    if (_toggling) return;
    setState(() {
      _toggling = true;
      widget.song.isFavorite = !widget.song.isFavorite;
    });
    final success =
        await DBService.toggleFavorite(widget.userId, widget.song.id);
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