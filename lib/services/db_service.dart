import 'package:mysql1/mysql1.dart';
import '../models/song.dart';

class DBService {
  static const String _host = 'dbadmin.dcism.org';
  static const int _port = 3306;
  static const String _user = 's24103884_mobdev';
  static const String _pass = 'Disco1025';
  static const String _db = 's24103884_mobdev';

  static Future<MySqlConnection> getConnection() async {
    var settings = ConnectionSettings(
      host: _host,
      port: _port,
      user: _user,
      password: _pass,
      db: _db,
    );
    return await MySqlConnection.connect(settings);
  }

  static Future<List<Song>> fetchAllSongs() async {
    final conn = await getConnection();
    // Joins songs and artists tables based on your SQL schema
    var results = await conn.query(
      'SELECT s.song_id, s.title, s.audio_url, s.cover_image, a.name as artist_name '
      'FROM songs s LEFT JOIN artists a ON s.artist_id = a.artist_id'
    );
    await conn.close();
    
    return results.map((row) => Song(
      id: row['song_id'],
      title: row['title'],
      artist: row['artist_name'],
      audioUrl: row['audio_url'],
      imageUrl: row['cover_image'],
    )).toList();
  }
}