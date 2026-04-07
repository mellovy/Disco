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
      final songs = await DBService.fetchAllSongs(widget.userId);
      if (mounted) setState(() { _allSongs = songs; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gridSongs = _allSongs.take(4).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1E6FF),
      body: _loading 
        ? const Center(child: CircularProgressIndicator()) 
        : RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 40),
                Text('Welcome, ${widget.username}!', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                const Text('Top Tracks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),

                if (_allSongs.isEmpty)
                  Column(
                    children: [
                      const SizedBox(height: 50),
                      Icon(Icons.music_off, size: 70, color: Colors.purple.withOpacity(0.2)),
                      const Text("Your database is empty.", style: TextStyle(color: Colors.grey)),
                    ],
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85,
                    ),
                    itemCount: gridSongs.length,
                    itemBuilder: (context, index) {
                      final song = gridSongs[index];
                      return GestureDetector(
                        onTap: () => widget.onOpenPlayer(song),
                        child: Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: Image.network(song.imageUrl!, width: double.infinity, fit: BoxFit.cover),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                                    Text(song.artist ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 1),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                
                const SizedBox(height: 30),
                if (_allSongs.length > 4) ...[
                  const Text('More for You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ..._allSongs.skip(4).map((song) => ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(song.imageUrl!, width: 45, height: 45, fit: BoxFit.cover),
                    ),
                    title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(song.artist ?? ''),
                    onTap: () => widget.onOpenPlayer(song),
                  )),
                ],
                const SizedBox(height: 100), // Buffer for miniplayer
              ],
            ),
          ),
    );
  }
}