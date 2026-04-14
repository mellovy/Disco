import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

class AudioManager {
  AudioManager._internal() {
    // Keep our internal tracker synced with just_audio (e.g. when auto-advancing to next track)
    _player.sequenceStateStream.listen((state) {
      if (state?.currentSource?.tag is Song) {
        final song = state!.currentSource!.tag as Song;
        _currentPlayingId = song.id;
      } else if (state?.currentSource == null) {
        _currentPlayingId = -1;
      }
    });
  }

  static final AudioManager instance = AudioManager._internal();

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  ConcatenatingAudioSource? _playlist;
  int _currentPlayingId = -1;

  // Expose the currently assigned playing ID to prevent race conditions
  int get currentPlayingId => _currentPlayingId;

  Song? get currentSong {
    final tag = _player.sequenceState?.currentSource?.tag;
    return tag as Song?;
  }

  Stream<Song?> get currentSongStream => _player.sequenceStateStream.map((state) {
    if (state == null || state.currentSource == null) return null;
    return state.currentSource!.tag as Song?;
  });

  // Play a single song, clearing any existing queue
  Future<void> setSong(Song song) async {
    // Ignore if already playing this exact single song
    if (_currentPlayingId == song.id && _playlist != null && _playlist!.length == 1) return;

    _currentPlayingId = song.id;

    final url = song.audioUrl;
    if (url == null || url.isEmpty) return;

    final source = AudioSource.uri(Uri.parse(url), tag: song);
    
    // Create a fresh queue with just this 1 song
    _playlist = ConcatenatingAudioSource(children: [source]);

    try {
      await _player.stop();
      await _player.setAudioSource(_playlist!);
      await _player.play();
    } on PlayerInterruptedException catch (e) {
      print("Interrupted setSong: $e");
    } catch (e) {
      print("Audio error: $e");
    }
  }

  // Explicitly add a song to the end of the current queue
  Future<void> addToQueue(Song song) async {
    final url = song.audioUrl;
    if (url == null || url.isEmpty) return;

    final source = AudioSource.uri(Uri.parse(url), tag: song);

    if (_playlist == null) {
      // If nothing is playing at all, just play it
      _playlist = ConcatenatingAudioSource(children: [source]);
      _currentPlayingId = song.id;
      try {
        await _player.setAudioSource(_playlist!);
        await _player.play();
      } catch (e) {
        print("Audio error: $e");
      }
    } else {
      // Append to the existing queue
      await _playlist!.add(source);
      
      // If the player had stopped because it reached the end, jump to the new song and play
      if (!_player.playing && _player.processingState == ProcessingState.completed) {
        _player.seekToNext();
        _player.play();
      }
    }
  }

  Stream<double> get positionFractionStream async* {
    await for (final pos in _player.positionStream) {
      final dur = _player.duration;
      if (dur != null && dur.inMilliseconds > 0) {
        yield (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);
      } else {
        yield 0.0;
      }
    }
  }

  Stream<bool> get playingStream => _player.playerStateStream.map((s) => s.playing);

  Duration? get duration => _player.duration;

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();

  // Fully stop playback and clear the queue
  Future<void> stop() async {
    await _player.stop();
    if (_playlist != null) {
      await _playlist!.clear();
    }
    _currentPlayingId = -1;
  }

  Future<void> seekFraction(double fraction) async {
    final dur = _player.duration;
    if (dur != null) {
      final target = Duration(milliseconds: (fraction * dur.inMilliseconds).round());
      await _player.seek(target);
    }
  }

  Future<void> dispose() => _player.dispose();
}