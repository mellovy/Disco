import 'package:flutter/material.dart';
import 'models/song.dart';
import 'services/db_service.dart';

class HomePage extends StatefulWidget {
  final String username;
  final int userId;
  final Function(Song) onOpenPlayer;
  const HomePage({super.key, required this.username, required this.userId, required this.onOpenPlayer});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Song> _allSongs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final songs = await DBService.fetchAllSongs();
      setState(() { _allSongs = songs; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1E6FF),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 40),
              Text('Hi, ${widget.username}!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              if (_allSongs.isEmpty) 
                Column(
                  children: [
                    const SizedBox(height: 50),
                    Icon(Icons.music_off, size: 100, color: Colors.purple.withOpacity(0.2)),
                    const Text("No songs available in the database.", style: TextStyle(color: Colors.grey)),
                  ],
                )
              else
                ..._allSongs.map((song) => ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text(song.title),
                  subtitle: Text(song.artist ?? ''),
                  onTap: () => widget.onOpenPlayer(song),
                )),
            ],
          ),
    );
  }
}