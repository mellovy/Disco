import 'package:flutter/material.dart';
import 'models/song.dart';
import 'services/db_service.dart';

class SearchPage extends StatefulWidget {
  final Function(Song) onOpenPlayer;
  const SearchPage({super.key, required this.onOpenPlayer});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Song> _allSongs = [];
  List<Song> _filteredSongs = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSongs();
  }

  _fetchSongs() async {
    final songs = await DBService.fetchAllSongs();
    setState(() { _allSongs = songs; _filteredSongs = songs; });
  }

  void _filterSongs(String query) {
    setState(() {
      _filteredSongs = _allSongs
          .where((s) => s.title.toLowerCase().contains(query.toLowerCase()) || 
                        (s.artist?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1E6FF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: _filterSongs,
                decoration: InputDecoration(
                  prefixIcon: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => _searchController.clear(), // Simplified back action
                  ),
                  hintText: "Search songs or artists...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredSongs.length,
                itemBuilder: (context, i) => ListTile(
                  title: Text(_filteredSongs[i].title),
                  subtitle: Text(_filteredSongs[i].artist ?? ''),
                  onTap: () => widget.onOpenPlayer(_filteredSongs[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}