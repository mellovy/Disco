import 'package:flutter/material.dart';
import 'Homepage.dart';
import 'Search.dart';
import 'models/song.dart';
import 'MusicPlayer.dart';

class AppShell extends StatefulWidget {
  final String username;
  final int userId;
  const AppShell({Key? key, required this.username, required this.userId}) : super(key: key);
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  Song? _currentSong;
  bool _playerMaximized = false;

  void _onItemTapped(int index) {
    setState(() {
      _playerMaximized = false;
      _selectedIndex = index;
    });
  }

  void _openPlayer(Song song) {
    setState(() {
      _currentSong = song;
      _playerMaximized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(username: widget.username, userId: widget.userId, onOpenPlayer: _openPlayer),
      SearchPage(onOpenPlayer: _openPlayer),
      const Center(child: Text('Library')),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: pages),
          if (_currentSong != null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 320),
              top: _playerMaximized ? 0 : MediaQuery.of(context).size.height - 130,
              left: 0, right: 0, height: MediaQuery.of(context).size.height,
              child: MusicPlayerPage(
                song: _currentSong!,
                onClose: () => setState(() => _playerMaximized = false),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFFAE65EC),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Library'),
        ],
      ),
    );
  }
}