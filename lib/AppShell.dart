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

  void _openPlayer(Song song) async {
    if (_currentSong?.id != song.id) {
      setState(() {
        _currentSong = song;
      });
      await _audioPlayer.setUrl(song.audioUrl!);
      _audioPlayer.play();
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
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: pages),
          
          if (_currentSong != null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              // Position it at the bottom if minimized, or full screen if maximized
              top: _playerMaximized ? 0 : MediaQuery.of(context).size.height - (kBottomNavigationBarHeight + 85),
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height,
              child: _playerMaximized 
                ? MusicPlayerPage(
                    song: _currentSong!, 
                    userId: widget.userId,
                    player: _audioPlayer,
                    onClose: () => setState(() => _playerMaximized = false)
                  )
                : _buildMiniPlayer(),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.purple,
        backgroundColor: const Color(0xFFF1E6FF),
        onTap: (i) {
          setState(() {
            _selectedIndex = i;
            _playerMaximized = false;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music_outlined), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.cloud_upload_outlined), label: 'Upload'),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return GestureDetector(
      onTap: () => setState(() => _playerMaximized = true),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.purple[100], // Match app theme
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        height: 75,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                _currentSong!.imageUrl!, 
                width: 50, 
                height: 50, 
                fit: BoxFit.cover,
                errorBuilder: (c,e,s) => const Icon(Icons.music_note),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentSong!.title, 
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                  ),
                  Text(
                    _currentSong!.artist ?? '', 
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.purple[700], fontSize: 13)
                  ),
                ],
              ),
            ),
            StreamBuilder<PlayerState>(
              stream: _audioPlayer.playerStateStream,
              builder: (context, snapshot) {
                final playing = snapshot.data?.playing ?? false;
                return IconButton(
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow, color: Colors.purple[900]),
                  onPressed: () => playing ? _audioPlayer.pause() : _audioPlayer.play(),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _audioPlayer.stop();
                setState(() => _currentSong = null);
              },
            ),
          ],
        ),
      ),
    );
  }
}