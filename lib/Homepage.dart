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
                                              PixelSongMenu(
                                                song: song,
                                                hasOngoingQueue: hasOngoingQueue,
                                                userId: widget.userId,
                                                accent: accent,
                                                textPrimary: textPrimary,
                                                cardColor: cardColor,
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
                                  trailing: PixelSongMenu(
                                    song: song,
                                    hasOngoingQueue: hasOngoingQueue,
                                    userId: widget.userId,
                                    accent: accent,
                                    textPrimary: textPrimary,
                                    cardColor: cardColor,
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

