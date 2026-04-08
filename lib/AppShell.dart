import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'Homepage.dart';
import 'Search.dart';
import 'Library.dart';
import 'UploadSong.dart';
import 'models/song.dart';
import 'MusicPlayer.dart';

class AppShell extends StatefulWidget {
  final String username;
  final int userId;
  const AppShell({super.key, required this.username, required this.userId});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  Song? _currentSong;
  bool _playerMaximized = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Centralized player logic: only reloads if a NEW song is selected
  void _openPlayer(Song song) async {
    if (_currentSong?.id != song.id) {
      setState(() {
        _currentSong = song;
      });
      try {
        await _audioPlayer.setUrl(song.audioUrl!);
        _audioPlayer.play();
      } catch (e) {
        debugPrint("Error loading audio: $e");
      }
    }
    setState(() {
      _playerMaximized = true;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(username: widget.username, userId: widget.userId, onOpenPlayer: _openPlayer),
      SearchPage(onOpenPlayer: _openPlayer),
      LibraryPage(userId: widget.userId),
      const UploadSongPage(),
    ];

    return Scaffold(
      // Using Stack to place the Mini Player on top of the content
      body: Stack(
        children: [
          // Main App Content
          IndexedStack(index: _selectedIndex, children: pages),
          
          // Player Overlay
          if (_currentSong != null) ...[
            if (_playerMaximized)
              // Full Screen Player
              MusicPlayerPage(
                song: _currentSong!, 
                userId: widget.userId,
                player: _audioPlayer,
                onClose: () => setState(() => _playerMaximized = false)
              )
            else
              // Floating Mini Player (positioned above BottomNav)
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: _buildMiniPlayer(),
              ),
          ],
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFFF1E6FF),
        onTap: (i) {
          setState(() {
            _selectedIndex = i;
            _playerMaximized = false;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.upload), label: 'Upload'),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return GestureDetector(
      onTap: () => setState(() => _playerMaximized = true),
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
        child: Container(
          height: 75,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              // Album Art
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  _currentSong!.imageUrl!, 
                  width: 50, 
                  height: 50, 
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    color: Colors.purple[50],
                    child: const Icon(Icons.music_note, color: Colors.purple),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Song Info
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentSong!.title, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis
                    ),
                    Text(
                      _currentSong!.artist ?? '', 
                      style: const TextStyle(fontSize: 12, color: Colors.grey), 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis
                    ),
                  ],
                ),
              ),
              // Controls
              IconButton(
                icon: const Icon(Icons.skip_previous), 
                onPressed: () { /* Logic for previous */ }
              ),
              StreamBuilder<PlayerState>(
                stream: _audioPlayer.playerStateStream,
                builder: (context, snapshot) {
                  final playing = snapshot.data?.playing ?? false;
                  return IconButton(
                    icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 35),
                    color: Colors.purple,
                    onPressed: () => playing ? _audioPlayer.pause() : _audioPlayer.play(),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_next), 
                onPressed: () { /* Logic for next */ }
              ),
              // Close Player
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  _audioPlayer.stop();
                  setState(() => _currentSong = null);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}