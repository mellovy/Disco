
import 'package:flutter/material.dart';
import 'models/song.dart';
import 'MusicPlayer.dart';

class SearchPage extends StatefulWidget {
  final ValueChanged<Song>? onOpenPlayer;
  const SearchPage({Key? key, this.onOpenPlayer}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Example: first song includes a sample audio URL (placeholder). Replace with your own file or URL.
  final List<Song> songs = [
    Song(
      title: 'Love Story',
      artist: 'Taylor Swift',
      audioUrl: 'assets/audio/love_story.mp3',
    ),
    ...List.generate(11, (i) => Song(title: 'Song Name ${i + 2}', artist: 'Artist ${i + 2}')),
  ];

  final ScrollController _scrollController = ScrollController();
  String query = '';

  List<Song> get filteredSongs {
    if (query.isEmpty) return songs;
    return songs
        .where((s) => s.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0E6FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 18.0),
          child: Column(
            children: [
              // Top row: back button + search pill (so user can return like Spotify)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6D9FF),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 6.0, right: 8.0),
                            child: Icon(Icons.search, color: Colors.black54),
                          ),
                          Expanded(
                            child: TextField(
                              onChanged: (v) => setState(() => query = v),
                              decoration: const InputDecoration(
                                hintText: 'Search',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            child: IconButton(
                              icon: const Icon(Icons.mic, color: Colors.black54),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // List with scrollbar
              Expanded(
                child: RawScrollbar(
                  controller: _scrollController,
                  thumbColor: Colors.grey.shade400,
                  radius: const Radius.circular(8),
                  thickness: 6,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: filteredSongs.length,
                    itemBuilder: (context, index) {
                      final s = filteredSongs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            if (widget.onOpenPlayer != null) {
                              widget.onOpenPlayer!.call(s);
                            } else {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => MusicPlayerPage(song: s)));
                            }
                          },
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 62,
                                    height: 62,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: const Icon(Icons.image, size: 36, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.title,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(s.artist ?? '', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
