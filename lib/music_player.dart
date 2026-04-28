import 'dart:async';
import 'package:flutter/material.dart';
import 'pixel_colors.dart';
import 'package:just_audio/just_audio.dart';
import 'models/song.dart';
import 'services/db_service.dart';
import 'services/audio_manager.dart';

class MusicPlayerPage extends StatefulWidget {
  final Song song;
  final int userId;
  final VoidCallback onClose;
  final AudioPlayer player;

  const MusicPlayerPage({
    super.key,
    required this.song,
    required this.userId,
    required this.onClose,
    required this.player,
  });

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage>
    with SingleTickerProviderStateMixin {
  late Song _currentSong;
  late bool _isFavorite;
  bool _togglingFavorite = false;

  late StreamSubscription<Song?> _songSub;
  late StreamSubscription<List<Song>> _queueSub;

  double? _dragValue;
  bool _isDragging = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _currentSong = AudioManager.instance.currentSong ?? widget.song;
    _isFavorite = _currentSong.isFavorite;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _songSub = AudioManager.instance.currentSongStream.listen((song) {
      if (song != null && mounted && song.id != _currentSong.id) {
        setState(() {
          _currentSong = song;
          _isFavorite = song.isFavorite;
        });
      }
    });
    _queueSub = AudioManager.instance.queueStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _songSub.cancel();
    _queueSub.cancel();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    if (_togglingFavorite) return;
    setState(() {
      _togglingFavorite = true;
      _isFavorite = !_isFavorite;
      _currentSong.isFavorite = _isFavorite;
    });
    final success =
        await DBService.toggleFavorite(widget.userId, _currentSong.id);
    if (!success && mounted) {
      setState(() {
        _isFavorite = !_isFavorite;
        _currentSong.isFavorite = _isFavorite;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update favorite')),
      );
    }
    if (mounted) setState(() => _togglingFavorite = false);
  }

  void _showQueue() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => QueueBottomSheet(
        currentSong: _currentSong,
        onSongSelected: (song) {
          Navigator.pop(context);
          AudioManager.instance.setSong(song);
        },
      ),
    );
  }

  void _showAddToPlaylist() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final playlists = await DBService.getPlaylists(widget.userId);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _PixelPlaylistSheet(
        song: _currentSong,
        userId: widget.userId,
        playlists: playlists,
        isDark: isDark,
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final accent = isDark ? PixelColors.neonPink : PixelColors.accentPink;
    final accentAlt = isDark ? PixelColors.neonPurple : PixelColors.accentLavender;
    final textPrimary = isDark ? Colors.white : PixelColors.darkBg;
    final borderColor = isDark ? PixelColors.darkBorder : PixelColors.lightBorder;
    final surfaceColor = isDark ? PixelColors.darkSurface : PixelColors.lightSurface;

    return Scaffold(
      backgroundColor: bgColor,
      // ── Pixel AppBar ─────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: accent.withOpacity(0.4)),
        ),
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_down, size: 32, color: accent),
          onPressed: widget.onClose,
        ),
        title: Text(
          'NOW PLAYING',
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 3,
            fontFamily: 'monospace',
          ),
        ),
        centerTitle: true,
        actions: [
          // Queue button with pixel badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(Icons.queue_music, color: accent, size: 26),
                onPressed: _showQueue,
              ),
              if (AudioManager.instance.currentQueue.isNotEmpty)
                Positioned(
                  right: 4,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    color: Colors.red,
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${AudioManager.instance.currentQueue.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.library_add_outlined, color: accent, size: 24),
            onPressed: _showAddToPlaylist,
          ),
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(_isFavorite),
                color: _isFavorite ? Colors.red : borderColor,
                size: 24,
              ),
            ),
            onPressed: _togglingFavorite ? null : _toggleFavorite,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ── Album art + vertical volume slider ────────────────────
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Vertical volume slider on the left ───────────────
                    SizedBox(
                      width: 36,
                      height: MediaQuery.of(context).size.width * 0.65,
                      child: StreamBuilder<double>(
                        stream: widget.player.volumeStream,
                        builder: (context, snapshot) {
                          return RotatedBox(
                            quarterTurns: 3,
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 4,
                                activeTrackColor: accent,
                                inactiveTrackColor: borderColor,
                                thumbColor: accent,
                                thumbShape: const _PixelThumb(),
                                overlayShape: SliderComponentShape.noOverlay,
                                trackShape: const _PixelTrack(),
                              ),
                              child: Slider(
                                value: snapshot.data ?? 1.0,
                                onChanged: (v) => widget.player.setVolume(v),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ── Album art ────────────────────────────────────────
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: MediaQuery.of(context).size.width * 0.65,
                          height: MediaQuery.of(context).size.width * 0.65,
                          decoration: BoxDecoration(
                            border: Border.all(color: accent, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: accentAlt.withOpacity(0.8),
                                blurRadius: 0,
                                offset: const Offset(6, 6),
                              ),
                              BoxShadow(
                                color: accent.withOpacity(
                                    0.15 + 0.1 * _pulseController.value),
                                blurRadius:
                                    16 + 8 * _pulseController.value,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: _currentSong.imageUrl != null
                          ? Image.network(
                              _currentSong.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) =>
                                  _placeholderArt(accent),
                            )
                          : _placeholderArt(accent),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Song title ────────────────────────────────────────────
              Text(
                _currentSong.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                  fontFamily: 'monospace',
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),

              // Artist pill — pixel style (sharp corners)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  border: Border.all(color: accent.withOpacity(0.4), width: 1),
                ),
                child: Text(
                  (_currentSong.artist ?? '').toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    letterSpacing: 2,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Progress bar — pixel style ─────────────────────────────
              StreamBuilder<Duration?>(
                stream: widget.player.durationStream,
                builder: (context, durSnap) {
                  final total = durSnap.data ?? Duration.zero;
                  return StreamBuilder<Duration>(
                    stream: widget.player.positionStream,
                    builder: (context, posSnap) {
                      final position = posSnap.data ?? Duration.zero;
                      final maxMs = total.inMilliseconds.toDouble();
                      final sliderValue = _isDragging
                          ? _dragValue!
                          : position.inMilliseconds
                              .toDouble()
                              .clamp(0.0, maxMs > 0 ? maxMs : 0.0);

                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 5,
                              activeTrackColor: accent,
                              inactiveTrackColor: borderColor,
                              thumbColor: accent,
                              thumbShape: const _PixelThumb(),
                              overlayShape: SliderComponentShape.noOverlay,
                              trackShape: const _PixelTrack(),
                            ),
                            child: Slider(
                              value: sliderValue,
                              max: maxMs > 0 ? maxMs : 1.0,
                              onChanged: maxMs > 0
                                  ? (v) => setState(() {
                                        _isDragging = true;
                                        _dragValue = v;
                                      })
                                  : null,
                              onChangeEnd: (v) async {
                                await widget.player.seek(
                                    Duration(milliseconds: v.toInt()));
                                setState(() {
                                  _isDragging = false;
                                  _dragValue = null;
                                });
                              },
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _fmt(_isDragging
                                      ? Duration(
                                          milliseconds: _dragValue!.toInt())
                                      : position),
                                  style: TextStyle(
                                    color: borderColor,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  _fmt(total),
                                  style: TextStyle(
                                    color: borderColor,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 8),

              // ── Controls row ───────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Shuffle
                  StreamBuilder<bool>(
                    stream: widget.player.shuffleModeEnabledStream,
                    builder: (context, snapshot) {
                      final isShuffle = snapshot.data ?? false;
                      return _PixelControlBtn(
                        icon: Icons.shuffle,
                        color: isShuffle ? accent : borderColor,
                        size: 24,
                        onTap: () async {
                          final enable = !isShuffle;
                          if (enable) await widget.player.shuffle();
                          await widget.player.setShuffleModeEnabled(enable);
                        },
                      );
                    },
                  ),

                  // Previous
                  _PixelControlBtn(
                    icon: Icons.skip_previous_rounded,
                    color: textPrimary,
                    size: 36,
                    onTap: () {
                      if (widget.player.hasPrevious) {
                        widget.player.seekToPrevious();
                      } else {
                        widget.player.seek(Duration.zero);
                      }
                    },
                  ),

                  // Play / Pause — large pixel button
                  StreamBuilder<PlayerState>(
                    stream: widget.player.playerStateStream,
                    builder: (context, snapshot) {
                      final playing = snapshot.data?.playing ?? false;
                      return GestureDetector(
                        onTap: () => playing
                            ? widget.player.pause()
                            : widget.player.play(),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: accent,
                            boxShadow: [
                              BoxShadow(
                                color: accentAlt.withOpacity(0.9),
                                blurRadius: 0,
                                offset: const Offset(5, 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 42,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),

                  // Next
                  _PixelControlBtn(
                    icon: Icons.skip_next_rounded,
                    color: textPrimary,
                    size: 36,
                    onTap: () {
                      if (widget.player.hasNext) widget.player.seekToNext();
                    },
                  ),

                  // Loop
                  StreamBuilder<LoopMode>(
                    stream: widget.player.loopModeStream,
                    builder: (context, snapshot) {
                      final mode = snapshot.data ?? LoopMode.off;
                      return _PixelControlBtn(
                        icon: mode == LoopMode.one
                            ? Icons.repeat_one
                            : Icons.repeat,
                        color: mode != LoopMode.off ? accent : borderColor,
                        size: 24,
                        onTap: () {
                          if (mode == LoopMode.off) {
                            widget.player.setLoopMode(LoopMode.all);
                          } else if (mode == LoopMode.all) {
                            widget.player.setLoopMode(LoopMode.one);
                          } else {
                            widget.player.setLoopMode(LoopMode.off);
                          }
                        },
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderArt(Color accent) {
    return Container(
      color: accent.withOpacity(0.08),
      child: Icon(Icons.music_note, size: 80, color: accent),
    );
  }
}

// ── Pixel square slider thumb ──────────────────────────────────────────────
class _PixelThumb extends SliderComponentShape {
  const _PixelThumb();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(14, 14);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final paint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.pink
      ..style = PaintingStyle.fill;
    // Square thumb instead of circle
    canvas.drawRect(
      Rect.fromCenter(center: center, width: 12, height: 12),
      paint,
    );
  }
}

// ── Flat pixel track (no rounded ends) ────────────────────────────────────
class _PixelTrack extends SliderTrackShape {
  const _PixelTrack();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 4;
    final trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(
      offset.dx,
      trackTop,
      parentBox.size.width,
      trackHeight,
    );
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final canvas = context.canvas;

    // Inactive (right of thumb)
    canvas.drawRect(
      Rect.fromLTRB(
          trackRect.left, trackRect.top, trackRect.right, trackRect.bottom),
      Paint()..color = sliderTheme.inactiveTrackColor ?? Colors.grey,
    );
    // Active (left of thumb)
    canvas.drawRect(
      Rect.fromLTRB(trackRect.left, trackRect.top,
          thumbCenter.dx, trackRect.bottom),
      Paint()..color = sliderTheme.activeTrackColor ?? Colors.pink,
    );
  }
}

// ── Pixel control button ───────────────────────────────────────────────────
class _PixelControlBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _PixelControlBtn({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}

// ── Pixel playlist sheet (used inside player) ─────────────────────────────
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
    final ok = await DBService.addSongToPlaylist(
        playlistId: id, songId: widget.song.id);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          ok ? '${widget.song.title} added to $name' : 'Failed to add',
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
        backgroundColor: widget.isDark
            ? PixelColors.darkCard
            : PixelColors.lightSurface,
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
            hintStyle:
                const TextStyle(fontFamily: 'monospace', fontSize: 11),
            filled: true,
            fillColor: widget.isDark
                ? PixelColors.darkSurface
                : PixelColors.lightCard,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: accent, width: 2)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL',
                  style:
                      TextStyle(fontFamily: 'monospace', letterSpacing: 1))),
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

// ── Queue Bottom Sheet ─────────────────────────────────────────────────────
class QueueBottomSheet extends StatefulWidget {
  final Song currentSong;
  final Function(Song) onSongSelected;

  const QueueBottomSheet({
    super.key,
    required this.currentSong,
    required this.onSongSelected,
  });

  @override
  State<QueueBottomSheet> createState() => _QueueBottomSheetState();
}

class _QueueBottomSheetState extends State<QueueBottomSheet> {
  late List<Song> _queue;
  Song? _currentPlayingSong;

  @override
  void initState() {
    super.initState();
    _queue = List.from(AudioManager.instance.currentQueue);
    _currentPlayingSong = widget.currentSong;
  }

  void _refreshQueue() {
    setState(() {
      _queue = List.from(AudioManager.instance.currentQueue);
      _currentPlayingSong = AudioManager.instance.currentSong;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? PixelColors.neonPink : PixelColors.accentPink;
    final bg = isDark ? PixelColors.darkSurface : PixelColors.lightSurface;
    final cardColor = isDark ? PixelColors.darkCard : PixelColors.lightCard;
    final border = isDark ? PixelColors.darkBorder : PixelColors.lightBorder;
    final textPrimary = isDark ? Colors.white : PixelColors.darkBg;

    final queuedSongs =
        _queue.where((s) => s.id != _currentPlayingSong?.id).toList();
    final hasQueue = queuedSongs.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: accent, width: 3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(width: 4, height: 18, color: accent),
                const SizedBox(width: 8),
                Text('QUEUE',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: accent,
                        letterSpacing: 2,
                        fontFamily: 'monospace')),
                const Spacer(),
                if (hasQueue)
                  GestureDetector(
                    onTap: () async {
                      await AudioManager.instance.clearQueue();
                      _refreshQueue();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        border: Border.all(color: Colors.red, width: 1),
                      ),
                      child: const Text('CLEAR ALL',
                          style: TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                              letterSpacing: 1)),
                    ),
                  ),
              ],
            ),
          ),

          if (_queue.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                children: [
                  Icon(Icons.queue_music, size: 64, color: border),
                  const SizedBox(height: 12),
                  Text('QUEUE IS EMPTY',
                      style: TextStyle(
                          color: border,
                          fontFamily: 'monospace',
                          letterSpacing: 2,
                          fontSize: 11)),
                ],
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                children: [
                  // Now playing card
                  if (_currentPlayingSong != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.08),
                        border: Border.all(color: accent, width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: accent.withOpacity(0.2),
                              blurRadius: 0,
                              offset: const Offset(3, 3))
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        leading: Stack(
                          alignment: Alignment.center,
                          children: [
                            _currentPlayingSong!.imageUrl != null
                                ? Image.network(
                                    _currentPlayingSong!.imageUrl!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) =>
                                        _thumb(accent),
                                  )
                                : _thumb(accent),
                            Container(
                              width: 50,
                              height: 50,
                              color: accent.withOpacity(0.65),
                              child: const Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 28),
                            ),
                          ],
                        ),
                        title: Text(
                          _currentPlayingSong!.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: accent,
                            fontSize: 13,
                            fontFamily: 'monospace',
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          _currentPlayingSong!.artist ?? '',
                          style: TextStyle(
                              color: accent.withOpacity(0.7),
                              fontSize: 10,
                              fontFamily: 'monospace'),
                        ),
                        trailing: Icon(Icons.play_circle_filled,
                            color: accent, size: 24),
                      ),
                    ),

                  if (hasQueue) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text('NEXT UP',
                          style: TextStyle(
                              color: border,
                              fontSize: 10,
                              letterSpacing: 2,
                              fontFamily: 'monospace')),
                    ),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      onReorder: (oldIndex, newIndex) async {
                        await AudioManager.instance
                            .reorderQueue(oldIndex, newIndex);
                        _refreshQueue();
                      },
                      itemCount: queuedSongs.length,
                      itemBuilder: (context, index) {
                        final song = queuedSongs[index];
                        final actualIndex =
                            _queue.indexWhere((s) => s.id == song.id);
                        return Container(
                          key: ValueKey(song.id),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: cardColor,
                            border:
                                Border.all(color: border, width: 2),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            leading: song.imageUrl != null
                                ? Image.network(song.imageUrl!,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) =>
                                        _thumb(accent, size: 44))
                                : _thumb(accent, size: 44),
                            title: Text(song.title,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                    fontSize: 12,
                                    fontFamily: 'monospace'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                                song.artist ?? '',
                                style: TextStyle(
                                    color: border,
                                    fontSize: 10,
                                    fontFamily: 'monospace'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            trailing: IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 18),
                              color: Colors.red.withOpacity(0.7),
                              onPressed: () async {
                                await AudioManager.instance
                                    .removeFromQueue(actualIndex);
                                _refreshQueue();
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

          // Footer count pill
          if (_queue.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.08),
                border: Border.all(color: accent.withOpacity(0.3), width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.playlist_play, color: accent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('${_queue.length} SONGS IN QUEUE',
                        style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    color: accent,
                    child: Text('${queuedSongs.length} NEXT',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            letterSpacing: 1)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _thumb(Color accent, {double size = 50}) {
    return Container(
      width: size,
      height: size,
      color: accent.withOpacity(0.1),
      child:
          Icon(Icons.music_note, color: accent, size: size * 0.5),
    );
  }
}