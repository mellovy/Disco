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
  late bool _isFavorite;
  double? _dragValue; 
  bool _isDragging = false; 

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.song.isFavorite;
  }

  // FIX: Direct state update to ensure the heart icon changes immediately
  void _toggleFavorite() async {
    setState(() {
      _isFavorite = !_isFavorite;
      widget.song.isFavorite = _isFavorite;
    });

    bool success = await DBService.toggleFavorite(widget.userId, widget.song.id);
    if (!success) {
      // Revert if the database update failed
      setState(() {
        _isFavorite = !_isFavorite;
        widget.song.isFavorite = _isFavorite;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update favorites"))
      );
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1E6FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 35, color: Colors.black),
          onPressed: widget.onClose,
        ),
        title: const Text("Now Playing", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red),
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
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: MediaQuery.of(context).size.width * 0.75,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.2), blurRadius: 20, spreadRadius: 2)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.network(
                      widget.song.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(color: Colors.grey[300], child: const Icon(Icons.music_note, size: 100)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(widget.song.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(widget.song.artist ?? '', style: const TextStyle(fontSize: 18, color: Colors.purple)),
              const SizedBox(height: 30),

              // FIX: This Logic prevents the "Reset to Beginning" bug
              StreamBuilder<Duration>(
                stream: widget.player.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final total = widget.player.duration ?? Duration.zero;
                  
                  return Column(
                    children: [
                      Slider(
                        activeColor: Colors.purple,
                        inactiveColor: Colors.purple[100],
                        // While dragging, use the drag value. Otherwise, use stream position.
                        value: _isDragging 
                            ? _dragValue!.clamp(0.0, total.inMilliseconds.toDouble())
                            : position.inMilliseconds.toDouble().clamp(0.0, total.inMilliseconds.toDouble()),
                        max: total.inMilliseconds.toDouble() > 0 ? total.inMilliseconds.toDouble() : 1.0,
                        onChanged: (v) {
                          setState(() {
                            _isDragging = true;
                            _dragValue = v;
                          });
                        },
                        onChangeEnd: (v) async {
                          await widget.player.seek(Duration(milliseconds: v.toInt()));
                          setState(() {
                            _isDragging = false;
                          });
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(position)),
                            Text(_formatDuration(total)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(icon: Icon(Icons.shuffle, color: _isShuffle ? Colors.purple : Colors.grey), onPressed: () => setState(() => _isShuffle = !_isShuffle)),
                  IconButton(icon: const Icon(Icons.skip_previous, size: 40), onPressed: () {}),
                  StreamBuilder<PlayerState>(
                    stream: widget.player.playerStateStream,
                    builder: (context, snapshot) {
                      final playing = snapshot.data?.playing ?? false;
                      return IconButton(
                        icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 75, color: Colors.purple),
                        onPressed: () => playing ? widget.player.pause() : widget.player.play(),
                      );
                    },
                  ),
                  IconButton(icon: const Icon(Icons.skip_next, size: 40), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.repeat, color: Colors.grey), onPressed: () {}),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.volume_down, color: Colors.purple),
                  Expanded(
                    child: Slider(
                      value: widget.player.volume,
                      activeColor: Colors.purple,
                      onChanged: (v) => setState(() => widget.player.setVolume(v)),
                    ),
                  ),
                  const Icon(Icons.volume_up, color: Colors.purple),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}