import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latihan_responsi/models/character_model.dart';
import 'package:latihan_responsi/models/episode_model.dart';
import 'package:latihan_responsi/providers/auth_provider.dart';
import 'package:latihan_responsi/providers/character_provider.dart';
import 'package:latihan_responsi/providers/episode_provider.dart';
import 'package:latihan_responsi/providers/favorites_provider.dart';
import 'package:latihan_responsi/screens/detail_screen.dart';
import 'package:latihan_responsi/screens/episode_screen.dart';
import 'package:latihan_responsi/screens/favorite_screen.dart';
import 'package:latihan_responsi/screens/home_screen.dart';
import 'package:latihan_responsi/screens/login_screen.dart';
import 'package:latihan_responsi/screens/main_navigation_screen.dart';
import 'package:latihan_responsi/screens/register_screen.dart';
import 'package:latihan_responsi/services/api_service.dart';
import 'package:latihan_responsi/services/database_helper.dart';
import 'package:latihan_responsi/services/session_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Widget createQAApp({
  AuthProvider? authProvider,
  CharacterProvider? characterProvider,
  FavoritesProvider? favoritesProvider,
  EpisodeProvider? episodeProvider,
  Widget? home,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => authProvider ?? AuthProvider(),
      ),
      ChangeNotifierProvider<CharacterProvider>(
        create: (_) => characterProvider ?? CharacterProvider(),
      ),
      ChangeNotifierProvider<FavoritesProvider>(
        create: (_) => favoritesProvider ?? FavoritesProvider(),
      ),
      ChangeNotifierProvider<EpisodeProvider>(
        create: (_) => episodeProvider ?? EpisodeProvider(),
      ),
    ],
    child: MaterialApp(
      home: home ?? const MainNavigationScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/main': (ctx) {
          final isLoggedIn = ctx.watch<AuthProvider>().isLoggedIn;
          if (!isLoggedIn) {
            return const LoginScreen();
          }
          return const MainNavigationScreen();
        },
      },
    ),
  );
}

final qaRick = CharacterModel(
  id: 1,
  name: 'Rick Sanchez',
  status: 'Alive',
  species: 'Human',
  gender: 'Male',
  image: 'https://rickandmortyapi.com/api/character/avatar/1.jpeg',
  origin: 'Earth (C-137)',
  location: 'Citadel of Ricks',
);

final qaMorty = CharacterModel(
  id: 2,
  name: 'Morty Smith',
  status: 'Alive',
  species: 'Human',
  gender: 'Male',
  image: 'https://rickandmortyapi.com/api/character/avatar/2.jpeg',
  origin: 'Earth (C-137)',
  location: 'Earth',
);

final qaEpisode = EpisodeModel(
  id: 1,
  name: 'Pilot',
  airDate: 'December 2, 2013',
  episode: 'S01E01',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('E2E QA Audit Suite: Backend & Auth Integration', () {
    late Database testDb;
    late DatabaseHelper dbHelper;
    late SessionService sessionService;
    late AuthProvider authProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      testDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await testDb.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL
        )
      ''');

      dbHelper = DatabaseHelper.withDatabase(testDb);
      sessionService = SessionService();
      authProvider = AuthProvider(
        dbHelper: dbHelper,
        sessionService: sessionService,
      );
    });

    tearDown(() async {
      await testDb.close();
    });

    test('QA-1: Complete SQLite + Session Lifecycle (Register, Duplicate, Login, Logout)', () async {
      // 1. Initial State
      expect(authProvider.isLoggedIn, isFalse);
      expect(authProvider.currentUser, isNull);

      // 2. Register user into SQLite
      final regSuccess = await authProvider.register('qa_scientist', 'portal_pass');
      expect(regSuccess, isTrue);

      final dbUser = await dbHelper.getUserByUsername('qa_scientist');
      expect(dbUser, isNotNull);
      expect(dbUser!.username, 'qa_scientist');
      expect(dbUser.password, 'portal_pass');

      // 3. Duplicate prevention check
      final duplicateReg = await authProvider.register('qa_scientist', 'other_pass');
      expect(duplicateReg, isFalse);
      expect(authProvider.errorMessage, contains('sudah digunakan'));

      // 4. Invalid Login attempt
      final loginFailed = await authProvider.login('qa_scientist', 'wrong_pass');
      expect(loginFailed, isFalse);
      expect(authProvider.isLoggedIn, isFalse);
      expect(authProvider.errorMessage, contains('salah'));

      // 5. Valid Login attempt
      final loginSuccess = await authProvider.login('qa_scientist', 'portal_pass');
      expect(loginSuccess, isTrue);
      expect(authProvider.isLoggedIn, isTrue);
      expect(authProvider.currentUser, 'qa_scientist');

      // 6. Verify session stored in SharedPreferences
      expect(await sessionService.isLoggedIn(), isTrue);
      expect(await sessionService.getCurrentUser(), 'qa_scientist');

      // 7. Check session persistence across provider instance
      final reloadedAuth = AuthProvider(
        dbHelper: dbHelper,
        sessionService: sessionService,
      );
      await reloadedAuth.checkSession();
      expect(reloadedAuth.isLoggedIn, isTrue);
      expect(reloadedAuth.currentUser, 'qa_scientist');

      // 8. Logout and verify session cleared
      await reloadedAuth.logout();
      expect(reloadedAuth.isLoggedIn, isFalse);
      expect(reloadedAuth.currentUser, isNull);
      expect(await sessionService.isLoggedIn(), isFalse);
    });
  });

  group('E2E QA Audit Suite: UI & Navigation Integration', () {
    late ApiService mockApiService;
    late CharacterProvider characterProvider;
    late FavoritesProvider favoritesProvider;
    late EpisodeProvider episodeProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      favoritesProvider = FavoritesProvider(preferences: prefs);

      final mockClient = MockClient((request) async {
        final path = request.url.path;
        final query = request.url.queryParameters;

        if (path.contains('/character/1')) {
          return http.Response(json.encode(qaRick.toJson()), 200);
        } else if (path.endsWith('/character')) {
          if (query['name'] == 'nonexistent') {
            return http.Response(json.encode({'error': 'There is nothing here'}), 404);
          }
          return http.Response(
            json.encode({
              'results': [qaRick.toJson(), qaMorty.toJson()]
            }),
            200,
          );
        } else if (path.endsWith('/episode')) {
          return http.Response(
            json.encode({
              'results': [qaEpisode.toJson()]
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      mockApiService = ApiService(client: mockClient);
      characterProvider = CharacterProvider(apiService: mockApiService);
      episodeProvider = EpisodeProvider(apiService: mockApiService);
    });

    testWidgets('QA-2: Login and Register Form Validation', (tester) async {
      await tester.pumpWidget(createQAApp(home: const LoginScreen()));
      await tester.pumpAndSettle();

      // Submit empty login form
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      expect(find.text('Username wajib diisi'), findsOneWidget);
      expect(find.text('Password wajib diisi'), findsOneWidget);

      // Navigate to RegisterScreen
      await tester.tap(find.text('Daftar Sekarang'));
      await tester.pumpAndSettle();

      expect(find.text('Buat Akun Baru'), findsOneWidget);

      // Submit empty register form
      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();

      expect(find.text('Username wajib diisi'), findsOneWidget);
      expect(find.text('Password wajib diisi'), findsOneWidget);
      expect(find.text('Konfirmasi password wajib diisi'), findsOneWidget);
    });

    testWidgets('QA-3: Home Character Explorer, Filter Status & Search', (tester) async {
      await tester.pumpWidget(
        createQAApp(
          characterProvider: characterProvider,
          favoritesProvider: favoritesProvider,
          home: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify characters displayed
      expect(find.text('Rick Sanchez'), findsOneWidget);
      expect(find.text('Morty Smith'), findsOneWidget);

      // Verify status filter chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Alive'), findsOneWidget);
      expect(find.text('Dead'), findsOneWidget);
      expect(find.text('Unknown'), findsOneWidget);

      // Tap filter
      await tester.tap(find.text('Alive'));
      await tester.pumpAndSettle();
      expect(characterProvider.selectedStatus, 'Alive');

      // Search field test
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Rick');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(characterProvider.searchQuery, 'Rick');
    });

    testWidgets('QA-4: Detail Screen Data Integrity & Real-Time Sync', (tester) async {
      await tester.pumpWidget(
        createQAApp(
          favoritesProvider: favoritesProvider,
          home: DetailScreen.fromCharacter(
            character: qaRick,
            apiService: mockApiService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Data verification
      expect(find.text('Rick Sanchez'), findsNWidgets(2));
      expect(find.text('Alive'), findsOneWidget);
      expect(find.text('Human'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Earth (C-137)'), findsOneWidget);
      expect(find.text('Citadel of Ricks'), findsOneWidget);

      // Favorite toggle verification
      expect(favoritesProvider.isFavorite(1), isFalse);
      await tester.tap(find.text('Simpan ke Favorit'));
      await tester.pumpAndSettle();

      expect(favoritesProvider.isFavorite(1), isTrue);
      expect(find.text('Rick Sanchez ditambahkan ke favorit!'), findsOneWidget);
      expect(find.text('Tersimpan di Favorit'), findsOneWidget);
    });

    testWidgets('QA-5: Favorites Persistence & Swipe-to-Delete', (tester) async {
      await favoritesProvider.addFavorite(qaRick);
      await favoritesProvider.addFavorite(qaMorty);

      await tester.pumpWidget(
        createQAApp(
          favoritesProvider: favoritesProvider,
          home: const FavoriteScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tersimpan (2)'), findsOneWidget);
      expect(find.text('Rick Sanchez'), findsOneWidget);
      expect(find.text('Morty Smith'), findsOneWidget);

      // Swipe to delete Rick
      final itemFinder = find.byKey(const Key('favorite_character_1'));
      await tester.drag(itemFinder, const Offset(-500.0, 0.0));
      await tester.pumpAndSettle();

      expect(favoritesProvider.isFavorite(1), isFalse);
      expect(find.text('Rick Sanchez dihapus dari favorit.'), findsOneWidget);
      expect(find.text('Rick Sanchez'), findsNothing);
      expect(find.text('Morty Smith'), findsOneWidget);
    });

    testWidgets('QA-6: Episode Screen Rendering & Navigation', (tester) async {
      await tester.pumpWidget(
        createQAApp(
          episodeProvider: episodeProvider,
          home: const EpisodeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pilot'), findsOneWidget);
      expect(find.text('December 2, 2013'), findsOneWidget);
      expect(find.text('S01E01'), findsOneWidget);
    });

    testWidgets('QA-7: Bottom Navigation Bar 3-way switching with IndexedStack state preservation', (tester) async {
      await tester.pumpWidget(
        createQAApp(
          characterProvider: characterProvider,
          favoritesProvider: favoritesProvider,
          episodeProvider: episodeProvider,
          home: const MainNavigationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rick & Morty Characters'), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);

      // Switch to Favorites tab
      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();
      expect(find.text('Favorite Characters'), findsOneWidget);
      expect(find.byType(FavoriteScreen), findsOneWidget);

      // Switch to Episodes tab
      await tester.tap(find.text('Episodes').first);
      await tester.pumpAndSettle();
      expect(find.text('Episodes'), findsWidgets);
      expect(find.byType(EpisodeScreen), findsOneWidget);

      // Switch back to Characters tab (preserved)
      await tester.tap(find.text('Characters'));
      await tester.pumpAndSettle();
      expect(find.text('Rick & Morty Characters'), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
