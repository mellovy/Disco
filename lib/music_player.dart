import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'models/song.dart';
import 'services/db_service.dart';

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

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  bool _isShuffle = false;
  bool _isRepeat = false;
  late bool _isFavorite;

  double? _dragValue;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.song.isFavorite;
  }

  void _toggleFavorite() async {
    final success =
        await DBService.toggleFavorite(widget.userId, widget.song.id);
    if (success && mounted) {
      setState(() {
        _isFavorite = !_isFavorite;
        widget.song.isFavorite = _isFavorite;
      });
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textPrimary = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_down, size: 35, color: textPrimary),
          onPressed: widget.onClose,
        ),
        title: Text("Now Playing",
            style:
                TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.red),
            onPressed: _toggleFavorite,
          )
        ],
      ),
      body: SingleChildScrollView( // ✅ FIX HERE
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // Album Art
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: MediaQuery.of(context).size.width * 0.75,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 25,
                          spreadRadius: 4)
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: widget.song.imageUrl != null
                        ? Image.network(
                            widget.song.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                                color: Colors.purple.withOpacity(0.15),
                                child: const Icon(Icons.music_note,
                                    size: 100, color: Colors.purple)),
                          )
                        : Container(
                            color: Colors.purple.withOpacity(0.15),
                            child: const Icon(Icons.music_note,
                                size: 100, color: Colors.purple)),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Title & Artist
              Text(widget.song.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textPrimary)),
              const SizedBox(height: 4),
              Text(widget.song.artist ?? '',
                  style: const TextStyle(fontSize: 18, color: Colors.purple)),
              const SizedBox(height: 24),

              // Seek bar
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
                          Slider(
                            activeColor: Colors.purple,
                            inactiveColor:
                                Colors.purple.withOpacity(isDark ? 0.3 : 0.2),
                            value: sliderValue,
                            max: maxMs > 0 ? maxMs : 1.0,
                            onChanged: maxMs > 0
                                ? (v) => setState(() {
                                      _isDragging = true;
                                      _dragValue = v;
                                    })
                                : null,
                            onChangeEnd: (v) async {
                              await widget.player
                                  .seek(Duration(milliseconds: v.toInt()));
                              setState(() {
                                _isDragging = false;
                                _dragValue = null;
                              });
                            },
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _fmt(_isDragging
                                      ? Duration(
                                          milliseconds: _dragValue!.toInt())
                                      : position),
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                                Text(_fmt(total),
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12)),
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

              // Playback controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.shuffle,
                        color: _isShuffle ? Colors.purple : Colors.grey),
                    onPressed: () =>
                        setState(() => _isShuffle = !_isShuffle),
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_previous, color: textPrimary),
                    iconSize: 36,
                    onPressed: () {},
                  ),
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: StreamBuilder<PlayerState>(
                      stream: widget.player.playerStateStream,
                      builder: (context, snapshot) {
                        final playing = snapshot.data?.playing ?? false;
                        return IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            playing
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            size: 80,
                            color: Colors.purple,
                          ),
                          onPressed: () => playing
                              ? widget.player.pause()
                              : widget.player.play(),
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_next, color: textPrimary),
                    iconSize: 36,
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.repeat,
                        color: _isRepeat ? Colors.purple : Colors.grey),
                    onPressed: () =>
                        setState(() => _isRepeat = !_isRepeat),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Volume
              Row(
                children: [
                  Icon(Icons.volume_down,
                      color: isDark ? Colors.grey[400] : Colors.purple),
                  Expanded(
                    child: StreamBuilder<double>(
                      stream: widget.player.volumeStream,
                      builder: (context, snapshot) {
                        return Slider(
                          value: snapshot.data ?? 1.0,
                          activeColor: Colors.purple,
                          inactiveColor: Colors.purple
                              .withOpacity(isDark ? 0.3 : 0.2),
                          onChanged: (v) => widget.player.setVolume(v),
                        );
                      },
                    ),
                  ),
                  Icon(Icons.volume_up,
                      color: isDark ? Colors.grey[400] : Colors.purple),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}