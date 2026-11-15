import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/character_model.dart';
import '../providers/favorites_provider.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

class DetailScreen extends StatefulWidget {
  final int characterId;
  final CharacterModel? initialCharacter;
  final ApiService? apiService;

  DetailScreen({
    super.key,
    int? characterId,
    CharacterModel? character,
    CharacterModel? initialCharacter,
    this.apiService,
  })  : characterId = characterId ?? character?.id ?? initialCharacter?.id ?? 0,
        initialCharacter = initialCharacter ?? character;

  DetailScreen.fromCharacter({
    super.key,
    required CharacterModel character,
    this.apiService,
  })  : characterId = character.id,
        initialCharacter = character;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final ApiService _apiService;
  CharacterModel? _character;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _character = widget.initialCharacter;
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    // Only show full loading if we have no initial character data
    if (_character == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final detail = await _apiService.getCharacterDetail(widget.characterId);
      if (!mounted) return;
      setState(() {
        _character = detail;
        _isLoading = false;
        _errorMessage = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (_character == null) {
          _errorMessage = e.message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (_character == null) {
          _errorMessage = 'Gagal memuat detail karakter: $e';
        }
      });
    }
  }

  Color _getStatusColor(String status) {
    final lower = status.toLowerCase();
    if (lower == 'alive') {
      return AppTheme.portalGreen;
    } else if (lower == 'dead') {
      return AppTheme.deadRed;
    } else {
      return AppTheme.textMuted;
    }
  }

  Future<void> _toggleFavorite(CharacterModel character) async {
    final favoritesProvider = context.read<FavoritesProvider>();
    final added = await favoritesProvider.toggleFavorite(character);

    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added
              ? '${character.name} ditambahkan ke favorit!'
              : '${character.name} dihapus dari favorit.',
        ),
        backgroundColor: added ? AppTheme.portalGreen : AppTheme.cardBackground,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();
    final isFav = _character != null && favoritesProvider.isFavorite(_character!.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(_character?.name ?? 'Detail Karakter'),
        actions: [
          if (_character != null)
            IconButton(
              tooltip: isFav ? 'Hapus dari Favorit' : 'Tambah ke Favorit',
              icon: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? AppTheme.accentYellow : Colors.white,
              ),
              onPressed: () => _toggleFavorite(_character!),
            ),
        ],
      ),
      floatingActionButton: _character != null
          ? FloatingActionButton.extended(
              backgroundColor: isFav ? AppTheme.cardBackground : AppTheme.portalGreen,
              foregroundColor: isFav ? AppTheme.accentYellow : Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isFav ? AppTheme.accentYellow : Colors.transparent,
                  width: 1.5,
                ),
              ),
              icon: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              ),
              label: Text(
                isFav ? 'Tersimpan di Favorit' : 'Simpan ke Favorit',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => _toggleFavorite(_character!),
            )
          : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _character == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.portalGreen,
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Memuat detail karakter...',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null && _character == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.deadRed.withValues(alpha: 0.5)),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: AppTheme.deadRed,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Gagal Memuat Detail',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(140, 44),
                  backgroundColor: AppTheme.portalGreen,
                ),
                icon: const Icon(Icons.refresh_rounded, color: Colors.black),
                label: const Text('Coba Lagi', style: TextStyle(color: Colors.black)),
                onPressed: _fetchDetail,
              ),
            ],
          ),
        ),
      );
    }

    final character = _character!;
    final statusColor = _getStatusColor(character.status);

    return RefreshIndicator(
      color: AppTheme.portalGreen,
      backgroundColor: AppTheme.cardBackground,
      onRefresh: _fetchDetail,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 88),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Character Image with subtle gradient
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.1,
                  child: Image.network(
                    character.image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppTheme.cardBackground,
                      child: const Icon(
                        Icons.broken_image_rounded,
                        size: 80,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: AppTheme.cardBackground,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.portalGreen,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppTheme.darkBackground,
                          AppTheme.darkBackground.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Status Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          character.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          border: Border.all(color: statusColor, width: 1.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              character.status,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Informasi Karakter',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.portalTeal,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Detail Tiles
                  _buildDetailTile(
                    icon: Icons.fingerprint_rounded,
                    label: 'Spesies',
                    value: character.species.isEmpty ? '-' : character.species,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailTile(
                    icon: Icons.transgender_rounded,
                    label: 'Gender',
                    value: character.gender.isEmpty ? '-' : character.gender,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailTile(
                    icon: Icons.public_rounded,
                    label: 'Origin (Asal)',
                    value: character.origin.isEmpty ? 'Unknown' : character.origin,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailTile(
                    icon: Icons.location_on_rounded,
                    label: 'Lokasi Terakhir',
                    value: character.location.isEmpty ? 'Unknown' : character.location,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.portalTeal.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.inputBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.portalTeal, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
