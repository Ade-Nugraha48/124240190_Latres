import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/character_model.dart';
import '../providers/favorites_provider.dart';
import '../utils/app_theme.dart';

class CharacterCard extends StatelessWidget {
  final CharacterModel character;
  final VoidCallback? onTap;

  const CharacterCard({
    super.key,
    required this.character,
    this.onTap,
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      color: AppTheme.cardBackground,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            // Character Avatar / Image
            SizedBox(
              width: 96,
              height: 96,
              child: Image.network(
                character.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppTheme.inputBackground,
                  child: const Icon(
                    Icons.broken_image_rounded,
                    color: AppTheme.textMuted,
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: AppTheme.inputBackground,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.portalGreen,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 14),

            // Character Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    character.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _getStatusColor(),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${character.status} - ${character.species}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (character.location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      character.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Favorite Icon Button
            IconButton(
              tooltip: isFav ? 'Hapus dari Favorit' : 'Tambah ke Favorit',
              icon: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? AppTheme.accentYellow : AppTheme.textMuted,
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
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}

