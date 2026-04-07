class Song {
  final int? id;
  final String title;
  final String? artist;
  final String? imageUrl;
  final String? audioUrl;
  final int? duration;

  Song({
    this.id,
    required this.title,
    this.artist,
    this.imageUrl,
    this.audioUrl,
    this.duration,
  });

  // Factory to create Song from Database/JSON map
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['song_id'],
      title: json['title'] ?? 'Unknown Title',
      artist: json['artist_name'], // Joined from artists table
      imageUrl: json['cover_image'],
      audioUrl: json['audio_url'],
      duration: json['duration'],
    );
  }
}