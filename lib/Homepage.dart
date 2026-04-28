import 'package:flutter/material.dart';
import 'pixel_colors.dart';
import 'models/song.dart';
import 'services/db_service.dart';
import 'services/audio_manager.dart';

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
class _PixelSongMenu extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final accent = isDark ? PixelColors.neonPink : PixelColors.accentPink;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert,
          color: isDark ? PixelColors.darkBorder : PixelColors.lightBorder,
          size: 20),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      color: isDark ? PixelColors.darkCard : PixelColors.lightCard,
      onSelected: (value) {
        if (value == 'queue') {
          AudioManager.instance.addToQueue(song);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${song.title} added to queue',
                style: const TextStyle(fontFamily: 'monospace')),
            duration: const Duration(seconds: 1),
          ));
        } else if (value == 'playlist') {
          onAddToPlaylist();
        }
      },
      itemBuilder: (_) => [
        if (hasOngoingQueue)
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
                      color: isDark ? Colors.white : PixelColors.darkBg)),
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
                    color: isDark ? Colors.white : PixelColors.darkBg)),
          ]),
        ),
      ],
    );
  }
}

// ── Pixel playlist bottom sheet ────────────────────────────────────────────
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
    final ok =
        await DBService.addSongToPlaylist(playlistId: id, songId: widget.song.id);
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
    showDialog(
      context: context,
      builder: (ctx) {
        final accent = widget.isDark ? PixelColors.neonPink : PixelColors.accentPink;
        return AlertDialog(
          backgroundColor: widget.isDark ? PixelColors.darkCard : PixelColors.lightSurface,
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
                  style: TextStyle(fontFamily: 'monospace', letterSpacing: 1)),
            ),
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
        );
      },
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
          // Pixel drag handle replacement — section label
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
                  color: border,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  letterSpacing: 1)),
          const SizedBox(height: 16),

          // Create new button
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
              child: Row(
                children: [
                  Icon(Icons.add, color: accent, size: 18),
                  const SizedBox(width: 10),
                  Text('CREATE NEW PLAYLIST',
                      style: TextStyle(
                          color: accent,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          fontSize: 11)),
                ],
              ),
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
              constraints: const BoxConstraints(maxHeight: 260),
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
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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