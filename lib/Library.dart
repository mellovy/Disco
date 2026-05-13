import 'package:flutter/material.dart';
import 'pixel_colors.dart';
import 'models/song.dart';
import 'services/db_service.dart';
import 'services/audio_manager.dart';
import 'widgets/shared_sheets.dart';

class LibraryPage extends StatefulWidget {
  final int userId;
  final void Function(Song, {List<Song>? queueSongs, bool shuffle})? onOpenPlayer;

  const LibraryPage({
    super.key,
    required this.userId,
    this.onOpenPlayer,
  });

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  List<dynamic> _playlists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
    DBService.playlistRefreshStream.listen((_) => _onRefreshTriggered());
  }

  void _onRefreshTriggered() {
    if (mounted) _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() => _loading = true);
    try {
      final playlists = await DBService.getPlaylists(widget.userId);
      if (mounted) {
        setState(() {
          _playlists = playlists;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCreatePlaylistDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? PixelColors.neonPink : PixelColors.accentPink;
    final ctrl = TextEditingController();
    bool creating = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor:
              isDark ? PixelColors.darkCard : PixelColors.lightSurface,
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
            controller: ctrl,
            autofocus: true,
            style: TextStyle(
                fontFamily: 'monospace',
                color: isDark ? Colors.white : PixelColors.darkBg),
            decoration: InputDecoration(
              hintText: 'PLAYLIST NAME',
              hintStyle:
                  const TextStyle(fontFamily: 'monospace', fontSize: 11),
              filled: true,
              fillColor: isDark
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
              onTap: creating
                  ? null
                  : () async {
                      final name = ctrl.text.trim();
                      if (name.isEmpty) return;
                      setDlg(() => creating = true);
                      final pid = await DBService.createPlaylist(
                          userId: widget.userId, name: name);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (pid != null) {
                        _loadPlaylists();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Playlist "$name" created',
                                style: const TextStyle(
                                    fontFamily: 'monospace')),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Failed to create playlist')),
                        );
                      }
                    },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: accent,
                child: const Text('CREATE',
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
      ),
    );
  }

  void _openPlaylistDetail(dynamic playlist) {
    final id = playlist['playlist_id'] ?? playlist['id'];
    final name = playlist['name'] ?? 'Untitled';
    final isFavorites = name == 'Favorites';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaylistDetailPage(
          playlistId: id is int ? id : int.parse(id.toString()),
          playlistName: name,
          isFavorites: isFavorites,
          userId: widget.userId,
          onOpenPlayer: widget.onOpenPlayer,
          onPlaylistChanged: _loadPlaylists,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final accent = isDark ? PixelColors.neonPink : PixelColors.accentPink;
    final accentCyan = isDark ? PixelColors.neonCyan : PixelColors.accentMint;
    final textPrimary = isDark ? Colors.white : PixelColors.darkBg;
    final borderColor = isDark ? PixelColors.darkBorder : PixelColors.lightBorder;
    final cardColor = isDark ? PixelColors.darkCard : PixelColors.lightCard;

    // Separate Favorites playlist
    final favoritesPlaylist = _playlists
        .where((p) => (p['name'] ?? '') == 'Favorites')
        .toList();
    final otherPlaylists = _playlists
        .where((p) => (p['name'] ?? '') != 'Favorites')
        .toList();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPlaylists,
          color: accent,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    children: [
                      Container(width: 6, height: 22, color: accent),
                      const SizedBox(width: 10),
                      Text(
                        'YOUR LIBRARY',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                          letterSpacing: 3,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _showCreatePlaylistDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: accent,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withOpacity(0.4),
                                blurRadius: 0,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'NEW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_loading)
                const SliverFillRemaining(
                  child: Center(
                      child: CircularProgressIndicator(
                          color: PixelColors.accentPink)),
                )
              else if (_playlists.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.library_music,
                            size: 60, color: borderColor),
                        const SizedBox(height: 12),
                        Text(
                          'NO PLAYLISTS YET',
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
              else ...[
                // Favorites section
                if (favoritesPlaylist.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(
                        children: [
                          Container(
                              width: 4, height: 14, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            'FAVORITES',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: borderColor,
                              letterSpacing: 2,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final pl = favoritesPlaylist[index];
                          return _PlaylistCard(
                            playlist: pl,
                            accent: Colors.red,
                            cardColor: cardColor,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                            icon: Icons.favorite,
                            onTap: () => _openPlaylistDetail(pl),
                          );
                        },
                        childCount: favoritesPlaylist.length,
                      ),
                    ),
                  ),
                ],

                // Other playlists section
                if (otherPlaylists.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Row(
                        children: [
                          Container(width: 4, height: 14, color: accentCyan),
                          const SizedBox(width: 8),
                          Text(
                            'YOUR PLAYLISTS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: borderColor,
                              letterSpacing: 2,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final pl = otherPlaylists[index];
                          return _PlaylistCard(
                            playlist: pl,
                            accent: accent,
                            cardColor: cardColor,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                            icon: Icons.playlist_play,
                            onTap: () => _openPlaylistDetail(pl),
                            onDelete: () async {
                              final id = pl['playlist_id'] ?? pl['id'];
                              final pid = id is int
                                  ? id
                                  : int.parse(id.toString());
                              final ok = await _confirmDelete(
                                  pl['name'] ?? 'Untitled');
                              if (ok) {
                                final success =
                                    await DBService.deletePlaylist(pid);
                                if (success && mounted) {
                                  _loadPlaylists();
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        'Playlist deleted',
                                        style: const TextStyle(
                                            fontFamily: 'monospace')),
                                  ));
                                }
                              }
                            },
                          );
                        },
                        childCount: otherPlaylists.length,
                      ),
                    ),
                  ),
                ],
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? PixelColors.darkCard
            : PixelColors.lightSurface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text('DELETE PLAYLIST',
            style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w900,
                color: Theme.of(context).brightness == Brightness.dark
                    ? PixelColors.neonPink
                    : PixelColors.accentPink)),
        content: Text('Are you sure you want to delete "$name"?',
            style: const TextStyle(fontFamily: 'monospace')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL',
                style: TextStyle(fontFamily: 'monospace')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE',
                style: TextStyle(
                    color: Colors.red,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _PlaylistCard extends StatelessWidget {
  final dynamic playlist;
  final Color accent;
  final Color cardColor;
  final Color borderColor;
  final Color textPrimary;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _PlaylistCard({
    required this.playlist,
    required this.accent,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.icon,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = playlist['name'] ?? 'Untitled';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Icon(icon, color: accent, size: 28),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            fontSize: 13,
            letterSpacing: 0.5,
            color: textPrimary,
          ),
        ),
        subtitle: Text(
          'PLAYLIST',
          style: TextStyle(
            color: borderColor,
            fontFamily: 'monospace',
            fontSize: 9,
            letterSpacing: 2,
          ),
        ),
        trailing: onDelete != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_right,
                      color: borderColor, size: 20),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(Icons.delete_outline,
                        color: Colors.red.withOpacity(0.7), size: 20),
                  ),
                ],
              )
            : Icon(Icons.chevron_right, color: borderColor, size: 20),
        onTap: onTap,
      ),
    );
  }
}

// ── Playlist Detail Page ───────────────────────────────────────────────────

class PlaylistDetailPage extends StatefulWidget {
  final int playlistId;
  final String playlistName;
  final bool isFavorites;
  final int userId;
  final void Function(Song, {List<Song>? queueSongs, bool shuffle})? onOpenPlayer;
  final VoidCallback? onPlaylistChanged;

  const PlaylistDetailPage({
    super.key,
    required this.playlistId,
    required this.playlistName,
    required this.isFavorites,
    required this.userId,
    this.onOpenPlayer,
    this.onPlaylistChanged,
  });

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  List<Song> _songs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() => _loading = true);
    try {
      final songs = widget.isFavorites
          ? await DBService.getFavoritesAsSongs(widget.userId)
          : await DBService.getPlaylistSongs(widget.playlistId);
      if (mounted) {
        setState(() {
          _songs = songs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _playPlaylist({bool shuffle = false}) {
    if (_songs.isEmpty) return;
    if (widget.onOpenPlayer != null && _songs.isNotEmpty) {
      widget.onOpenPlayer!(_songs.first, queueSongs: _songs, shuffle: shuffle);
    }
  }

  Future<void> _removeSong(Song song) async {
    final ok = await DBService.removeSongFromPlaylist(
      playlistId: widget.playlistId,
      songId: song.id,
    );
    if (ok && mounted) {
      _loadSongs();
      widget.onPlaylistChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed from ${widget.playlistName}',
              style: const TextStyle(fontFamily: 'monospace')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final accent = isDark ? PixelColors.neonPink : PixelColors.accentPink;
    final textPrimary = isDark ? Colors.white : PixelColors.darkBg;
    final borderColor = isDark ? PixelColors.darkBorder : PixelColors.lightBorder;
    final cardColor = isDark ? PixelColors.darkCard : PixelColors.lightCard;
    final iconColor = widget.isFavorites ? Colors.red : accent;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? PixelColors.darkSurface : PixelColors.lightSurface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: iconColor.withOpacity(0.4)),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20, color: accent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.playlistName.toUpperCase(),
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 3,
            fontFamily: 'monospace',
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : RefreshIndicator(
              onRefresh: _loadSongs,
              color: accent,
              child: CustomScrollView(
                slivers: [
                  // Action buttons
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _playPlaylist(shuffle: false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                decoration: BoxDecoration(
                                  color: accent,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withOpacity(0.4),
                                      blurRadius: 0,
                                      offset: const Offset(3, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.play_arrow,
                                        color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'PLAY',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _playPlaylist(shuffle: true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  border:
                                      Border.all(color: accent, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withOpacity(0.3),
                                      blurRadius: 0,
                                      offset: const Offset(3, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shuffle,
                                        color: accent, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'SHUFFLE',
                                      style: TextStyle(
                                        color: accent,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_songs.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(iconColor == Colors.red
                                    ? Icons.favorite_border
                                    : Icons.queue_music,
                                size: 60, color: borderColor),
                            const SizedBox(height: 12),
                            Text(
                              widget.isFavorites
                                  ? 'NO FAVORITES YET'
                                  : 'PLAYLIST IS EMPTY',
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final song = _songs[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: cardColor,
                                border: Border.all(
                                    color: borderColor, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withOpacity(0.1),
                                    blurRadius: 0,
                                    offset: const Offset(3, 3),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                leading: song.imageUrl != null
                                    ? Image.network(
                                        song.imageUrl!,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) =>
                                            pixelThumb(accent, size: 48),
                                      )
                                    : pixelThumb(accent, size: 48),
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
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.onOpenPlayer != null)
                                      IconButton(
                                        icon: Icon(Icons.play_arrow,
                                            color: accent, size: 22),
                                        onPressed: () =>
                                            widget.onOpenPlayer!(song, queueSongs: _songs),
                                      ),
                                    if (!widget.isFavorites)
                                      IconButton(
                                        icon: const Icon(
                                            Icons.remove_circle_outline,
                                            size: 20),
                                        color: Colors.red.withOpacity(0.7),
                                        onPressed: () => _removeSong(song),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: _songs.length,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
    );
  }
}
