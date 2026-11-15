import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latihan_responsi/models/character_model.dart';
import 'package:latihan_responsi/providers/favorites_provider.dart';
import 'package:latihan_responsi/screens/favorite_screen.dart';
import 'package:latihan_responsi/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createFavoriteTestWidget({
  required FavoritesProvider favoritesProvider,
  Widget? child,
}) {
  return ChangeNotifierProvider<FavoritesProvider>.value(
    value: favoritesProvider,
    child: MaterialApp(
      home: Scaffold(
        body: child ?? const FavoriteScreen(),
      ),
    ),
  );
}

final sampleCharacter1 = CharacterModel(
  id: 1,
  name: 'Rick Sanchez',
  status: 'Alive',
  species: 'Human',
  gender: 'Male',
  image: 'https://rickandmortyapi.com/api/character/avatar/1.jpeg',
  origin: 'Earth (C-137)',
  location: 'Citadel of Ricks',
);

final sampleCharacter2 = CharacterModel(
  id: 2,
  name: 'Morty Smith',
  status: 'Alive',
  species: 'Human',
  gender: 'Male',
  image: 'https://rickandmortyapi.com/api/character/avatar/2.jpeg',
  origin: 'Earth (C-137)',
  location: 'Earth',
);

void main() {
  group('Favorites SharedPreferences Persistence Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saves and loads favorites in JSON string format persistently', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = FavoritesProvider(preferences: prefs);

      // 1. Initial state
      await provider.loadFavorites();
      expect(provider.favorites, isEmpty);

      // 2. Add characters to favorites
      await provider.addFavorite(sampleCharacter1);
      await provider.addFavorite(sampleCharacter2);

      expect(provider.favorites.length, 2);
      expect(provider.isFavorite(1), isTrue);
      expect(provider.isFavorite(2), isTrue);

      // 3. Inspect raw JSON in SharedPreferences
      final rawJson = prefs.getString(AppConstants.prefFavorites);
      expect(rawJson, isNotNull);
      final List<dynamic> decoded = json.decode(rawJson!);
      expect(decoded.length, 2);
      expect(decoded.first['name'], 'Rick Sanchez');

      // 4. Simulate app restart by instantiating a new provider
      final reloadedProvider = FavoritesProvider(preferences: prefs);
      await reloadedProvider.loadFavorites();

      expect(reloadedProvider.favorites.length, 2);
      expect(reloadedProvider.isFavorite(1), isTrue);
      expect(reloadedProvider.isFavorite(2), isTrue);
      expect(reloadedProvider.favorites.first.name, 'Rick Sanchez');
      expect(reloadedProvider.favorites.last.name, 'Morty Smith');

      // 5. Remove character from favorites
      await reloadedProvider.removeFavorite(1);
      expect(reloadedProvider.isFavorite(1), isFalse);
      expect(reloadedProvider.favorites.length, 1);

      // 6. Verify SharedPreferences was updated after removal
      final updatedJson = prefs.getString(AppConstants.prefFavorites);
      final List<dynamic> updatedDecoded = json.decode(updatedJson!);
      expect(updatedDecoded.length, 1);
      expect(updatedDecoded.first['name'], 'Morty Smith');
    });

    test('toggleFavorite adds when not present and removes when present', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = FavoritesProvider(preferences: prefs);

      final added = await provider.toggleFavorite(sampleCharacter1);
      expect(added, isTrue);
      expect(provider.isFavorite(1), isTrue);

      final removed = await provider.toggleFavorite(sampleCharacter1);
      expect(removed, isFalse);
      expect(provider.isFavorite(1), isFalse);
    });
  });

  group('FavoriteScreen Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('displays empty state when no favorite characters are saved', (tester) async {
      final provider = FavoritesProvider();
      await provider.loadFavorites();

      await tester.pumpWidget(createFavoriteTestWidget(favoritesProvider: provider));

      expect(find.text('Belum Ada Karakter Favorit'), findsOneWidget);
      expect(
        find.textContaining('Jelajahi daftar karakter di menu Home'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    });

    testWidgets('displays list of favorites and allows swipe-to-delete with undo', (tester) async {
      final provider = FavoritesProvider();
      await provider.addFavorite(sampleCharacter1);
      await provider.addFavorite(sampleCharacter2);

      await tester.pumpWidget(createFavoriteTestWidget(favoritesProvider: provider));

      expect(find.text('Tersimpan (2)'), findsOneWidget);
      expect(find.text('Rick Sanchez'), findsOneWidget);
      expect(find.text('Morty Smith'), findsOneWidget);

      // Swipe to delete Rick Sanchez
      final dismissibleFinder = find.byKey(const Key('favorite_character_1'));
      expect(dismissibleFinder, findsOneWidget);

      await tester.drag(dismissibleFinder, const Offset(-500.0, 0.0));
      await tester.pumpAndSettle();

      // Verify SnackBar confirmation is shown
      expect(find.text('Rick Sanchez dihapus dari favorit.'), findsOneWidget);
      expect(find.text('BATAL'), findsOneWidget);

      // Verify Rick is removed from list and provider
      expect(find.text('Rick Sanchez'), findsNothing);
      expect(find.text('Morty Smith'), findsOneWidget);
      expect(provider.isFavorite(1), isFalse);
      expect(provider.favorites.length, 1);

      // Tap BATAL (Undo) action in SnackBar
      await tester.tap(find.text('BATAL'));
      await tester.pumpAndSettle();

      // Verify Rick Sanchez is restored
      expect(provider.isFavorite(1), isTrue);
      expect(find.text('Rick Sanchez'), findsOneWidget);
      expect(find.text('Morty Smith'), findsOneWidget);
    });
  });
}
