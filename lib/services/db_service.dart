import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';

class DBService {
  static const String baseUrl = "https://disco.dcism.org/api/"; 

  static Future<Map<String, dynamic>> authenticate(String user, String pass, {String? email}) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth.php"),
      body: {
        "username": user,
        "password": pass,
        if (email != null) "email": email,
      },
    );
    return jsonDecode(response.body);
  }

  static Future<List<Song>> fetchAllSongs() async {
    final response = await http.get(Uri.parse("$baseUrl/data.php?type=songs"));
    
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((s) => Song(
        id: int.parse(s['song_id'].toString()),
        title: s['title'],
        artist: s['artist_name'] ?? 'Unknown Artist',
        audioUrl: s['audio_url'],
        imageUrl: s['cover_image'],
      )).toList();
    }
    return [];
  }

  static Future<List<dynamic>> getPlaylists(int userId) async {
    final res = await http.get(Uri.parse("$baseUrl/data.php?type=playlists&user_id=$userId"));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }
}