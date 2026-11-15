import 'package:flutter/foundation.dart';
import '../models/episode_model.dart';
import '../services/api_service.dart';

class EpisodeProvider with ChangeNotifier {
  final ApiService _apiService;

  List<EpisodeModel> _episodes = [];
  bool _isLoading = false;
  String? _errorMessage;

  EpisodeProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  List<EpisodeModel> get episodes => List.unmodifiable(_episodes);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => !_isLoading && _errorMessage == null && _episodes.isEmpty;

  Future<void> fetchEpisodes({int page = 1}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _episodes = await _apiService.getEpisodes(page: page);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _episodes = [];
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan atau server: $e';
      _episodes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void retry() {
    fetchEpisodes();
  }
}

