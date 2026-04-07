import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/song.dart';

class DBService {
  static const String baseUrl = "https://disco.dcism.org/api"; 

  // Combined Login and Registration
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

  // Consistent naming: fetchAllSongs
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

  // Consistent naming: getPlaylists
  static Future<List<dynamic>> getPlaylists(int userId) async {
    final res = await http.get(Uri.parse("$baseUrl/data.php?type=playlists&user_id=$userId"));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }

  // Upload method using bytes for Web/Emulator compatibility
  static Future<void> uploadSong({
    required String title,
    required String artistId,
    required Uint8List audioBytes,
    required String audioName,
    required Uint8List imageBytes,
    required String imageName,
    required Function(double) onProgress,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse("$baseUrl/upload_song.php"));
    
    request.fields['title'] = title;
    request.fields['artist_id'] = artistId;

    request.files.add(http.MultipartFile.fromBytes('audio', audioBytes, filename: audioName));
    request.files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: imageName));

    final streamedResponse = await request.send();
    onProgress(0.5); // Signal start

    final response = await http.Response.fromStream(streamedResponse);
    final res = jsonDecode(response.body);

    if (res['success'] != true) {
      throw res['message'] ?? "Upload failed";
    }
  }
}