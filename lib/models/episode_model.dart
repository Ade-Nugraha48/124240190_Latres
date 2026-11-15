class EpisodeModel {
  final int id;
  final String name;
  final String airDate;
  final String episode;

  const EpisodeModel({
    required this.id,
    required this.name,
    required this.airDate,
    required this.episode,
  });

  EpisodeModel copyWith({
    int? id,
    String? name,
    String? airDate,
    String? episode,
  }) {
    return EpisodeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      airDate: airDate ?? this.airDate,
      episode: episode ?? this.episode,
    );
  }

  factory EpisodeModel.fromJson(Map<String, dynamic> json) {
    return EpisodeModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: (json['name'] ?? '').toString(),
      airDate: (json['air_date'] ?? json['airDate'] ?? '').toString(),
      episode: (json['episode'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'air_date': airDate,
      'episode': episode,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpisodeModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          airDate == other.airDate &&
          episode == other.episode;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ airDate.hashCode ^ episode.hashCode;

  @override
  String toString() {
    return 'EpisodeModel(id: $id, name: $name, airDate: $airDate, episode: $episode)';
  }
}

