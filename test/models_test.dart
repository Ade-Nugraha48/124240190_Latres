import 'package:flutter_test/flutter_test.dart';
import 'package:latihan_responsi/models/character_model.dart';
import 'package:latihan_responsi/models/episode_model.dart';
import 'package:latihan_responsi/models/user_model.dart';

void main() {
  group('UserModel Unit Tests', () {
    test('should serialize and deserialize from/to Map and JSON correctly', () {
      final user = UserModel(
        id: 1,
        username: 'rick_sanchez',
        password: 'password123',
      );

      final map = user.toMap();
      expect(map['id'], 1);
      expect(map['username'], 'rick_sanchez');
      expect(map['password'], 'password123');

      final userFromMap = UserModel.fromMap(map);
      expect(userFromMap, equals(user));
      expect(userFromMap.id, 1);
      expect(userFromMap.username, 'rick_sanchez');
      expect(userFromMap.password, 'password123');

      final json = user.toJson();
      final userFromJson = UserModel.fromJson(json);
      expect(userFromJson, equals(user));
    });

    test('copyWith should create new instance with updated properties', () {
      final user = UserModel(
        id: 1,
        username: 'morty',
        password: 'pass',
      );

      final updatedUser = user.copyWith(username: 'morty_smith');
      expect(updatedUser.id, 1);
      expect(updatedUser.username, 'morty_smith');
      expect(updatedUser.password, 'pass');
    });
  });

  group('CharacterModel Unit Tests', () {
    test('should parse from standard Rick & Morty API JSON', () {
      final apiJson = {
        'id': 1,
        'name': 'Rick Sanchez',
        'status': 'Alive',
        'species': 'Human',
        'gender': 'Male',
        'image': 'https://rickandmortyapi.com/api/character/avatar/1.jpeg',
        'origin': {
          'name': 'Earth (C-137)',
          'url': 'https://rickandmortyapi.com/api/location/1',
        },
        'location': {
          'name': 'Citadel of Ricks',
          'url': 'https://rickandmortyapi.com/api/location/3',
        },
      };

      final character = CharacterModel.fromJson(apiJson);

      expect(character.id, 1);
      expect(character.name, 'Rick Sanchez');
      expect(character.status, 'Alive');
      expect(character.species, 'Human');
      expect(character.gender, 'Male');
      expect(character.image, 'https://rickandmortyapi.com/api/character/avatar/1.jpeg');
      expect(character.origin, 'Earth (C-137)');
      expect(character.location, 'Citadel of Ricks');
      expect(character.isAlive, isTrue);
      expect(character.isDead, isFalse);
      expect(character.isUnknown, isFalse);
    });

    test('should correctly identify dead and unknown status', () {
      final deadCharacter = CharacterModel.fromJson({
        'id': 2,
        'name': 'Dead Character',
        'status': 'Dead',
        'species': 'Alien',
        'gender': 'Unknown',
        'image': '',
        'origin': {'name': 'Unknown'},
        'location': {'name': 'Unknown'},
      });

      expect(deadCharacter.isDead, isTrue);
      expect(deadCharacter.isAlive, isFalse);
      expect(deadCharacter.isUnknown, isFalse);

      final unknownCharacter = deadCharacter.copyWith(status: 'unknown');
      expect(unknownCharacter.isUnknown, isTrue);
      expect(unknownCharacter.isAlive, isFalse);
      expect(unknownCharacter.isDead, isFalse);
    });

    test('should handle string origin and location for persistent storage serialization', () {
      final storedJson = {
        'id': 10,
        'name': 'Summer Smith',
        'status': 'Alive',
        'species': 'Human',
        'gender': 'Female',
        'image': 'https://example.com/summer.png',
        'origin': 'Earth (Replacement Dimension)',
        'location': 'Earth (Replacement Dimension)',
      };

      final character = CharacterModel.fromJson(storedJson);
      expect(character.origin, 'Earth (Replacement Dimension)');
      expect(character.location, 'Earth (Replacement Dimension)');

      final serialized = character.toJson();
      expect(serialized['id'], 10);
      expect(serialized['name'], 'Summer Smith');
      expect((serialized['origin'] as Map)['name'], 'Earth (Replacement Dimension)');
      expect((serialized['location'] as Map)['name'], 'Earth (Replacement Dimension)');
    });
  });

  group('EpisodeModel Unit Tests', () {
    test('should parse from API JSON correctly', () {
      final episodeJson = {
        'id': 1,
        'name': 'Pilot',
        'air_date': 'December 2, 2013',
        'episode': 'S01E01',
      };

      final episode = EpisodeModel.fromJson(episodeJson);

      expect(episode.id, 1);
      expect(episode.name, 'Pilot');
      expect(episode.airDate, 'December 2, 2013');
      expect(episode.episode, 'S01E01');

      final serialized = episode.toJson();
      expect(serialized['id'], 1);
      expect(serialized['name'], 'Pilot');
      expect(serialized['air_date'], 'December 2, 2013');
      expect(serialized['episode'], 'S01E01');
    });
  });
}

