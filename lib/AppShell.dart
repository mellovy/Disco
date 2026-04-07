import 'package:flutter/material.dart';
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
  bool _maximized = false;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(username: widget.username, userId: widget.userId, onOpenPlayer: (s) => setState(() { _currentSong = s; _maximized = true; })),
      SearchPage(onOpenPlayer: (s) => setState(() { _currentSong = s; _maximized = true; })),
      LibraryPage(userId: widget.userId),
      UploadSongPage(), // New Tab
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: pages),
          if (_currentSong != null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              top: _maximized ? 0 : MediaQuery.of(context).size.height - 130,
              left: 0, right: 0, height: MediaQuery.of(context).size.height,
              child: MusicPlayerPage(
                song: _currentSong!, 
                onClose: () => setState(() => _maximized = false)
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() { _selectedIndex = i; _maximized = false; }),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Upload'),
        ],
      ),
    );
  }
}