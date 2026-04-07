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
  List<String> _playlists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final songs = await DBService.fetchAllSongs();
      final conn = await DBService.getConnection();
      var pResults = await conn.query('SELECT name FROM playlists WHERE user_id = ?', [widget.userId]);
      await conn.close();

      setState(() {
        _allSongs = songs;
        _playlists = pResults.map((r) => r['name'].toString()).toList();
        _loading = false;
      });
    } catch (e) {
      print(e);
    }
  }

  void _shufflePlay() {
    if (_allSongs.isNotEmpty) {
      final shuffled = List<Song>.from(_allSongs)..shuffle();
      widget.onOpenPlayer(shuffled.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading ? const Center(child: CircularProgressIndicator()) : Container(
      color: const Color(0xFFEAD7FF),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hi, ${widget.username}!', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              IconButton(onPressed: _shufflePlay, icon: const Icon(Icons.shuffle, color: Colors.purple)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Your Playlists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          GridView.count(
            shrinkWrap: true, crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 3,
            physics: const NeverScrollableScrollPhysics(),
            children: _playlists.map((name) => Card(child: Center(child: Text(name)))).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Recommended Songs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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