import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/character_model.dart';
import '../models/episode_model.dart';
import '../utils/constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class ApiService {
  final http.Client _client;
  final String baseUrl;

  ApiService({
    http.Client? client,
    this.baseUrl = AppConstants.apiBaseUrl,
  }) : _client = client ?? http.Client();

  Future<List<CharacterModel>> getCharacters({
    int page = 1,
    String? status,
    String? name,
  }) async {
    try {
      final queryParameters = <String, String>{
        'page': page.toString(),
      };

      if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
        queryParameters['status'] = status.toLowerCase();
      }

      if (name != null && name.trim().isNotEmpty) {
        queryParameters['name'] = name.trim();
      }

      final uri = Uri.parse('$baseUrl${AppConstants.characterEndpoint}').replace(
        queryParameters: queryParameters,
      );

      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];
        return results
            .map((item) => CharacterModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 404) {
        // Rick & Morty API returns 404 when search or filter returns no results
        return [];
      } else {
        throw ApiException(
          'Failed to load characters',
          response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<CharacterModel> getCharacterDetail(int id) async {
    try {
      final uri = Uri.parse('$baseUrl${AppConstants.characterEndpoint}/$id');
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return CharacterModel.fromJson(data);
      } else {
        throw ApiException(
          'Failed to load character detail for ID $id',
          response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<List<EpisodeModel>> getEpisodes({int page = 1}) async {
    try {
      final uri = Uri.parse('$baseUrl${AppConstants.episodeEndpoint}').replace(
        queryParameters: {'page': page.toString()},
      );
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];
        return results
            .map((item) => EpisodeModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw ApiException(
          'Failed to load episodes',
          response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }
}

