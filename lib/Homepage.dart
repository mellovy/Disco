import 'package:flutter/material.dart';
import 'models/song.dart';
import 'services/db_service.dart';
import 'services/audio_manager.dart'; 

class HomePage extends StatefulWidget {
  final String username;
  final int userId;
  final Function(Song) onOpenPlayer;
  const HomePage(
      {super.key,
      required this.username,
      required this.userId,
      required this.onOpenPlayer});

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
      if (mounted) setState(() {
        _allSongs = songs;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _songImage(String? url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (url == null) {
      return Container(
        width: width, height: height,
        color: Colors.purple.withOpacity(0.1),
        child: const Icon(Icons.music_note, color: Colors.purple),
      );
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (c, e, s) => Container(
        width: width, height: height,
        color: Colors.purple.withOpacity(0.1),
        child: const Icon(Icons.music_note, color: Colors.purple),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = isDark ? const Color(0xFF2A2A3E) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final gridSongs = _allSongs.take(4).toList();

    return Scaffold(
      backgroundColor: bgColor,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          // Listen to the audio manager stream to see if a queue exists dynamically
          : StreamBuilder<Song?>(
              stream: AudioManager.instance.currentSongStream,
              builder: (context, snapshot) {
                final bool hasOngoingQueue = snapshot.hasData && snapshot.data != null;

                return RefreshIndicator(
                  onRefresh: _loadData,
                  color: Colors.purple,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        'Welcome, ${widget.username}!',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: textPrimary),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'Top Tracks',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary),
                      ),
                      const SizedBox(height: 15),

                      if (_allSongs.isEmpty)
                        Column(
                          children: [
                            const SizedBox(height: 50),
                            Icon(Icons.music_off,
                                size: 70, color: Colors.purple.withOpacity(0.2)),
                            Text("Your library is empty.",
                                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey)),
                          ],
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: gridSongs.length,
                          itemBuilder: (context, index) {
                            final song = gridSongs[index];
                            return GestureDetector(
                              onTap: () {
                                // No more loading the entire list. Just tell the player to open this one.
                                widget.onOpenPlayer(song);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(12)),
                                        child: _songImage(song.imageUrl,
                                            width: double.infinity),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(song.title,
                                                    style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: textPrimary),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis),
                                                Text(song.artist ?? '',
                                                    style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 11),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis),
                                              ],
                                            ),
                                          ),
                                          // Add to Queue Icon (Visible only if a song is currently playing)
                                          if (hasOngoingQueue)
                                            GestureDetector(
                                              onTap: () {
                                                AudioManager.instance.addToQueue(song);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text("${song.title} added to queue"),
                                                    duration: const Duration(seconds: 1),
                                                    behavior: SnackBarBehavior.floating,
                                                  ),
                                                );
                                              },
                                              child: const Icon(Icons.playlist_add, color: Colors.purple, size: 22),
                                            ),
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
                        Text('More for You',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textPrimary)),
                        ..._allSongs.skip(4).map((song) => ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: _songImage(song.imageUrl,
                                    width: 45, height: 45),
                              ),
                              title: Text(song.title,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary)),
                              subtitle: Text(song.artist ?? '',
                                  style: const TextStyle(color: Colors.grey)),
                              // Add to Queue Icon (Visible only if a song is currently playing)
                              trailing: hasOngoingQueue
                                  ? IconButton(
                                      icon: const Icon(Icons.playlist_add, color: Colors.purple),
                                      onPressed: () {
                                        AudioManager.instance.addToQueue(song);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("${song.title} added to queue"),
                                            duration: const Duration(seconds: 1),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                    )
                                  : null,
                              onTap: () {
                                widget.onOpenPlayer(song);
                              },
                            )),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              }
            ),
    );
  }
}