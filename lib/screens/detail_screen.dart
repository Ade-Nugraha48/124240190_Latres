import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/character_model.dart';
import '../providers/favorites_provider.dart';
import '../utils/app_theme.dart';

class DetailScreen extends StatelessWidget {
  final CharacterModel character;

  const DetailScreen({
    super.key,
    required this.character,
  });

  Color _getStatusColor() {
    if (character.isAlive) {
      return AppTheme.portalGreen;
    } else if (character.isDead) {
      return AppTheme.deadRed;
    } else {
      return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();
    final isFav = favoritesProvider.isFavorite(character.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(character.name),
        actions: [
          IconButton(
            tooltip: isFav ? 'Hapus dari Favorit' : 'Tambah ke Favorit',
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? AppTheme.accentYellow : Colors.white,
            ),
            onPressed: () async {
              final added = await context
                  .read<FavoritesProvider>()
                  .toggleFavorite(character);
              if (!context.mounted) return;

              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    added
                        ? '${character.name} ditambahkan ke favorit!'
                        : '${character.name} dihapus dari favorit.',
                  ),
                  backgroundColor:
                      added ? AppTheme.portalGreen : AppTheme.cardBackground,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero / Image
            AspectRatio(
              aspectRatio: 1,
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
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          character.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withValues(alpha: 0.15),
                          border: Border.all(color: _getStatusColor()),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getStatusColor(),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              character.status,
                              style: TextStyle(
                                color: _getStatusColor(),
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

                  // Detail Info Cards
                  _buildDetailTile(
                    icon: Icons.fingerprint_rounded,
                    label: 'Species',
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
                    label: 'Origin',
                    value: character.origin.isEmpty ? 'Unknown' : character.origin,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailTile(
                    icon: Icons.location_on_rounded,
                    label: 'Last Known Location',
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
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.inputBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.portalTeal, size: 22),
          ),
          const SizedBox(width: 14),
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
