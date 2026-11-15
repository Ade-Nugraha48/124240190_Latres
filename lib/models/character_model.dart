class CharacterModel {
  final int id;
  final String name;
  final String status;
  final String species;
  final String gender;
  final String image;
  final String origin;
  final String location;

  const CharacterModel({
    required this.id,
    required this.name,
    required this.status,
    required this.species,
    required this.gender,
    required this.image,
    required this.origin,
    required this.location,
  });

  bool get isAlive => status.toLowerCase() == 'alive';
  bool get isDead => status.toLowerCase() == 'dead';
  bool get isUnknown => !isAlive && !isDead;

  CharacterModel copyWith({
    int? id,
    String? name,
    String? status,
    String? species,
    String? gender,
    String? image,
    String? origin,
    String? location,
  }) {
    return CharacterModel(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      species: species ?? this.species,
      gender: gender ?? this.gender,
      image: image ?? this.image,
      origin: origin ?? this.origin,
      location: location ?? this.location,
    );
  }

  factory CharacterModel.fromJson(Map<String, dynamic> json) {
    String parseLocationName(dynamic value) {
      if (value is Map<String, dynamic>) {
        return (value['name'] ?? '').toString();
      } else if (value is Map) {
        return (value['name'] ?? '').toString();
      } else if (value is String) {
        return value;
      }
      return '';
    }

    return CharacterModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: (json['name'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      species: (json['species'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      origin: parseLocationName(json['origin']),
      location: parseLocationName(json['location']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'species': species,
      'gender': gender,
      'image': image,
      'origin': {'name': origin},
      'location': {'name': location},
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharacterModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          status == other.status &&
          species == other.species &&
          gender == other.gender &&
          image == other.image &&
          origin == other.origin &&
          location == other.location;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      status.hashCode ^
      species.hashCode ^
      gender.hashCode ^
      image.hashCode ^
      origin.hashCode ^
      location.hashCode;

  @override
  String toString() {
    return 'CharacterModel(id: $id, name: $name, status: $status, species: $species, gender: $gender, image: $image, origin: $origin, location: $location)';
  }
}

