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
  late StreamSubscription<List<Song>> _queueSub;

  double? _dragValue;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentSong = AudioManager.instance.currentSong ?? widget.song;
    _isFavorite = _currentSong.isFavorite;

    _songSub = AudioManager.instance.currentSongStream.listen((song) {
      if (song != null && mounted && song.id != _currentSong.id) {
        setState(() {
          _currentSong = song;
          _isFavorite = song.isFavorite;
        });
      }
    });
    
    _queueSub = AudioManager.instance.queueStream.listen((queue) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _songSub.cancel();
    _queueSub.cancel();
    super.dispose();
  }

  void _toggleFavorite() async {
    final success = await DBService.toggleFavorite(widget.userId, _currentSong.id);
    if (success && mounted) {
      setState(() {
        _isFavorite = !_isFavorite;
        _currentSong.isFavorite = _isFavorite;
      });
    }
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
        title: Text(
          "Now Playing",
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: Icon(Icons.queue_music, color: Colors.purple, size: 28),
                  onPressed: _showQueue,
                ),
                if (AudioManager.instance.currentQueue.isNotEmpty)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        '${AudioManager.instance.currentQueue.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.red,
                size: 28,
              ),
              onPressed: _toggleFavorite,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
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
                        spreadRadius: 4,
                      ),
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
                              child: const Icon(Icons.music_note, size: 100, color: Colors.purple),
                            ),
                          )
                        : Container(
                            color: Colors.purple.withOpacity(0.15),
                            child: const Icon(Icons.music_note, size: 100, color: Colors.purple),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                _currentSong.title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                _currentSong.artist ?? '',
                style: const TextStyle(fontSize: 18, color: Colors.purple),
              ),
              const SizedBox(height: 24),
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
                          : position.inMilliseconds.toDouble().clamp(0.0, maxMs > 0 ? maxMs : 0.0);

                      return Column(
                        children: [
                          Slider(
                            activeColor: Colors.purple,
                            inactiveColor: Colors.purple.withOpacity(isDark ? 0.3 : 0.2),
                            value: sliderValue,
                            max: maxMs > 0 ? maxMs : 1.0,
                            onChanged: maxMs > 0
                                ? (v) => setState(() {
                                    _isDragging = true;
                                    _dragValue = v;
                                  })
                                : null,
                            onChangeEnd: (v) async {
                              await widget.player.seek(Duration(milliseconds: v.toInt()));
                              setState(() {
                                _isDragging = false;
                                _dragValue = null;
                              });
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _fmt(_isDragging ? Duration(milliseconds: _dragValue!.toInt()) : position),
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                Text(_fmt(total), style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  StreamBuilder<bool>(
                    stream: widget.player.shuffleModeEnabledStream,
                    builder: (context, snapshot) {
                      final isShuffle = snapshot.data ?? false;
                      return IconButton(
                        icon: Icon(Icons.shuffle, color: isShuffle ? Colors.purple : Colors.grey),
                        iconSize: 28,
                        onPressed: () async {
                          final enable = !isShuffle;
                          if (enable) await widget.player.shuffle();
                          await widget.player.setShuffleModeEnabled(enable);
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_previous, color: textPrimary),
                    iconSize: 36,
                    onPressed: () {
                      if (widget.player.hasPrevious) {
                        widget.player.seekToPrevious();
                      } else {
                        widget.player.seek(Duration.zero);
                      }
                    },
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
                            playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            size: 80,
                            color: Colors.purple,
                          ),
                          onPressed: () => playing ? widget.player.pause() : widget.player.play(),
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_next, color: textPrimary),
                    iconSize: 36,
                    onPressed: () {
                      if (widget.player.hasNext) {
                        widget.player.seekToNext();
                      }
                    },
                  ),
                  StreamBuilder<LoopMode>(
                    stream: widget.player.loopModeStream,
                    builder: (context, snapshot) {
                      final mode = snapshot.data ?? LoopMode.off;
                      return IconButton(
                        icon: Icon(
                          mode == LoopMode.one ? Icons.repeat_one : Icons.repeat,
                          color: mode != LoopMode.off ? Colors.purple : Colors.grey,
                        ),
                        iconSize: 28,
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
              Row(
                children: [
                  Icon(Icons.volume_down, color: isDark ? Colors.grey[400] : Colors.purple),
                  Expanded(
                    child: StreamBuilder<double>(
                      stream: widget.player.volumeStream,
                      builder: (context, snapshot) {
                        return Slider(
                          value: snapshot.data ?? 1.0,
                          activeColor: Colors.purple,
                          inactiveColor: Colors.purple.withOpacity(isDark ? 0.3 : 0.2),
                          onChanged: (v) => widget.player.setVolume(v),
                        );
                      },
                    ),
                  ),
                  Icon(Icons.volume_up, color: isDark ? Colors.grey[400] : Colors.purple),
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
    final sheetBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? const Color(0xFF2A2A3E) : Colors.white;
    final dividerColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    final queuedSongs = _queue.where((song) => song.id != _currentPlayingSong?.id).toList();
    final hasQueue = queuedSongs.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[600] : Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.queue_music, color: Colors.purple, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Queue',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                  ],
                ),
                if (hasQueue)
                  TextButton.icon(
                    onPressed: () async {
                      await AudioManager.instance.clearQueue();
                      _refreshQueue();
                    },
                    icon: Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    label: Text('Clear All', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                  ),
              ],
            ),
          ),
          if (_queue.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: Column(
                children: [
                  Icon(Icons.queue_music, size: 80, color: Colors.purple.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'Your queue is empty',
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + next to songs to add to queue',
                    style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  if (_currentPlayingSong != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.purple.withOpacity(0.3), width: 1.5),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        leading: Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _currentPlayingSong!.imageUrl != null
                                  ? Image.network(
                                      _currentPlayingSong!.imageUrl!,
                                      width: 55,
                                      height: 55,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Container(
                                        width: 55,
                                        height: 55,
                                        color: Colors.purple.withOpacity(0.1),
                                        child: Icon(Icons.music_note, color: Colors.purple, size: 28),
                                      ),
                                    )
                                  : Container(
                                      width: 55,
                                      height: 55,
                                      color: Colors.purple.withOpacity(0.1),
                                      child: Icon(Icons.music_note, color: Colors.purple, size: 28),
                                    ),
                            ),
                            Container(
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                            ),
                          ],
                        ),
                        title: Text(
                          _currentPlayingSong!.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _currentPlayingSong!.artist ?? 'Unknown Artist',
                            style: TextStyle(
                              color: Colors.purple,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing: Icon(Icons.play_circle_filled, color: Colors.purple, size: 28),
                      ),
                    ),
                  if (hasQueue) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 8),
                      child: Text(
                        'Next up',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      onReorder: (oldIndex, newIndex) async {
                        await AudioManager.instance.reorderQueue(oldIndex, newIndex);
                        _refreshQueue();
                        
                        final currentSong = AudioManager.instance.currentSong;
                        if (currentSong != null && currentSong.id != _currentPlayingSong?.id) {
                          widget.onSongSelected(currentSong);
                        }
                      },
                      itemCount: queuedSongs.length,
                      itemBuilder: (context, index) {
                        final song = queuedSongs[index];
                        final actualIndex = _queue.indexWhere((s) => s.id == song.id);
                        
                        return Container(
                          key: ValueKey(song.id),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: dividerColor, width: 1),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: song.imageUrl != null
                                  ? Image.network(
                                      song.imageUrl!,
                                      width: 45,
                                      height: 45,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Container(
                                        width: 45,
                                        height: 45,
                                        color: Colors.purple.withOpacity(0.1),
                                        child: Icon(Icons.music_note, color: Colors.purple, size: 24),
                                      ),
                                    )
                                  : Container(
                                      width: 45,
                                      height: 45,
                                      color: Colors.purple.withOpacity(0.1),
                                      child: Icon(Icons.music_note, color: Colors.purple, size: 24),
                                    ),
                            ),
                            title: Text(
                              song.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              song.artist ?? 'Unknown Artist',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.close_rounded, size: 20),
                              color: Colors.red.withOpacity(0.7),
                              onPressed: () async {
                                await AudioManager.instance.removeFromQueue(actualIndex);
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
          if (_queue.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withOpacity(0.1),
                    Colors.purple.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purple.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.playlist_play, color: Colors.purple, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Songs',
                          style: TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${_queue.length} songs in queue',
                          style: TextStyle(color: Colors.purple, fontSize: 13, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${queuedSongs.length} next',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}