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
        headers: {"Accept": "application/json"},
        body: {
          "user_id": userId.toString(),
          "song_id": songId.toString(),
        },
      );
      print("toggleFavorite status: ${res.statusCode}");
      print("toggleFavorite body: ${res.body}");
      final body = res.body.trim();
      if (res.statusCode == 200 && body.isNotEmpty) {
        try {
          final data = jsonDecode(body);
          return data['success'] == true;
        } catch (e) {
          print("toggleFavorite JSON parse error: $e — raw: $body");
          // If body is non-empty but not JSON, treat a 200 as success
          return true;
        }
      }
    } catch (e) {
      print("Favorite toggle error: $e");
    }
    return false;
  }

  static Future<List<dynamic>> getPlaylists(int userId) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/data.php?type=playlists&user_id=$userId"),
      );
      final body = res.body.trim();
      if (res.statusCode == 200 && body.isNotEmpty) {
        return jsonDecode(body);
      }
    } catch (e) {
      print("Get playlists error: $e");
    }
    return [];
  }

  /// Create a new playlist for the user. Returns the new playlist id or null.
  static Future<int?> createPlaylist({
    required int userId,
    required String name,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/data.php?type=create_playlist"),
        body: {
          "user_id": userId.toString(),
          "name": name,
        },
      );
      final body = res.body.trim();
      if (res.statusCode == 200 && body.isNotEmpty) {
        try {
          final data = jsonDecode(body);
          if (data['success'] == true) {
            final raw = data['playlist_id'];
            if (raw == null) return null;
            return raw is int ? raw : int.tryParse(raw.toString());
          }
        } catch (e) {
          print("Create playlist JSON parse error: $e — raw: $body");
        }
      } else {
        print("Create playlist bad response: status=${res.statusCode} body='${res.body}'");
      }
    } catch (e) {
      print("Create playlist error: $e");
    }
    return null;
  }

  /// Add a song to a playlist. Returns true on success.
  static Future<bool> addSongToPlaylist({
    required int playlistId,
    required int songId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/data.php?type=add_to_playlist"),
        body: {
          "playlist_id": playlistId.toString(),
          "song_id": songId.toString(),
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['success'] == true;
      }
    } catch (e) {
      print("Add to playlist error: $e");
    }
    return false;
  }

  // --- PREFERENCES API ---
  static Future<bool> getDarkMode(int userId) async {
    try {
      final res =
          await http.get(Uri.parse("$baseUrl/preferences.php?user_id=$userId"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['dark_mode'] == 1;
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
          "dark_mode": isDark ? "1" : "0",
        },
      );
    } catch (e) {
      print("Pref save error: $e");
    }
  }

  /// Returns an error message string or null if successful.
  static Future<String?> uploadSong({
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
          final decoded = jsonDecode(response.body);
          if (decoded['success'] == true) {
            return null;
          } else {
            return decoded['error'] ?? "Unknown server error";
          }
        } catch (e) {
          return "JSON Decode error: ${response.body}";
        }
      } else {
        return "Upload failed with status: ${response.statusCode}";
      }
    } catch (e) {
      return "Upload exception: $e";
    }
  }
}