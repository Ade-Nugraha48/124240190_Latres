import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latihan_responsi/services/api_service.dart';

void main() {
  group('ApiService Unit Tests', () {
    test('getCharacters returns list of CharacterModel on 200 response', () async {
      final mockClient = MockClient((request) async {
        final mockResponse = {
          'info': {'count': 1, 'pages': 1},
          'results': [
            {
              'id': 1,
              'name': 'Rick Sanchez',
              'status': 'Alive',
              'species': 'Human',
              'gender': 'Male',
              'image': 'https://rickandmortyapi.com/api/character/avatar/1.jpeg',
              'origin': {'name': 'Earth (C-137)'},
              'location': {'name': 'Citadel of Ricks'},
            }
          ]
        };
        return http.Response(json.encode(mockResponse), 200);
      });

      final apiService = ApiService(client: mockClient);
      final characters = await apiService.getCharacters();

      expect(characters.length, 1);
      expect(characters.first.name, 'Rick Sanchez');
      expect(characters.first.isAlive, isTrue);
    });

    test('getCharacters returns empty list on 404 response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({'error': 'There is nothing here'}), 404);
      });

      final apiService = ApiService(client: mockClient);
      final characters = await apiService.getCharacters(name: 'non_existent_character');

      expect(characters, isEmpty);
    });

    test('getCharacterDetail returns character detail on 200 response', () async {
      final mockClient = MockClient((request) async {
        final mockResponse = {
          'id': 1,
          'name': 'Rick Sanchez',
          'status': 'Alive',
          'species': 'Human',
          'gender': 'Male',
          'image': 'https://rickandmortyapi.com/api/character/avatar/1.jpeg',
          'origin': {'name': 'Earth (C-137)'},
          'location': {'name': 'Citadel of Ricks'},
        };
        return http.Response(json.encode(mockResponse), 200);
      });

      final apiService = ApiService(client: mockClient);
      final character = await apiService.getCharacterDetail(1);

      expect(character.id, 1);
      expect(character.name, 'Rick Sanchez');
    });

    test('getEpisodes returns list of EpisodeModel on 200 response', () async {
      final mockClient = MockClient((request) async {
        final mockResponse = {
          'info': {'count': 1, 'pages': 1},
          'results': [
            {
              'id': 1,
              'name': 'Pilot',
              'air_date': 'December 2, 2013',
              'episode': 'S01E01',
            }
          ]
        };
        return http.Response(json.encode(mockResponse), 200);
      });

      final apiService = ApiService(client: mockClient);
      final episodes = await apiService.getEpisodes();

      expect(episodes.length, 1);
      expect(episodes.first.name, 'Pilot');
      expect(episodes.first.episode, 'S01E01');
    });

    test('throws ApiException on server error 500', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final apiService = ApiService(client: mockClient);

      expect(
        () => apiService.getCharacters(),
        throwsA(isA<ApiException>()),
      );
    });
  });
}

