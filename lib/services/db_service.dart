import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/song.dart';

class DBService {
  static const String baseUrl = "https://disco.dcism.org/api";

  static Future<Map<String, dynamic>> authenticate(
    String user,
    String pass, {
    String? email,
  }) async {
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
      return data
          .map(
            (s) => Song(
              id: int.parse(s['song_id'].toString()),
              title: s['title'],
              artist: s['artist_name'] ?? 'Unknown Artist',
              audioUrl: s['audio_url'],
              imageUrl: s['cover_image'],
            ),
          )
          .toList();
    }
    return [];
  }

  static Future<List<dynamic>> getPlaylists(int userId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/data.php?type=playlists&user_id=$userId"),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }

  static Future<void> uploadSong({
    required String title,
    required String artistId,
    required File audioFile,
    required File imageFile,
    required Function(double) onProgress, // Added progress callback
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse("$baseUrl/upload_song.php"),
    );

    request.fields['title'] = title;
    request.fields['artist_id'] = artistId;

    request.files.add(
      await http.MultipartFile.fromPath('audio', audioFile.path),
    );
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    // Calculate total length for progress tracking
    int totalLength = request.contentLength;
    int bytesSent = 0;

    final httpClient = http.Client();
    final streamedResponse = await httpClient.send(request);

    // Listen to the response stream to track progress
    streamedResponse.stream.listen(
      (List<int> chunk) {
        bytesSent += chunk.length;
        onProgress(bytesSent / totalLength);
      },
      onDone: () async {
        final response = await http.Response.fromStream(streamedResponse);
        final res = jsonDecode(response.body);
        if (res['success'] != true) throw res['message'] ?? "Upload failed";
      },
      onError: (e) => throw e,
    );
  }
}
