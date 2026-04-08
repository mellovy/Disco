import 'dart:async';

import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

class AudioManager {
  AudioManager._internal();

  static final AudioManager instance = AudioManager._internal();

  final AudioPlayer _player = AudioPlayer();
  Song? _currentSong;

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

  Song? get currentSong => _currentSong;

  Future<void> setSong(Song song) async {
    if (_currentSong?.audioUrl == song.audioUrl) return;
    _currentSong = song;
    final url = song.audioUrl;
    if (url == null || url.isEmpty) return;
    if (url.startsWith('http')) {
      await _player.setUrl(url);
    } else {
      await _player.setAsset(url);
    }
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();

  Future<void> seekFraction(double fraction) async {
    final dur = _player.duration;
    if (dur != null) {
      final target = Duration(milliseconds: (fraction * dur.inMilliseconds).round());
      await _player.seek(target);
    }
  }

  Future<void> dispose() => _player.dispose();
}
