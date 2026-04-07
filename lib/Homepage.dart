import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/song.dart';

class HomePage extends StatefulWidget {
  final String username;
  final int userId;
  final Function(Song) onOpenPlayer;

  const HomePage({super.key, required this.username, required this.userId, required this.onOpenPlayer});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Song> _recentSongs = [];
  List<dynamic> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      // Replace with your API fetching logic for songs and user-specific playlists
      final songsResponse = await http.get(Uri.parse('https://your-api-domain.com/get_songs.php'));
      final playlistsResponse = await http.get(Uri.parse('https://your-api-domain.com/get_playlists.php?user_id=${widget.userId}'));

      if (songsResponse.statusCode == 200) {
        final List<dynamic> songData = json.decode(songsResponse.body);
        final List<dynamic> playlistData = json.decode(playlistsResponse.body);
        
        setState(() {
          _recentSongs = songData.map((s) => Song.fromJson(s)).toList();
          _playlists = playlistData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading home data: $e');
    }
  }

  void _shufflePlay() {
    if (_recentSongs.isNotEmpty) {
      final shuffled = List<Song>.from(_recentSongs)..shuffle();
      widget.onOpenPlayer(shuffled.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0E6FF),
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Hi, ${widget.username}!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: _shufflePlay,
                    icon: const Icon(Icons.shuffle),
                    label: const Text('Shuffle'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[100]),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Your Playlists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 3),
                itemCount: _playlists.length,
                itemBuilder: (ctx, i) => Card(child: Center(child: Text(_playlists[i]['name']))),
              ),
              const SizedBox(height: 20),
              const Text('Recently Played', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ..._recentSongs.map((song) => ListTile(
                leading: const Icon(Icons.music_note),
                title: Text(song.title),
                subtitle: Text(song.artist ?? 'Unknown Artist'),
                onTap: () => widget.onOpenPlayer(song),
              )),
            ],
          ),
    );
  }
}