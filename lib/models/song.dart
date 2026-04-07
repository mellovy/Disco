class Song {
  final int? id;
  final String title;
  final String? artist;
  final String? imageUrl;
  final String? audioUrl;

  Song({
    this.id,
    required this.title,
    this.artist,
    this.imageUrl,
    this.audioUrl,
  });
}
