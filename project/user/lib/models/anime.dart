class AnimeModel {
  final String animeId;
  final String animeName;
  final String? animePoster;
  final String? animeBanner;
  final String? animeDescription;

  AnimeModel({
    required this.animeId,
    required this.animeName,
    this.animePoster,
    this.animeBanner,
    this.animeDescription,
  });

  factory AnimeModel.fromMap(Map<String, dynamic> map) {
    return AnimeModel(
      animeId: map['anime_id'].toString(),
      animeName: map['anime_name'] ?? '',
      animePoster: map['anime_poster'],
      animeBanner: map['anime_banner'],
      animeDescription: map['anime_description'],
    );
  }
} 