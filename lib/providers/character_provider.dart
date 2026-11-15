import 'package:flutter/foundation.dart';
import '../models/character_model.dart';
import '../services/api_service.dart';

class CharacterProvider with ChangeNotifier {
  final ApiService _apiService;

  List<CharacterModel> _characters = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedStatus = 'All';
  String _searchQuery = '';

  CharacterProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  List<CharacterModel> get characters => List.unmodifiable(_characters);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;
  bool get isEmpty => !_isLoading && _errorMessage == null && _characters.isEmpty;

  Future<void> fetchCharacters() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final statusParam = _selectedStatus.toLowerCase() == 'all'
          ? null
          : _selectedStatus.toLowerCase();
      final nameParam = _searchQuery.trim().isEmpty ? null : _searchQuery.trim();

      _characters = await _apiService.getCharacters(
        status: statusParam,
        name: nameParam,
      );
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _characters = [];
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan atau server: $e';
      _characters = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setStatus(String status) {
    if (_selectedStatus.toLowerCase() == status.toLowerCase()) return;
    _selectedStatus = status;
    fetchCharacters();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query.trim()) return;
    _searchQuery = query.trim();
    fetchCharacters();
  }

  void clearSearch() {
    if (_searchQuery.isEmpty) return;
    _searchQuery = '';
    fetchCharacters();
  }

  void retry() {
    fetchCharacters();
  }
}
