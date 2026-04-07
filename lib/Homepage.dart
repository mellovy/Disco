import 'package:flutter/material.dart';
import 'Search.dart';
import 'models/song.dart';
import 'MusicPlayer.dart';

class HomePage extends StatelessWidget {
  final String username;
  final VoidCallback? onSearch;
  final ValueChanged<Song>? onOpenPlayer;
  const HomePage({super.key, required this.username, this.onSearch, this.onOpenPlayer});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEAD7FF),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: greeting and icons
              Row(
                children: [
                  Expanded(child: Text('Good Morning!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87))),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.person_outline, color: Colors.black87)),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined, color: Colors.black87)),
                ],
              ),
              const SizedBox(height: 12),

              // Search pill (tappable) — matches SearchPage style
              GestureDetector(
                onTap: () {
                  if (onSearch != null) {
                    onSearch!.call();
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage()));
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6D9FF),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: const [
                      Padding(
                        padding: EdgeInsets.only(left: 6.0, right: 8.0),
                        child: Icon(Icons.search, color: Colors.black54),
                      ),
                      Expanded(
                        child: Text('Search', style: TextStyle(color: Colors.black54, fontSize: 16)),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 6.0),
                        child: Icon(Icons.mic, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Playlists grid (2x2)
              SizedBox(
                height: 220,
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(4, (index) {
                    return _PlaylistCard(title: 'Playlist #${index + 1}');
                  }),
                ),
              ),
              const SizedBox(height: 12),

              // Recently Played header
              const Text('Recently Played...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),

              // Recently played horizontal list (tappable to open player)
              SizedBox(
                height: 120,
                child: Builder(builder: (context) {
                  final recentSongs = [
                    Song(title: 'Love Story', artist: 'Taylor Swift', audioUrl: 'assets/audio/love_story.mp3'),
                    ...List.generate(2, (i) => Song(title: 'Song Name ${i + 2}', artist: 'Artist ${i + 2}')),
                  ];
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: recentSongs.length,
                    itemBuilder: (context, index) {
                      final song = recentSongs[index];
                      return InkWell(
                        onTap: () {
                          if (onOpenPlayer != null) {
                            onOpenPlayer!.call(song);
                          } else {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => MusicPlayerPage(song: song)));
                          }
                        },
                        child: Container(
                          width: 320,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)],
                          ),
                          child: Row(
                            children: [
                              Container(width: 80, height: 80, color: Colors.grey[200], child: const Icon(Icons.image, size: 40, color: Colors.grey)),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(song.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(song.artist ?? '', style: const TextStyle(color: Colors.black54))])),
                              const SizedBox(width: 8),
                              IconButton(onPressed: () {}, icon: const Icon(Icons.skip_previous)),
                              IconButton(onPressed: () {}, icon: const Icon(Icons.play_arrow)),
                              IconButton(onPressed: () {}, icon: const Icon(Icons.skip_next)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
      // Note: bottom navigation is provided by AppShell when HomePage is embedded there.
    );
  }
}

// (Removed unused helper widgets to avoid analyzer warnings)

// Playlist card used in grid
class _PlaylistCard extends StatelessWidget {
  final String title;
  const _PlaylistCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.image, color: Colors.grey)),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
