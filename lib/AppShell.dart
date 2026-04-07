import 'package:flutter/material.dart';
import 'Homepage.dart';
import 'Search.dart';
import 'models/song.dart';
import 'MusicPlayer.dart';

class AppShell extends StatefulWidget {
  final String username;
  const AppShell({Key? key, required this.username}) : super(key: key);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  Song? _currentSong;
  bool _playerMaximized = false;
  static const Duration _playerAnimDuration = Duration(milliseconds: 320);

  void _onItemTapped(int index) {
    setState(() {
      // Close any maximized player first so navigation is visible
      _playerMaximized = false;
      _currentSong = null;
      _selectedIndex = index;
    });
  }

  void _openPlayer(Song song, {bool maximize = true}) {
    setState(() {
      _currentSong = song;
      _playerMaximized = maximize;
    });
  }

  void _closePlayer() {
    // Animate closing: first collapse, then remove song after animation completes
    setState(() {
      _playerMaximized = false;
    });
    Future.delayed(_playerAnimDuration, () {
      if (mounted) setState(() => _currentSong = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(username: widget.username, onSearch: () => _onItemTapped(1), onOpenPlayer: (s) => _openPlayer(s, maximize: true)),
      SearchPage(onOpenPlayer: (s) => _openPlayer(s, maximize: true)),
      Center(child: Text('Library - coming soon', style: TextStyle(fontSize: 18, color: Colors.black54))),
    ];

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final height = constraints.maxHeight;
          final miniTop = height - 120.0; // position for mini-player (above nav)
          final fullTop = 0.0;
          return Stack(
            children: [
              IndexedStack(index: _selectedIndex, children: pages),
              if (_currentSong != null)
                // Animated overlay: slide between mini and full positions
                AnimatedPositioned(
                  duration: _playerAnimDuration,
                  curve: Curves.easeInOut,
                  top: _playerMaximized ? fullTop : miniTop,
                  left: 0,
                  right: 0,
                  height: height,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _playerMaximized ? 1.0 : 0.98,
                    // Use the full MusicPlayerPage so audio playback is wired
                    child: MusicPlayerPage(song: _currentSong!),
                  ),
                ),
            ],
          );
        }),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Library'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFAE65EC),
        unselectedItemColor: Colors.black54,
        onTap: (index) {
          // Close player with animation first, then switch page
          if (_currentSong != null) {
            _closePlayer();
            Future.delayed(_playerAnimDuration, () => _onItemTapped(index));
          } else {
            _onItemTapped(index);
          }
        },
      ),
    );
  }
}
