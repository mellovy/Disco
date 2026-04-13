import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'models/song.dart';
import 'services/db_service.dart';

class SearchPage extends StatefulWidget {
  final Function(Song) onOpenPlayer;
  final VoidCallback onProfileTap;
  final String username;
  final Color avatarColor;
  final Uint8List? avatarImageBytes;

  const SearchPage({
    super.key,
    required this.onOpenPlayer,
    required this.onProfileTap,
    required this.username,
    required this.avatarColor,
    this.avatarImageBytes,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Song> _allSongs = [];
  List<Song> _filteredSongs = [];
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final songs = await DBService.fetchAllSongs(0);
    if (mounted) setState(() => _allSongs = songs);
  }

  void _filter(String val) {
    setState(() {
      _hasSearched = val.isNotEmpty;
      _filteredSongs = _allSongs
          .where((s) =>
              s.title.toLowerCase().contains(val.toLowerCase()) ||
              (s.artist?.toLowerCase().contains(val.toLowerCase()) ?? false))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final searchFill = isDark ? const Color(0xFF2A2A3E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: _filter,
                      style: TextStyle(color: textPrimary),
                      decoration: InputDecoration(
                        hintText: "What do you want to listen to?",
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: searchFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: widget.onProfileTap,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: widget.avatarColor,
                      backgroundImage: widget.avatarImageBytes != null
                          ? MemoryImage(widget.avatarImageBytes!)
                          : null,
                      child: widget.avatarImageBytes == null
                          ? Text(
                              widget.username.isNotEmpty
                                  ? widget.username[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: !_hasSearched
                  ? Center(
                      child: Text("Search for your favorite songs",
                          style: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey)))
                  : _filteredSongs.isEmpty
                      ? Center(
                          child: Text("No songs found",
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey)))
                      : ListView.builder(
                          itemCount: _filteredSongs.length,
                          itemBuilder: (context, i) {
                            final song = _filteredSongs[i];
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: song.imageUrl != null
                                    ? Image.network(
                                        song.imageUrl!,
                                        width: 45,
                                        height: 45,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Container(
                                          width: 45, height: 45,
                                          color: Colors.purple.withOpacity(0.1),
                                          child: const Icon(Icons.music_note,
                                              color: Colors.purple, size: 20),
                                        ),
                                      )
                                    : Container(
                                        width: 45, height: 45,
                                        color: Colors.purple.withOpacity(0.1),
                                        child: const Icon(Icons.music_note,
                                            color: Colors.purple, size: 20),
                                      ),
                              ),
                              title: Text(song.title,
                                  style: TextStyle(color: textPrimary)),
                              subtitle: Text(song.artist ?? '',
                                  style: const TextStyle(color: Colors.grey)),
                              onTap: () => widget.onOpenPlayer(song),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}