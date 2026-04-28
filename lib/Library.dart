import 'package:flutter/material.dart';
import 'pixel_colors.dart';
import 'services/db_service.dart';

class LibraryPage extends StatelessWidget {
  final int userId;
  const LibraryPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? PixelColors.darkCard : PixelColors.lightCard;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Library',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: textPrimary)),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: DBService.getPlaylists(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: Colors.purple));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                          child: Text("No playlists found.",
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey)));
                    }
                    final playlists = snapshot.data!;
                    return ListView.builder(
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        return Card(
                          color: cardColor,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: const RoundedRectangleBorder(),
                          child: ListTile(
                            leading: Icon(Icons.playlist_play,
                                size: 40, color: isDark ? PixelColors.neonCyan : PixelColors.accentMint),
                            title: Text(playlists[index]['name'],
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary)),
                            subtitle: Text("Playlist",
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey)),
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