import 'package:flutter/material.dart';
import 'models/song.dart';
import 'dart:async';

import 'services/audio_manager.dart';

typedef VoidSongCallback = void Function();

class MusicPlayerContent extends StatelessWidget {
  final Song song;
  final double position;
  final bool isPlaying;
  final ValueChanged<double>? onSeek;
  final VoidCallback? onPlayPause;
  final VoidCallback? onClose;

  const MusicPlayerContent({super.key, required this.song, this.position = 0.0, this.isPlaying = false, this.onSeek, this.onPlayPause, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Small down-chevron to dismiss
        Align(
          alignment: Alignment.topLeft,
          child: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 28),
            onPressed: onClose ?? () => Navigator.of(context).maybePop(),
          ),
        ),

        // Big artwork box
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Container(
            height: 260,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
            ),
            child: Center(
              child: song.imageUrl == null
                  ? const Icon(Icons.image, size: 96, color: Colors.grey)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(song.imageUrl!, fit: BoxFit.cover),
                    ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Title / artist / action
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(song.artist ?? 'Artist Name', style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: () {},
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Progress slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Slider(
            value: position,
            onChanged: onSeek,
            min: 0,
            max: 1,
            activeColor: Colors.blueAccent,
            inactiveColor: Colors.grey.shade300,
          ),
        ),

        const SizedBox(height: 8),

        // Controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                iconSize: 28,
                icon: const Icon(Icons.skip_previous),
                onPressed: () {},
              ),
              GestureDetector(
                onTap: onPlayPause,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(36), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)]),
                  child: Center(
                    child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 40),
                  ),
                ),
              ),
              IconButton(
                iconSize: 28,
                icon: const Icon(Icons.skip_next),
                onPressed: () {},
              ),
            ],
          ),
        ),

        const Spacer(),
      ],
    );
  }
}

class MusicPlayerPage extends StatefulWidget {
  final Song song;
  const MusicPlayerPage({super.key, required this.song});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  double _position = 0.0; // 0.0 - 1.0
  bool _isPlaying = false;
  bool _loadFailed = false;
  late final AudioManager _audioManager;
  StreamSubscription<double>? _posSub;
  StreamSubscription<bool>? _playingSub;
  // duration handled via AudioPlayer.duration when needed

  @override
  void initState() {
    super.initState();
    _audioManager = AudioManager.instance;
    _initAudio();
  }

  Future<void> _initAudio() async {
    final url = widget.song.audioUrl;
    if (url != null && url.isNotEmpty) {
      try {
          await _audioManager.setSong(widget.song);

          _posSub = _audioManager.positionFractionStream.listen((fraction) {
            setState(() => _position = fraction);
          });
          _playingSub = _audioManager.playingStream.listen((playing) {
            setState(() => _isPlaying = playing);
          });

          // Start playing automatically
          await _audioManager.play();
      } catch (e, st) {
        // Log and surface a user-friendly message so we can debug asset/network issues
        _loadFailed = true;
        // print to console for developer
        // ignore: avoid_print
        print('MusicPlayer: error loading audio "$url": $e\n$st');
        // show a SnackBar after the first frame so context is available
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final messenger = ScaffoldMessenger.maybeOf(context);
          messenger?.showSnackBar(SnackBar(content: Text('Failed to load audio: ${e.toString()}')));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0E6FF),
      body: SafeArea(
        child: MusicPlayerContent(
          song: widget.song,
          position: _position,
          isPlaying: _isPlaying,
          onSeek: (fraction) async {
            await _audioManager.seekFraction(fraction);
          },
          onPlayPause: () async {
            if (_loadFailed) {
              // if load failed, try re-initializing
              await _initAudio();
              return;
            }

            // Optimistically update UI so button responds immediately.
            // Save the previous value so we can revert on error.
            final previousPlaying = _isPlaying;
            final newPlaying = !previousPlaying;
            setState(() => _isPlaying = newPlaying);
            try {
              if (newPlaying) {
                await _audioManager.play();
              } else {
                await _audioManager.pause();
              }
            } catch (e) {
              // revert UI change on error and show message
              setState(() => _isPlaying = previousPlaying);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final messenger = ScaffoldMessenger.maybeOf(context);
                messenger?.showSnackBar(SnackBar(content: Text('Playback error: ${e.toString()}')));
              });
            }
          },
          onClose: () {
            // Don't stop audio on close; just dismiss the player UI
            Navigator.of(context).maybePop();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _playingSub?.cancel();
    super.dispose();
  }
}
