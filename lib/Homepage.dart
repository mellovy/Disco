import 'package:flutter/material.dart';
import 'pixel_colors.dart';
import 'models/song.dart';
import 'services/db_service.dart';
import 'services/audio_manager.dart';
import 'widgets/shared_sheets.dart';

class HomePage extends StatefulWidget {
  final String username;
  final int userId;
  final Function(Song) onOpenPlayer;
  final Function(List<Song>)? onSongsLoaded;

  const HomePage({
    super.key,
    required this.username,
    required this.userId,
    required this.onOpenPlayer,
    this.onSongsLoaded,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Song> _allSongs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final songs = await DBService.fetchAllSongs(widget.userId);
      if (mounted) {
        setState(() {
          _allSongs = songs;
          _loading = false;
        });
        widget.onSongsLoaded?.call(songs);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _songImage(String? url,
      {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (url == null) {
      return Container(
        width: width,
        height: height,
        color: PixelColors.lightSurface,
        child: const Icon(Icons.music_note, color: PixelColors.accentPink),
      );
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (c, e, s) => Container(
        width: width,
        height: height,
        color: PixelColors.lightSurface,
        child: const Icon(Icons.music_note, color: PixelColors.accentPink),
      ),
    );
  }

  void _showAddToPlaylist(BuildContext context, Song song) async {
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
    final accentCyan = isDark ? PixelColors.neonCyan : PixelColors.accentMint;
    final cardColor = isDark ? PixelColors.darkCard : PixelColors.lightCard;
    final borderColor = isDark ? PixelColors.darkBorder : PixelColors.lightBorder;
    final textPrimary = isDark ? Colors.white : PixelColors.darkBg;
    final gridSongs = _allSongs.take(4).toList();

    return Scaffold(
      backgroundColor: bgColor,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : StreamBuilder<Song?>(
              stream: AudioManager.instance.currentSongStream,
              builder: (context, snapshot) {
                final bool hasOngoingQueue =
                    snapshot.hasData && snapshot.data != null;

                return RefreshIndicator(
                  onRefresh: _loadData,
                  color: accent,
                  child: CustomScrollView(
                    slivers: [
                      // ── Pixel header — sticky pink banner ─────────────
                      SliverAppBar(
                        pinned: true,
                        floating: false,
                        expandedHeight: 100,
                        backgroundColor:
                            isDark ? PixelColors.darkSurface : PixelColors.accentPink,
                        elevation: 0,
                        // Sharp pixel bottom border
                        bottom: PreferredSize(
                          preferredSize: const Size.fromHeight(3),
                          child: Container(
                            height: 3,
                            color: isDark
                                ? PixelColors.neonPurple
                                : PixelColors.accentLavender,
                          ),
                        ),
                        flexibleSpace: FlexibleSpaceBar(
                          collapseMode: CollapseMode.pin,
                          background: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? PixelColors.darkSurface
                                  : PixelColors.accentPink,
                            ),
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).padding.top + 12,
                              left: 20,
                              right: 20,
                              bottom: 16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Pixel badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.5),
                                        width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.music_note,
                                          color: Colors.white, size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        'DISCO',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'HEY, ${widget.username.toUpperCase()}!',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                    fontFamily: 'monospace',
                                    shadows: [
                                      Shadow(
                                        color: Color(0x55000000),
                                        blurRadius: 0,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                const Text(
                                  '>> WHAT ARE WE VIBING TO?',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                    letterSpacing: 2,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ── Top Tracks section header ─────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                          child: Row(
                            children: [
                              Container(
                                  width: 6, height: 22, color: accentCyan),
                              const SizedBox(width: 10),
                              Text(
                                'TOP TRACKS',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: textPrimary,
                                  letterSpacing: 3,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (_allSongs.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: Column(
                              children: [
                                Icon(Icons.music_off,
                                    size: 60,
                                    color: borderColor),
                                const SizedBox(height: 12),
                                Text(
                                  'NO SONGS YET',
                                  style: TextStyle(
                                    color: borderColor,
                                    fontFamily: 'monospace',
                                    letterSpacing: 2,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.82,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final song = gridSongs[index];
                                return GestureDetector(
                                  onTap: () => widget.onOpenPlayer(song),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      border: Border.all(
                                          color: borderColor, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accent.withOpacity(0.18),
                                          blurRadius: 0,
                                          offset: const Offset(4, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _songImage(song.imageUrl,
                                              width: double.infinity),
                                        ),
                                        Container(
                                          color: cardColor,
                                          padding: const EdgeInsets.fromLTRB(
                                              10, 8, 6, 8),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      song.title,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        fontSize: 12,
                                                        color: textPrimary,
                                                        fontFamily: 'monospace',
                                                        letterSpacing: 0.5,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      song.artist ?? '',
                                                      style: TextStyle(
                                                        color: isDark
                                                            ? PixelColors
                                                                .neonPurple
                                                            : PixelColors
                                                                .accentLavender,
                                                        fontSize: 10,
                                                        fontFamily: 'monospace',
                                                        letterSpacing: 0.5,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              _PixelSongMenu(
                                                song: song,
                                                hasOngoingQueue: hasOngoingQueue,
                                                userId: widget.userId,
                                                isDark: isDark,
                                                onAddToPlaylist: () =>
                                                    _showAddToPlaylist(
                                                        context, song),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              childCount: gridSongs.length,
                            ),
                          ),
                        ),

                      // ── More for You ──────────────────────────────────
                      if (_allSongs.length > 4) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 28, 16, 12),
                            child: Row(
                              children: [
                                Container(
                                    width: 6,
                                    height: 22,
                                    color: isDark
                                        ? PixelColors.neonPink
                                        : PixelColors.accentPink),
                                const SizedBox(width: 10),
                                Text(
                                  'MORE FOR YOU',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: textPrimary,
                                    letterSpacing: 3,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final song = _allSongs.skip(4).toList()[index];
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  border: Border.all(
                                      color: borderColor, width: 2),
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
                                      horizontal: 12, vertical: 4),
                                  leading: _songImage(song.imageUrl,
                                      width: 48, height: 48),
                                  title: Text(
                                    song.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: textPrimary,
                                      fontFamily: 'monospace',
                                      letterSpacing: 0.5,
                                    ),
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
                                  ),
                                  trailing: _PixelSongMenu(
                                    song: song,
                                    hasOngoingQueue: hasOngoingQueue,
                                    userId: widget.userId,
                                    isDark: isDark,
                                    onAddToPlaylist: () =>
                                        _showAddToPlaylist(context, song),
                                  ),
                                  onTap: () => widget.onOpenPlayer(song),
                                ),
                              );
                            },
                            childCount: _allSongs.skip(4).length,
                          ),
                        ),
                      ],

                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ── Pixel-style 3-dot song action menu ────────────────────────────────────
class _PixelSongMenu extends StatefulWidget {
  final Song song;
  final bool hasOngoingQueue;
  final int userId;
  final bool isDark;
  final VoidCallback onAddToPlaylist;

  const _PixelSongMenu({
    required this.song,
    required this.hasOngoingQueue,
    required this.userId,
    required this.isDark,
    required this.onAddToPlaylist,
  });

  @override
  State<_PixelSongMenu> createState() => _PixelSongMenuState();
}

class _PixelSongMenuState extends State<_PixelSongMenu> {
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
    final accent = widget.isDark ? PixelColors.neonPink : PixelColors.accentPink;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert,
          color: widget.isDark ? PixelColors.darkBorder : PixelColors.lightBorder,
          size: 20),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      color: widget.isDark ? PixelColors.darkCard : PixelColors.lightCard,
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
              Icon(Icons.playlist_add, color: accent, size: 18),
              const SizedBox(width: 10),
              Text('ADD TO QUEUE',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      letterSpacing: 1,
                      color: widget.isDark ? Colors.white : PixelColors.darkBg)),
            ]),
          ),
        PopupMenuItem(
          value: 'favorite',
          child: Row(children: [
            Icon(
              widget.song.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: widget.song.isFavorite ? Colors.red : accent,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              widget.song.isFavorite ? 'REMOVE FROM FAVORITES' : 'ADD TO FAVORITES',
              style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  letterSpacing: 1,
                  color: widget.isDark ? Colors.white : PixelColors.darkBg),
            ),
          ]),
        ),
        PopupMenuItem(
          value: 'playlist',
          child: Row(children: [
            Icon(Icons.library_add, color: accent, size: 18),
            const SizedBox(width: 10),
            Text('ADD TO PLAYLIST',
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    letterSpacing: 1,
                    color: widget.isDark ? Colors.white : PixelColors.darkBg)),
          ]),
        ),
      ],
    );
  }
}