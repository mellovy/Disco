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
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  _fetch() async {
    final songs = await DBService.fetchAllSongs(0); // Fetch all
    setState(() => _allSongs = songs);
  }

  void _filter(String val) {
    setState(() {
      _hasSearched = val.isNotEmpty;
      _filteredSongs = _allSongs.where((s) => 
        s.title.toLowerCase().contains(val.toLowerCase()) || 
        (s.artist?.toLowerCase().contains(val.toLowerCase()) ?? false)
      ).toList();
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
                onChanged: _filter,
                decoration: InputDecoration(
                  hintText: "What do you want to listen to?",
                  prefixIcon: const Icon(Icons.search),
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: !_hasSearched 
                ? const Center(child: Text("Search for your favorite songs"))
                : _filteredSongs.isEmpty 
                  ? const Center(child: Text("No songs found"))
                  : ListView.builder(
                      itemCount: _filteredSongs.length,
                      itemBuilder: (context, i) => ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(_filteredSongs[i].imageUrl!, width: 45, height: 45, fit: BoxFit.cover),
                        ),
                        title: Text(_filteredSongs[i].title),
                        subtitle: Text(_filteredSongs[i].artist ?? ''),
                        onTap: () => widget.onOpenPlayer(_filteredSongs[i]),
                      ),
                    ),
            )
          ],
        ),
      ),
    );
  }
}