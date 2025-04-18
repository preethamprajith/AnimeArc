class EpisodeModel {
  final String episodeId;
  final String animeId;
  final String episodeNumber;
  final String episodeTitle;
  final String episodeUrl;
  final String? episodeThumbnail;
  final String? duration;
  final DateTime? releaseDate;

  EpisodeModel({
    required this.episodeId,
    required this.animeId,
    required this.episodeNumber,
    required this.episodeTitle,
    required this.episodeUrl,
    this.episodeThumbnail,
    this.duration,
    this.releaseDate,
  });

  factory EpisodeModel.fromMap(Map<String, dynamic> map) {
    return EpisodeModel(
      episodeId: map['episode_id'].toString(),
      animeId: map['anime_id'].toString(),
      episodeNumber: map['episode_number'].toString(),
      episodeTitle: map['episode_title'] ?? '',
      episodeUrl: map['episode_url'] ?? '',
      episodeThumbnail: map['episode_thumbnail'],
      duration: map['duration'],
      releaseDate: map['release_date'] != null 
          ? DateTime.parse(map['release_date']) 
          : null,
    );
  }
} 