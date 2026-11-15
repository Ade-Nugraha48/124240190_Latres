import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/character_model.dart';
import '../providers/favorites_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/character_card.dart';
import 'detail_screen.dart';

class FavoriteScreen extends StatelessWidget {
  final VoidCallback? onExploreTap;

  const FavoriteScreen({
    super.key,
    this.onExploreTap,
  });

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();
    final favorites = favoritesProvider.favorites;

    Widget body;
    if (favoritesProvider.isLoading) {
      body = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.portalGreen,
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Memuat karakter favorit...',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    } else if (favorites.isEmpty) {
      body = _buildEmptyState(context);
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info count
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tersimpan (${favorites.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Row(
                  children: [
                    Icon(
                      Icons.swipe_left_rounded,
                      size: 16,
                      color: AppTheme.textMuted,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Geser untuk menghapus',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List with Dismissible swipe to delete
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 4, bottom: 20),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final character = favorites[index];
                return Dismissible(
                  key: Key('favorite_character_${character.id}'),
                  direction: DismissDirection.endToStart,
                  background: _buildDismissBackground(),
                  onDismissed: (direction) =>
                      _handleDismiss(context, character, favoritesProvider),
                  child: CharacterCard(
                    character: character,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailScreen(
                            characterId: character.id,
                            initialCharacter: character,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return Scaffold(body: body);
  }

  Widget _buildDismissBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.deadRed,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Hapus dari Favorit',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.delete_forever_rounded, color: Colors.white, size: 28),
        ],
      ),
    );
  }

  void _handleDismiss(
    BuildContext context,
    CharacterModel character,
    FavoritesProvider provider,
  ) {
    provider.removeFavorite(character.id);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${character.name} dihapus dari favorit.'),
        backgroundColor: AppTheme.cardBackground,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'BATAL',
          textColor: AppTheme.portalGreen,
          onPressed: () {
            provider.addFavorite(character);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.cardBackground,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentYellow.withValues(alpha: 0.15),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 72,
                color: AppTheme.accentYellow,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum Ada Karakter Favorit',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Jelajahi daftar karakter di menu Home dan ketuk ikon bintang atau hati untuk menyimpannya di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textMuted,
                height: 1.4,
              ),
            ),
            if (onExploreTap != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.portalGreen,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(180, 44),
                ),
                icon: const Icon(Icons.travel_explore_rounded),
                label: const Text('Jelajahi Karakter'),
                onPressed: onExploreTap,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

