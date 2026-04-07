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
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSongs();
  }

  Future<void> _fetchSongs() async {
    final songs = await DBService.fetchAllSongs();
    if (mounted) {
      setState(() {
        _allSongs = songs;
        _filteredSongs = songs;
        _isLoading = false;
      });
    }
  }

  void _runFilter(String enteredKeyword) {
    List<Song> results = [];
    if (enteredKeyword.isEmpty) {
      results = _allSongs;
    } else {
      results = _allSongs
          .where((song) =>
              song.title.toLowerCase().contains(enteredKeyword.toLowerCase()) ||
              (song.artist?.toLowerCase().contains(enteredKeyword.toLowerCase()) ?? false))
          .toList();
    }

    setState(() {
      _filteredSongs = results;
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
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => _runFilter(value),
                      decoration: InputDecoration(
                        hintText: "Search artist, songs...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredSongs.isEmpty
                      ? const Center(child: Text("No songs match your search."))
                      : ListView.builder(
                          itemCount: _filteredSongs.length,
                          itemBuilder: (context, index) => ListTile(
                            leading: const Icon(Icons.music_note),
                            title: Text(_filteredSongs[index].title),
                            subtitle: Text(_filteredSongs[index].artist ?? ''),
                            onTap: () => widget.onOpenPlayer(_filteredSongs[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}