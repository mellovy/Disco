import 'package:flutter/material.dart';
import 'models/song.dart';
import 'services/audio_manager.dart';

class MusicPlayerPage extends StatefulWidget {
  final Song song;
  final VoidCallback? onClose; // Added onClose
  const MusicPlayerPage({super.key, required this.song, this.onClose});
  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  double _position = 0.0;
  bool _isPlaying = false;
  late final AudioManager _audioManager;

  @override
  void initState() {
    super.initState();
    _audioManager = AudioManager.instance;
    _initAudio();
  }

  Future<void> _initAudio() async {
    if (widget.song.audioUrl != null) {
      await _audioManager.setSong(widget.song);
      _audioManager.positionFractionStream.listen((f) => setState(() => _position = f));
      _audioManager.playingStream.listen((p) => setState(() => _isPlaying = p));
      await _audioManager.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0E6FF),
      body: SafeArea(
        child: Column(
          children: [
            Align(alignment: Alignment.topLeft, child: IconButton(icon: const Icon(Icons.keyboard_arrow_down), onPressed: widget.onClose ?? () => Navigator.pop(context))),
            const SizedBox(height: 20),
            Container(width: 260, height: 260, color: Colors.white, child: const Icon(Icons.image, size: 100, color: Colors.grey)),
            const SizedBox(height: 20),
            Text(widget.song.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(widget.song.artist ?? 'Unknown Artist'),
            Slider(value: _position, onChanged: (v) => _audioManager.seekFraction(v)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.skip_previous, size: 40), onPressed: () {}),
                IconButton(icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 60), onPressed: () => _isPlaying ? _audioManager.pause() : _audioManager.play()),
                IconButton(icon: const Icon(Icons.skip_next, size: 40), onPressed: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}