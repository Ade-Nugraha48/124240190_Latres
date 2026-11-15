import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character_model.dart';
import '../utils/constants.dart';

class FavoritesProvider with ChangeNotifier {
  SharedPreferences? preferences;
  List<CharacterModel> _favorites = [];
  bool _isLoading = false;

  FavoritesProvider({this.preferences});

  List<CharacterModel> get favorites => List.unmodifiable(_favorites);
  bool get isLoading => _isLoading;

  bool isFavorite(int characterId) {
    return _favorites.any((character) => character.id == characterId);
  }

  Future<SharedPreferences> _getPrefs() async {
    preferences ??= await SharedPreferences.getInstance();
    return preferences!;
  }

  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await _getPrefs();
      final jsonString = prefs.getString(AppConstants.prefFavorites);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = json.decode(jsonString);
        _favorites = decoded
            .map((item) => CharacterModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _favorites = [];
      }
    } catch (_) {
      _favorites = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleFavorite(CharacterModel character) async {
    final exists = isFavorite(character.id);
    if (exists) {
      _favorites.removeWhere((c) => c.id == character.id);
    } else {
      _favorites.add(character);
    }
    await _saveToStorage();
    notifyListeners();
    return !exists; // true if added, false if removed
  }

  Future<void> removeFavorite(int characterId) async {
    _favorites.removeWhere((c) => c.id == characterId);
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await _getPrefs();
      final jsonList = _favorites.map((c) => c.toJson()).toList();
      await prefs.setString(AppConstants.prefFavorites, json.encode(jsonList));
    } catch (_) {}
  }
}

