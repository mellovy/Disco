import 'package:flutter/material.dart';
import 'models/song.dart';
import 'services/db_service.dart';

class HomePage extends StatefulWidget {
  final String username;
  final int userId;
  final Function(Song) onOpenPlayer;

  const HomePage({
    super.key, 
    required this.username, 
    required this.userId, 
    required this.onOpenPlayer
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Song> _allSongs = [];
  List<dynamic> _playlists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final songs = await DBService.fetchAllSongs();
      final playlists = await DBService.getPlaylists(widget.userId);

      if (mounted) {
        setState(() {
          _allSongs = songs;
          _playlists = playlists;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF1E6FF),
      body: _loading 
          ? const Center(child: CircularProgressIndicator()) 
          : RefreshIndicator(
              onRefresh: _loadData,
              color: Colors.purple,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(), // Essential for RefreshIndicator
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hi, ${widget.username}!', 
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                      ),
                      IconButton(
                        onPressed: _shufflePlay, 
                        icon: const Icon(Icons.shuffle, color: Colors.purple)
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  if (_allSongs.isEmpty) 
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 80),
                          Icon(Icons.music_off, size: 100, color: Colors.purple.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          const Text(
                            "No songs found in the database.", 
                            style: TextStyle(color: Colors.grey, fontSize: 16)
                          ),
                          const Text(
                            "Swipe down to refresh", 
                            style: TextStyle(color: Colors.grey, fontSize: 12)
                          ),
                        ],
                      ),
                    )
                  else ...[
                    const Text('Your Playlists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    GridView.count(
                      shrinkWrap: true, 
                      crossAxisCount: 2, 
                      mainAxisSpacing: 10, 
                      crossAxisSpacing: 10, 
                      childAspectRatio: 3,
                      physics: const NeverScrollableScrollPhysics(),
                      children: _playlists.map((p) => Card(
                        child: Center(child: Text(p['name'] ?? 'Playlist'))
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text('Top Tracks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ..._allSongs.map((song) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.music_note, color: Colors.purple),
                      ),
                      title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(song.artist ?? 'Unknown Artist'),
                      onTap: () => widget.onOpenPlayer(song),
                    )),
                  ]
                ],
              ),
            ),
    );
  }
}