class Song {
  final int id;
  final String title;
  final String? artist;
  final String? audioUrl;
  final String? imageUrl;
  bool isFavorite;

  Song({
    required this.id,
    required this.title,
    this.artist,
    this.audioUrl,
    this.imageUrl,
    this.isFavorite = false,
  });

  // Factory to create Song from Database/JSON map
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['song_id'],
      title: json['title'] ?? 'Unknown Title',
      artist: json['artist_name'], // Joined from artists table
      imageUrl: json['cover_image'],
      audioUrl: json['audio_url'],
    );
  }
}