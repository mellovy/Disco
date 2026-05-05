import 'dart:async';
import 'dart:math';
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
        _originalOrder.clear();
        _queueStreamController.add(List.unmodifiable(_currentQueue));
      }
    });

    _player.currentIndexStream.listen((_) => _updateQueueFromPlayer());
  }

  static final AudioManager instance = AudioManager._internal();

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  ConcatenatingAudioSource? _playlist;
  int _currentPlayingId = -1;

  List<Song> _currentQueue = [];
  List<Song> _originalOrder = []; // Original order before shuffle

  int get currentPlayingId => _currentPlayingId;
  int? get currentIndex => _player.currentIndex;

  List<Song> get currentQueue => List.unmodifiable(_currentQueue);

  final _queueStreamController = StreamController<List<Song>>.broadcast();
  Stream<List<Song>> get queueStream => _queueStreamController.stream;

  Song? get currentSong {
    final tag = _player.sequenceState?.currentSource?.tag;
    return tag as Song?;
  }

  Stream<Song?> get currentSongStream =>
      _player.sequenceStateStream.map((state) {
        if (state == null || state.currentSource == null) return null;
        return state.currentSource!.tag as Song?;
      });

  void _updateQueueFromPlayer() {
    final state = _player.sequenceState;
    if (state == null) return;

    // Use effectiveSequence when shuffled so UI reflects actual play order
    final sequence =
        _player.shuffleModeEnabled ? state.effectiveSequence : state.sequence;

    final newQueue = <Song>[];
    for (var source in sequence) {
      if (source.tag is Song) {
        newQueue.add(source.tag as Song);
      }
    }
    _currentQueue = newQueue;
    _queueStreamController.add(List.unmodifiable(_currentQueue));
  }

  /// Play a single song, clearing any existing queue.
  Future<void> setSong(Song song) async {
    _currentPlayingId = song.id;
    final url = song.audioUrl;
    if (url == null || url.isEmpty) return;

    final source = AudioSource.uri(Uri.parse(url), tag: song);
    _playlist = ConcatenatingAudioSource(children: [source]);
    _originalOrder = [song];

    try {
      await _player.setShuffleModeEnabled(false);
      await _player.setAudioSource(_playlist!, preload: true);
      await _player.play();
      _updateQueueFromPlayer();
    } on PlayerInterruptedException catch (e) {
      print("Interrupted setSong: $e");
    } catch (e) {
      print("Audio error: $e");
    }
  }

  /// Load an entire list of songs as the queue, starting playback at [startIndex].
  Future<void> setQueue(List<Song> songs, {int startIndex = 0}) async {
    if (songs.isEmpty) return;

    final sources = songs
        .where((s) => s.audioUrl != null && s.audioUrl!.isNotEmpty)
        .map((s) => AudioSource.uri(Uri.parse(s.audioUrl!), tag: s))
        .toList();

    if (sources.isEmpty) return;

    final clampedIndex = startIndex.clamp(0, sources.length - 1);
    _playlist = ConcatenatingAudioSource(children: sources);
    _originalOrder = List.from(songs);

    try {
      await _player.setShuffleModeEnabled(false);
      await _player.setAudioSource(_playlist!,
          initialIndex: clampedIndex, preload: true);
      _currentPlayingId = songs[clampedIndex].id;
      await _player.play();
      _updateQueueFromPlayer();
    } on PlayerInterruptedException catch (e) {
      print("Interrupted setQueue: $e");
    } catch (e) {
      print("Audio error in setQueue: $e");
    }
  }

  Future<void> addToQueue(Song song) async {
    final url = song.audioUrl;
    if (url == null || url.isEmpty) return;

    final source = AudioSource.uri(Uri.parse(url), tag: song);

    if (_playlist == null) {
      _playlist = ConcatenatingAudioSource(children: [source]);
      _originalOrder = [song];
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
      _originalOrder.add(song);
      if (!_player.playing &&
          _player.processingState == ProcessingState.completed) {
        await _player.seekToNext();
        await _player.play();
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
    if (_playlist == null ||
        index < 0 ||
        index >= _playlist!.length) return;

    final isCurrent = index == _player.currentIndex;
    await _playlist!.removeAt(index);
    if (index < _originalOrder.length) {
      _originalOrder.removeAt(index);
    }

    if (isCurrent) {
      _currentPlayingId = -1;
    }

    _updateQueueFromPlayer();
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (_playlist == null) return;
    if (oldIndex < 0 || oldIndex >= _playlist!.length) return;
    if (newIndex < 0 || newIndex > _playlist!.length) return;
    if (oldIndex == newIndex) return;
    if (oldIndex < newIndex) newIndex -= 1;

    final source = _playlist!.sequence[oldIndex];
    await _playlist!.removeAt(oldIndex);
    await _playlist!.insert(newIndex, source);

    // Keep original order in sync
    if (oldIndex < _originalOrder.length && newIndex <= _originalOrder.length) {
      final song = _originalOrder.removeAt(oldIndex);
      _originalOrder.insert(newIndex, song);
    }

    _updateQueueFromPlayer();
  }

  Future<void> clearQueue() async {
    if (_playlist != null) {
      await _playlist!.clear();
      _currentQueue.clear();
      _originalOrder.clear();
      _queueStreamController.add(List.unmodifiable(_currentQueue));
    }
  }

  /// Toggle shuffle on/off. When enabled, shuffles the queue while keeping
  /// the current song in place. When disabled, restores original order.
  Future<void> toggleShuffle(bool enable) async {
    if (_playlist == null || _currentQueue.length <= 1) return;

    final currentIdx = _player.currentIndex ?? 0;
    final currentSong = _currentQueue[currentIdx.clamp(0, _currentQueue.length - 1)];

    if (enable) {
      // Save original order if not already saved
      if (_originalOrder.isEmpty) {
        _originalOrder = List.from(_currentQueue);
      }

      // Shuffle everything except the current song
      final others = _currentQueue
          .asMap()
          .entries
          .where((e) => e.key != currentIdx)
          .map((e) => e.value)
          .toList();
      others.shuffle(Random());

      // Build new order: current song first, then shuffled rest
      final newOrder = [currentSong, ...others];

      final sources = newOrder
          .where((s) => s.audioUrl != null && s.audioUrl!.isNotEmpty)
          .map((s) => AudioSource.uri(Uri.parse(s.audioUrl!), tag: s))
          .toList();

      final wasPlaying = _player.playing;
      await _player.stop();

      _playlist = ConcatenatingAudioSource(children: sources);
      await _player.setAudioSource(_playlist!, initialIndex: 0, preload: true);

      if (wasPlaying) await _player.play();
    } else {
      // Restore original order
      if (_originalOrder.isEmpty) return;

      final startIndex = _originalOrder.indexWhere((s) => s.id == currentSong.id);
      final clampedStart = startIndex >= 0 ? startIndex : 0;

      final sources = _originalOrder
          .where((s) => s.audioUrl != null && s.audioUrl!.isNotEmpty)
          .map((s) => AudioSource.uri(Uri.parse(s.audioUrl!), tag: s))
          .toList();

      final wasPlaying = _player.playing;
      await _player.stop();

      _playlist = ConcatenatingAudioSource(children: sources);
      await _player.setAudioSource(_playlist!,
          initialIndex: clampedStart, preload: true);

      if (wasPlaying) await _player.play();
    }

    _updateQueueFromPlayer();
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

  Stream<bool> get playingStream =>
      _player.playerStateStream.map((s) => s.playing);

  Duration? get duration => _player.duration;

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();

  Future<void> stop() async {
    await _player.stop();
    if (_playlist != null) await _playlist!.clear();
    _currentPlayingId = -1;
    _currentQueue.clear();
    _originalOrder.clear();
    _queueStreamController.add(List.unmodifiable(_currentQueue));
  }

  Future<void> seekFraction(double fraction) async {
    final dur = _player.duration;
    if (dur != null) {
      final target =
          Duration(milliseconds: (fraction * dur.inMilliseconds).round());
      await _player.seek(target);
    }
  }

  Future<void> dispose() async {
    await _queueStreamController.close();
    await _player.dispose();
  }
}
