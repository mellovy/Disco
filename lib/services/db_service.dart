import 'dart:convert';
import 'dart:typed_data';
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

  static Future<bool> changePassword({
    required int userId,
    required String username,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/data.php?type=change_password"),
        body: {
          "user_id": userId.toString(),
          "username": username,
          "current_password": currentPassword,
          "new_password": newPassword,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      print("Change password error: $e");
    }
    return false;
  }

  static Future<List<Song>> fetchAllSongs(int userId) async {
    try {
      final response = await http.get(
        Uri.parse(
          "$baseUrl/data.php?type=songs&user_id=$userId&t=${DateTime.now().millisecondsSinceEpoch}",
        ),
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        List data = jsonDecode(response.body);
        return data.map((s) {
          int id = int.parse(s['song_id'].toString());
          return Song(
            id: id,
            title: s['title'] ?? 'Untitled',
            artist: s['artist_name'] ?? 'Unknown Artist',
            audioUrl: "$baseUrl/get_file.php?id=$id&field=audio_url",
            imageUrl: "$baseUrl/get_file.php?id=$id&field=cover_image",
            isFavorite: s['is_favorite'] == 1,
          );
        }).toList();
      }
    } catch (e) {
      print("Fetch Error: $e");
    }
    return [];
  }

  static Future<bool> toggleFavorite(int userId, int songId) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/data.php?type=toggle_favorite"),
        body: {"user_id": userId.toString(), "song_id": songId.toString()},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['success'] == true;
      }
    } catch (e) {
      print("Favorite toggle error: $e");
    }
    return false;
  }

  static Future<List<dynamic>> getPlaylists(int userId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/data.php?type=playlists&user_id=$userId"),
    );
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  // --- PREFERENCES API ---
  static Future<bool> getDarkMode(int userId) async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/preferences.php?user_id=$userId"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['dark_mode'] == 1; // Returns true if dark mode is enabled in the DB
      }
    } catch (e) {
      print("Pref error: $e");
    }
    return false;
  }

  static Future<void> saveDarkMode(int userId, bool isDark) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/preferences.php"),
        body: {
          "user_id": userId.toString(),
          "dark_mode": isDark ? "1" : "0", // Sends 1 for dark, 0 for light
        }
      );
    } catch (e) {
      print("Pref save error: $e");
    }
  }

  static Future<bool> uploadSong({
    required String title,
    required String artistName,
    required Uint8List audioBytes,
    required String audioName,
    required Uint8List imageBytes,
    required String imageName,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/upload_song.php"),
      );
      request.fields['title'] = title;
      request.fields['artist_name'] = artistName;
      request.files.add(
        http.MultipartFile.fromBytes('audio', audioBytes, filename: audioName),
      );
      request.files.add(
        http.MultipartFile.fromBytes('image', imageBytes, filename: imageName),
      );
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body)['success'] == true;
        } catch(e) {
          print("JSON Decode error on upload. Server returned: ${response.body}");
          return false;
        }
      } else {
        print("Upload failed with server status code: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Upload exception: $e");
      return false;
    }
  }
}