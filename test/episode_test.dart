import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latihan_responsi/models/episode_model.dart';
import 'package:latihan_responsi/providers/episode_provider.dart';
import 'package:latihan_responsi/screens/episode_screen.dart';
import 'package:latihan_responsi/services/api_service.dart';
import 'package:provider/provider.dart';

Widget createEpisodeTestWidget({
  required EpisodeProvider episodeProvider,
}) {
  return ChangeNotifierProvider<EpisodeProvider>.value(
    value: episodeProvider,
    child: const MaterialApp(
      home: Scaffold(
        body: EpisodeScreen(),
      ),
    ),
  );
}

final sampleEpisode1 = EpisodeModel(
  id: 1,
  name: 'Pilot',
  airDate: 'December 2, 2013',
  episode: 'S01E01',
);

final sampleEpisode2 = EpisodeModel(
  id: 2,
  name: 'Lawnmower Dog',
  airDate: 'December 9, 2013',
  episode: 'S01E02',
);

void main() {
  group('EpisodeProvider Unit Tests', () {
    test('fetchEpisodes populates episodes list on 200 response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'results': [sampleEpisode1.toJson(), sampleEpisode2.toJson()]
          }),
          200,
        );
      });

      final apiService = ApiService(client: mockClient);
      final provider = EpisodeProvider(apiService: apiService);

      expect(provider.episodes, isEmpty);
      expect(provider.isLoading, isFalse);

      await provider.fetchEpisodes();

      expect(provider.isLoading, isFalse);
      expect(provider.episodes.length, 2);
      expect(provider.episodes.first.name, 'Pilot');
      expect(provider.episodes.first.airDate, 'December 2, 2013');
      expect(provider.episodes.first.episode, 'S01E01');
      expect(provider.errorMessage, isNull);
    });

    test('fetchEpisodes handles server error and sets errorMessage', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final apiService = ApiService(client: mockClient);
      final provider = EpisodeProvider(apiService: apiService);

      await provider.fetchEpisodes();

      expect(provider.episodes, isEmpty);
      expect(provider.errorMessage, isNotNull);
    });

    test('retry calls fetchEpisodes again', () async {
      int calls = 0;
      final mockClient = MockClient((request) async {
        calls++;
        if (calls == 1) {
          return http.Response('Error', 500);
        }
        return http.Response(
          json.encode({
            'results': [sampleEpisode1.toJson()]
          }),
          200,
        );
      });

      final apiService = ApiService(client: mockClient);
      final provider = EpisodeProvider(apiService: apiService);

      await provider.fetchEpisodes();
      expect(provider.errorMessage, isNotNull);

      provider.retry();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.episodes.length, 1);
      expect(provider.errorMessage, isNull);
    });
  });

  group('EpisodeScreen Widget Tests', () {
    testWidgets('displays error state and retry button on fetch error', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response('Network Error', 500);
      });
      final provider = EpisodeProvider(apiService: ApiService(client: mockClient));

      await tester.pumpWidget(createEpisodeTestWidget(episodeProvider: provider));
      await tester.pumpAndSettle();

      expect(find.text('Gagal Memuat Episode'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    });

    testWidgets('displays list of episodes with name and air date', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'results': [sampleEpisode1.toJson(), sampleEpisode2.toJson()]
          }),
          200,
        );
      });
      final provider = EpisodeProvider(apiService: ApiService(client: mockClient));

      await tester.pumpWidget(createEpisodeTestWidget(episodeProvider: provider));
      await tester.pumpAndSettle();

      expect(find.text('Total Episode (2)'), findsOneWidget);
      expect(find.text('Pilot'), findsOneWidget);
      expect(find.text('December 2, 2013'), findsOneWidget);
      expect(find.text('S01E01'), findsOneWidget);

      expect(find.text('Lawnmower Dog'), findsOneWidget);
      expect(find.text('December 9, 2013'), findsOneWidget);
      expect(find.text('S01E02'), findsOneWidget);
    });
  });
}

