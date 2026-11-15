import 'package:flutter_test/flutter_test.dart';
import 'package:latihan_responsi/models/user_model.dart';
import 'package:latihan_responsi/providers/auth_provider.dart';
import 'package:latihan_responsi/services/database_helper.dart';
import 'package:latihan_responsi/services/session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Setup SQLite FFI for desktop/unit test execution
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('SessionService Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('should return false for isLoggedIn initially', () async {
      final sessionService = SessionService();
      final isLoggedIn = await sessionService.isLoggedIn();
      final currentUser = await sessionService.getCurrentUser();

      expect(isLoggedIn, isFalse);
      expect(currentUser, isNull);
    });

    test('saveSession saves user credentials and status', () async {
      final sessionService = SessionService();
      await sessionService.saveSession(username: 'rick_c137');

      expect(await sessionService.isLoggedIn(), isTrue);
      expect(await sessionService.getCurrentUser(), 'rick_c137');
    });

    test('clearSession resets login state and user info', () async {
      final sessionService = SessionService();
      await sessionService.saveSession(username: 'rick_c137');
      await sessionService.clearSession();

      expect(await sessionService.isLoggedIn(), isFalse);
      expect(await sessionService.getCurrentUser(), isNull);
    });
  });

  group('DatabaseHelper & AuthProvider Flow Tests', () {
    late Database db;
    late DatabaseHelper dbHelper;
    late SessionService sessionService;
    late AuthProvider authProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL
        )
      ''');

      dbHelper = DatabaseHelper.withDatabase(db);
      sessionService = SessionService();
      authProvider = AuthProvider(
        dbHelper: dbHelper,
        sessionService: sessionService,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('registerUser successfully stores user in db', () async {
      final user = UserModel(username: 'morty_smith', password: 'password123');
      final id = await dbHelper.registerUser(user);

      expect(id, isPositive);

      final fetched = await dbHelper.getUserByUsername('morty_smith');
      expect(fetched, isNotNull);
      expect(fetched!.username, 'morty_smith');
      expect(fetched.password, 'password123');
    });

    test('registerUser throws AuthDuplicateException when username exists', () async {
      final user = UserModel(username: 'summer_smith', password: 'password123');
      await dbHelper.registerUser(user);

      expect(
        () => dbHelper.registerUser(user),
        throwsA(isA<AuthDuplicateException>()),
      );
    });

    test('loginUser returns UserModel for valid credentials and null for invalid', () async {
      final user = UserModel(username: 'beth_smith', password: 'password123');
      await dbHelper.registerUser(user);

      final success = await dbHelper.loginUser('beth_smith', 'password123');
      expect(success, isNotNull);
      expect(success!.username, 'beth_smith');

      final wrongPass = await dbHelper.loginUser('beth_smith', 'wrong_pass');
      expect(wrongPass, isNull);

      final nonExistent = await dbHelper.loginUser('jerry_smith', 'password123');
      expect(nonExistent, isNull);
    });

    test('AuthProvider complete flow: register -> login -> checkSession -> logout', () async {
      // 1. Initial state
      expect(authProvider.isLoggedIn, isFalse);
      expect(authProvider.currentUser, isNull);

      // 2. Register
      final regSuccess = await authProvider.register('portal_gunner', 'dimension35c');
      expect(regSuccess, isTrue);
      expect(authProvider.errorMessage, isNull);

      // 3. Duplicate register should fail
      final regDup = await authProvider.register('portal_gunner', 'other');
      expect(regDup, isFalse);
      expect(authProvider.errorMessage, contains('sudah digunakan'));

      // 4. Invalid Login
      final loginFail = await authProvider.login('portal_gunner', 'wrong_pass');
      expect(loginFail, isFalse);
      expect(authProvider.isLoggedIn, isFalse);

      // 5. Valid Login
      final loginSuccess = await authProvider.login('portal_gunner', 'dimension35c');
      expect(loginSuccess, isTrue);
      expect(authProvider.isLoggedIn, isTrue);
      expect(authProvider.currentUser, 'portal_gunner');

      // 6. Check Session persistence
      final newAuthProvider = AuthProvider(
        dbHelper: dbHelper,
        sessionService: sessionService,
      );
      await newAuthProvider.checkSession();
      expect(newAuthProvider.isLoggedIn, isTrue);
      expect(newAuthProvider.currentUser, 'portal_gunner');

      // 7. Logout
      await newAuthProvider.logout();
      expect(newAuthProvider.isLoggedIn, isFalse);
      expect(newAuthProvider.currentUser, isNull);
    });
  });
}

