import 'package:flutter/material.dart';
import 'services/db_service.dart';

class LibraryPage extends StatelessWidget {
  final int userId;
  const LibraryPage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1E6FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your Library', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: DBService.getPlaylists(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("No playlists found."));
                    }
                    final playlists = snapshot.data!;
                    return ListView.builder(
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const Icon(Icons.playlist_play, size: 40),
                            title: Text(playlists[index]['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text("Playlist"),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}