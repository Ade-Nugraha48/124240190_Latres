import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latihan_responsi/providers/auth_provider.dart';
import 'package:latihan_responsi/providers/character_provider.dart';
import 'package:latihan_responsi/providers/favorites_provider.dart';
import 'package:latihan_responsi/screens/login_screen.dart';
import 'package:latihan_responsi/screens/main_navigation_screen.dart';
import 'package:latihan_responsi/screens/register_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestWidget(
  Widget child, {
  AuthProvider? authProvider,
  CharacterProvider? characterProvider,
  FavoritesProvider? favoritesProvider,
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
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LoginScreen Widget Tests', () {
    testWidgets('renders input fields, buttons, and titles', (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginScreen()));

      expect(find.text('Rick & Morty Explorer'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Masuk'), findsOneWidget);
      expect(find.text('Daftar Sekarang'), findsOneWidget);
    });

    testWidgets('shows validation errors when submitting empty form', (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginScreen()));

      final masukButton = find.text('Masuk');
      await tester.tap(masukButton);
      await tester.pumpAndSettle();

      expect(find.text('Username wajib diisi'), findsOneWidget);
      expect(find.text('Password wajib diisi'), findsOneWidget);
    });
  });

  group('RegisterScreen Widget Tests', () {
    testWidgets('renders all input fields and register button', (tester) async {
      await tester.pumpWidget(createTestWidget(const RegisterScreen()));

      expect(find.text('Buat Akun Baru'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3)); // username, password, confirm password
      expect(find.text('Daftar'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
    });

    testWidgets('validates empty inputs and password mismatch', (tester) async {
      await tester.pumpWidget(createTestWidget(const RegisterScreen()));

      // 1. Submit empty form
      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();

      expect(find.text('Username wajib diisi'), findsOneWidget);
      expect(find.text('Password wajib diisi'), findsOneWidget);
      expect(find.text('Konfirmasi password wajib diisi'), findsOneWidget);

      // 2. Test mismatched passwords
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'portal_rick');
      await tester.enterText(textFields.at(1), 'password123');
      await tester.enterText(textFields.at(2), 'mismatch_pass');

      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi password tidak cocok'), findsOneWidget);
    });
  });

  group('MainNavigationScreen Widget Tests', () {
    testWidgets('renders navigation bar tabs and logout button', (tester) async {
      await tester.pumpWidget(createTestWidget(const MainNavigationScreen()));

      expect(find.text('Rick & Morty Characters'), findsOneWidget);
      expect(find.text('Characters'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Episodes'), findsOneWidget);
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);

      // Test tab switching
      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();
      expect(find.text('Favorite Characters'), findsOneWidget);

      await tester.tap(find.text('Episodes').first);
      await tester.pumpAndSettle();
      expect(find.text('Daftar seluruh episode serial Rick and Morty.'), findsOneWidget);
    });
  });
}
