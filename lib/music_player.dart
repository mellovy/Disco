import 'dart:async';
import 'package:flutter/material.dart';
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

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  late Song _currentSong;
  late bool _isFavorite;
  late StreamSubscription<Song?> _songSub;

  double? _dragValue;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    // Default to passed song, but grab current if playing from queue
    _currentSong = AudioManager.instance.currentSong ?? widget.song;
    _isFavorite = _currentSong.isFavorite;

    // Listen to queue changes (Next/Prev) to update UI dynamically
    _songSub = AudioManager.instance.currentSongStream.listen((song) {
      if (song != null && mounted && song.id != _currentSong.id) {
        setState(() {
          _currentSong = song;
          _isFavorite = song.isFavorite;
        });
      }
    });
  }

  @override
  void dispose() {
    _songSub.cancel();
    super.dispose();
  }

  void _toggleFavorite() async {
    final success =
        await DBService.toggleFavorite(widget.userId, _currentSong.id);
    if (success && mounted) {
      setState(() {
        _isFavorite = !_isFavorite;
        _currentSong.isFavorite = _isFavorite;
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
      body: SingleChildScrollView(
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
                    child: _currentSong.imageUrl != null
                        ? Image.network(
                            _currentSong.imageUrl!,
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

              // Title & Artist (Now Reactive)
              Text(_currentSong.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textPrimary)),
              const SizedBox(height: 4),
              Text(_currentSong.artist ?? '',
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
                  // Shuffle Button
                  StreamBuilder<bool>(
                    stream: widget.player.shuffleModeEnabledStream,
                    builder: (context, snapshot) {
                      final isShuffle = snapshot.data ?? false;
                      return IconButton(
                        icon: Icon(Icons.shuffle,
                            color: isShuffle ? Colors.purple : Colors.grey),
                        onPressed: () async {
                          final enable = !isShuffle;
                          if (enable) await widget.player.shuffle();
                          await widget.player.setShuffleModeEnabled(enable);
                        },
                      );
                    },
                  ),

                  // Previous Button
                  IconButton(
                    icon: Icon(Icons.skip_previous, color: textPrimary),
                    iconSize: 36,
                    onPressed: () {
                      if (widget.player.hasPrevious) {
                        widget.player.seekToPrevious();
                      } else {
                        widget.player.seek(Duration.zero); // Reset if at start
                      }
                    },
                  ),

                  // Play/Pause Button
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

                  // Next Button
                  IconButton(
                    icon: Icon(Icons.skip_next, color: textPrimary),
                    iconSize: 36,
                    onPressed: () {
                      if (widget.player.hasNext) {
                        widget.player.seekToNext();
                      }
                    },
                  ),

                  // Repeat Button
                  StreamBuilder<LoopMode>(
                    stream: widget.player.loopModeStream,
                    builder: (context, snapshot) {
                      final mode = snapshot.data ?? LoopMode.off;
                      return IconButton(
                        icon: Icon(
                          mode == LoopMode.one ? Icons.repeat_one : Icons.repeat,
                          color: mode != LoopMode.off ? Colors.purple : Colors.grey,
                        ),
                        onPressed: () {
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