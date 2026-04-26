import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

class AudioManager {
  AudioManager._internal() {
    _player.sequenceStateStream.listen((state) {
      if (state?.currentSource?.tag is Song) {
        final song = state!.currentSource!.tag as Song;
        _currentPlayingId = song.id;
        _updateQueueFromPlayer();
      } else if (state?.currentSource == null) {
        _currentPlayingId = -1;
        _currentQueue.clear();
      }
    });
  }

  static final AudioManager instance = AudioManager._internal();

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  ConcatenatingAudioSource? _playlist;
  int _currentPlayingId = -1;
  
  List<Song> _currentQueue = [];
  
  int get currentPlayingId => _currentPlayingId;
  
  List<Song> get currentQueue => List.unmodifiable(_currentQueue);
  
  final _queueStreamController = StreamController<List<Song>>.broadcast();
  Stream<List<Song>> get queueStream => _queueStreamController.stream;

  Song? get currentSong {
    final tag = _player.sequenceState?.currentSource?.tag;
    return tag as Song?;
  }

  Stream<Song?> get currentSongStream => _player.sequenceStateStream.map((state) {
    if (state == null || state.currentSource == null) return null;
    return state.currentSource!.tag as Song?;
  });

  void _updateQueueFromPlayer() {
    final sequence = _player.sequenceState?.sequence;
    if (sequence != null) {
      final newQueue = <Song>[];
      for (var source in sequence) {
        if (source.tag is Song) {
          newQueue.add(source.tag as Song);
        }
      }
      _currentQueue = newQueue;
      _queueStreamController.add(_currentQueue);
    }
  }

  Future<void> setSong(Song song) async {
    if (_currentPlayingId == song.id && _playlist != null && _playlist!.length == 1) return;

    _currentPlayingId = song.id;

    final url = song.audioUrl;
    if (url == null || url.isEmpty) return;

    final source = AudioSource.uri(Uri.parse(url), tag: song);
    
    _playlist = ConcatenatingAudioSource(children: [source]);

    try {
      await _player.stop();
      await _player.setAudioSource(_playlist!);
      await _player.play();
      _updateQueueFromPlayer();
    } on PlayerInterruptedException catch (e) {
      print("Interrupted setSong: $e");
    } catch (e) {
      print("Audio error: $e");
    }
  }

  Future<void> addToQueue(Song song) async {
    final url = song.audioUrl;
    if (url == null || url.isEmpty) return;

    final source = AudioSource.uri(Uri.parse(url), tag: song);

    if (_playlist == null) {
      _playlist = ConcatenatingAudioSource(children: [source]);
      _currentPlayingId = song.id;
      try {
        await _player.setAudioSource(_playlist!);
        await _player.play();
        _updateQueueFromPlayer();
      } catch (e) {
        print("Audio error: $e");
      }
    } else {
      await _playlist!.add(source);
      
      if (!_player.playing && _player.processingState == ProcessingState.completed) {
        _player.seekToNext();
        _player.play();
      }
      _updateQueueFromPlayer();
    }
  }

  Future<void> addMultipleToQueue(List<Song> songs) async {
    for (var song in songs) {
      await addToQueue(song);
    }
  }

  Future<void> removeFromQueue(int index) async {
    if (_playlist != null && index < _playlist!.length) {
      final removedSource = _playlist!.sequence[index];
      await _playlist!.removeAt(index);
      
      if (removedSource.tag is Song && 
          (removedSource.tag as Song).id == currentPlayingId) {
        await _player.stop();
        _currentPlayingId = -1;
      }
      
      _updateQueueFromPlayer();
      _queueStreamController.add(_currentQueue);
    }
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (_playlist == null) return;
    
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final source = await _playlist!.sequence[oldIndex];
    await _playlist!.removeAt(oldIndex);
    await _playlist!.insert(newIndex, source);
    
    _updateQueueFromPlayer();
    _queueStreamController.add(_currentQueue);
  }

  Future<void> clearQueue() async {
    if (_playlist != null) {
      await _playlist!.clear();
      _currentQueue.clear();
      _queueStreamController.add(_currentQueue);
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

  Future<void> stop() async {
    await _player.stop();
    if (_playlist != null) {
      await _playlist!.clear();
    }
    _currentPlayingId = -1;
    _currentQueue.clear();
    _queueStreamController.add(_currentQueue);
  }

  Future<void> seekFraction(double fraction) async {
    final dur = _player.duration;
    if (dur != null) {
      final target = Duration(milliseconds: (fraction * dur.inMilliseconds).round());
      await _player.seek(target);
    }
  }

  Future<void> dispose() async {
    await _queueStreamController.close();
    await _player.dispose();
  }
}