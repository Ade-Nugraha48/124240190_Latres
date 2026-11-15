import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latihan_responsi/models/character_model.dart';
import 'package:latihan_responsi/providers/character_provider.dart';
import 'package:latihan_responsi/providers/favorites_provider.dart';
import 'package:latihan_responsi/screens/detail_screen.dart';
import 'package:latihan_responsi/screens/home_screen.dart';
import 'package:latihan_responsi/services/api_service.dart';
import 'package:latihan_responsi/widgets/character_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createHomeTestWidget({
  CharacterProvider? characterProvider,
  FavoritesProvider? favoritesProvider,
  Widget? child,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<CharacterProvider>(
        create: (_) => characterProvider ?? CharacterProvider(),
      ),
      ChangeNotifierProvider<FavoritesProvider>(
        create: (_) => favoritesProvider ?? FavoritesProvider(),
      ),
    ],
    child: MaterialApp(
      home: child ?? const HomeScreen(),
    ),
  );
}

final sampleCharacter = CharacterModel(
  id: 1,
  name: 'Rick Sanchez',
  status: 'Alive',
  species: 'Human',
  gender: 'Male',
  image: 'https://rickandmortyapi.com/api/character/avatar/1.jpeg',
  origin: 'Earth (C-137)',
  location: 'Citadel of Ricks',
);

final sampleDeadCharacter = CharacterModel(
  id: 2,
  name: 'Morty Clone',
  status: 'Dead',
  species: 'Humanoid',
  gender: 'Male',
  image: 'https://rickandmortyapi.com/api/character/avatar/2.jpeg',
  origin: 'Unknown',
  location: 'Earth',
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FavoritesProvider Unit Tests', () {
    test('initially empty and detects isFavorite correctly', () async {
      final favProvider = FavoritesProvider();
      await favProvider.loadFavorites();

      expect(favProvider.favorites, isEmpty);
      expect(favProvider.isFavorite(1), isFalse);
    });

    test('toggleFavorite adds then removes character with persistence', () async {
      final favProvider = FavoritesProvider();
      await favProvider.loadFavorites();

      final added = await favProvider.toggleFavorite(sampleCharacter);
      expect(added, isTrue);
      expect(favProvider.isFavorite(sampleCharacter.id), isTrue);
      expect(favProvider.favorites.length, 1);

      // Verify persistence by loading into a new provider
      final newFavProvider = FavoritesProvider();
      await newFavProvider.loadFavorites();
      expect(newFavProvider.isFavorite(sampleCharacter.id), isTrue);

      // Toggle again to remove
      final removed = await newFavProvider.toggleFavorite(sampleCharacter);
      expect(removed, isFalse);
      expect(newFavProvider.isFavorite(sampleCharacter.id), isFalse);
      expect(newFavProvider.favorites, isEmpty);
    });
  });

  group('CharacterProvider Unit Tests', () {
    test('fetchCharacters successfully populates character list', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'results': [sampleCharacter.toJson()]
          }),
          200,
        );
      });

      final apiService = ApiService(client: mockClient);
      final provider = CharacterProvider(apiService: apiService);

      expect(provider.isLoading, isFalse);
      await provider.fetchCharacters();

      expect(provider.isLoading, isFalse);
      expect(provider.characters.length, 1);
      expect(provider.characters.first.name, 'Rick Sanchez');
      expect(provider.errorMessage, isNull);
    });

    test('fetchCharacters handles error and retry cleanly', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          return http.Response('Server Error', 500);
        }
        return http.Response(
          json.encode({
            'results': [sampleCharacter.toJson()]
          }),
          200,
        );
      });

      final apiService = ApiService(client: mockClient);
      final provider = CharacterProvider(apiService: apiService);

      await provider.fetchCharacters();
      expect(provider.errorMessage, isNotNull);
      expect(provider.characters, isEmpty);

      // Retry
      provider.retry();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.characters.length, 1);
      expect(provider.errorMessage, isNull);
    });

    test('status filter and search updates trigger requests', () async {
      String? lastUrl;
      final mockClient = MockClient((request) async {
        lastUrl = request.url.toString();
        return http.Response(
          json.encode({
            'results': [sampleCharacter.toJson()]
          }),
          200,
        );
      });

      final apiService = ApiService(client: mockClient);
      final provider = CharacterProvider(apiService: apiService);

      provider.setStatus('Alive');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(lastUrl, contains('status=alive'));

      provider.setSearchQuery('Rick');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(lastUrl, contains('name=Rick'));
      expect(lastUrl, contains('status=alive'));
    });
  });

  group('CharacterCard & DetailScreen Widget Tests', () {
    testWidgets('CharacterCard displays character name, status, and toggles favorite', (tester) async {
      final favProvider = FavoritesProvider();

      await tester.pumpWidget(
        createHomeTestWidget(
          favoritesProvider: favProvider,
          child: Scaffold(
            body: CharacterCard(character: sampleCharacter),
          ),
        ),
      );

      expect(find.text('Rick Sanchez'), findsOneWidget);
      expect(find.text('Alive - Human'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

      // Tap favorite icon
      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.text('Rick Sanchez ditambahkan ke favorit!'), findsOneWidget);
    });

    testWidgets('DetailScreen displays complete character details', (tester) async {
      await tester.pumpWidget(
        createHomeTestWidget(
          child: DetailScreen(character: sampleCharacter),
        ),
      );

      expect(find.text('Rick Sanchez'), findsNWidgets(2)); // AppBar + body
      expect(find.text('Alive'), findsOneWidget);
      expect(find.text('Human'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Earth (C-137)'), findsOneWidget);
      expect(find.text('Citadel of Ricks'), findsOneWidget);
    });
  });

  group('HomeScreen Widget States Tests', () {
    testWidgets('displays error state and retry button on fetch failure', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response('Network Error', 500);
      });
      final provider = CharacterProvider(apiService: ApiService(client: mockClient));

      await tester.pumpWidget(createHomeTestWidget(characterProvider: provider));
      await tester.pumpAndSettle();

      expect(find.text('Gagal Memuat Karakter'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('displays search bar and filter chips', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'results': [sampleCharacter.toJson(), sampleDeadCharacter.toJson()]
          }),
          200,
        );
      });
      final provider = CharacterProvider(apiService: ApiService(client: mockClient));

      await tester.pumpWidget(createHomeTestWidget(characterProvider: provider));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Alive'), findsOneWidget);
      expect(find.text('Dead'), findsOneWidget);
      expect(find.text('Unknown'), findsOneWidget);
      expect(find.text('Rick Sanchez'), findsOneWidget);
      expect(find.text('Morty Clone'), findsOneWidget);
    });
  });
}
