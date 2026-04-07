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
    // Show only first 4 songs in grid
    final gridSongs = _allSongs.take(4).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1E6FF),
      body: _loading 
        ? const Center(child: CircularProgressIndicator()) 
        : RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                const SizedBox(height: 50),
                Text('Hello, ${widget.username}!', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const Text('Find your vibe today', style: TextStyle(color: Colors.grey)),
                
                const SizedBox(height: 30),
                const Text('Recommended for You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),

                if (_allSongs.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Icon(Icons.music_off, size: 70, color: Colors.purple.withOpacity(0.2)),
                        const Text("No songs available.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                else
                  // 2x2 Grid Layout
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: gridSongs.length,
                    itemBuilder: (context, index) {
                      final song = gridSongs[index];
                      return GestureDetector(
                        onTap: () => widget.onOpenPlayer(song),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                  child: Image.network(
                                    song.imageUrl!, 
                                    width: double.infinity, 
                                    fit: BoxFit.cover,
                                    errorBuilder: (c,e,s) => Container(color: Colors.purple[50], child: const Icon(Icons.music_note)),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(song.artist ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 15),
                if (_allSongs.length > 4) ...[
                  const Text('More Tracks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ..._allSongs.skip(4).map((song) => ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(song.imageUrl!, width: 50, height: 50, fit: BoxFit.cover),
                    ),
                    title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(song.artist ?? ''),
                    onTap: () => widget.onOpenPlayer(song),
                  )),
                ],
              ],
            ),
          ),
    );
  }
}