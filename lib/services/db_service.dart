import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/song.dart';

class DBService {
  static const String baseUrl = "https://disco.dcism.org/api"; 

  static Future<Map<String, dynamic>> authenticate(String user, String pass, {String? email}) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth.php"),
      body: {"username": user, "password": pass, if (email != null) "email": email},
    );
    return jsonDecode(response.body);
  }

  static Future<List<Song>> fetchAllSongs() async {
    try {
      // FIX: Added 't' parameter with current time to prevent browser caching
      final response = await http.get(
        Uri.parse("$baseUrl/data.php?type=songs&t=${DateTime.now().millisecondsSinceEpoch}")
      );
      
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((s) => Song(
          id: int.parse(s['song_id'].toString()),
          title: s['title'] ?? 'Untitled',
          artist: s['artist_name'] ?? 'Unknown Artist',
          audioUrl: s['audio_url'], 
          imageUrl: s['cover_image'],
        )).toList();
      }
    } catch (e) {
      print("Fetch Error: $e");
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

  static Future<bool> uploadSong({
    required String title,
    required String artistId,
    required Uint8List audioBytes,
    required String audioName,
    required Uint8List imageBytes,
    required String imageName,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse("$baseUrl/upload_song.php"));
      
      request.fields['title'] = title;
      request.fields['artist_id'] = artistId;

      request.files.add(http.MultipartFile.fromBytes('audio', audioBytes, filename: audioName));
      request.files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: imageName));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      final res = jsonDecode(response.body);
      return res['success'] == true;
    } catch (e) {
      print("Upload error: $e");
      return false;
    }
  }
}