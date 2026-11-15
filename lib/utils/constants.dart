class AppConstants {
  // Base API configuration
  static const String apiBaseUrl = 'https://rickandmortyapi.com/api';
  static const String characterEndpoint = '/character';
  static const String episodeEndpoint = '/episode';

  // Local Storage & Shared Preferences Keys
  static const String prefIsLoggedIn = 'isLoggedIn';
  static const String prefCurrentUser = 'currentUser';
  static const String prefFavorites = 'favorite_characters';

  // Database Configuration
  static const String databaseName = 'rick_and_morty.db';
  static const int databaseVersion = 1;
  static const String userTable = 'users';
}

