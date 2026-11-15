import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/episode_model.dart';
import '../providers/episode_provider.dart';
import '../utils/app_theme.dart';

class EpisodeScreen extends StatefulWidget {
  const EpisodeScreen({super.key});

  @override
  State<EpisodeScreen> createState() => _EpisodeScreenState();
}

class _EpisodeScreenState extends State<EpisodeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final episodeProvider = context.read<EpisodeProvider>();
      if (episodeProvider.episodes.isEmpty &&
          !episodeProvider.isLoading &&
          episodeProvider.errorMessage == null) {
        episodeProvider.fetchEpisodes();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final episodeProvider = context.watch<EpisodeProvider>();

    return Scaffold(
      body: _buildBody(episodeProvider),
    );
  }

  Widget _buildBody(EpisodeProvider provider) {
    if (provider.isLoading) {
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
              'Memuat daftar episode...',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (provider.errorMessage != null) {
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
                  border: Border.all(
                    color: AppTheme.deadRed.withValues(alpha: 0.5),
                  ),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: AppTheme.deadRed,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Gagal Memuat Episode',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.errorMessage!,
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
                label: const Text(
                  'Coba Lagi',
                  style: TextStyle(color: Colors.black),
                ),
                onPressed: provider.retry,
              ),
            ],
          ),
        ),
      );
    }

    if (provider.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.tv_off_rounded,
                size: 64,
                color: AppTheme.textMuted,
              ),
              SizedBox(height: 16),
              Text(
                'Tidak Ada Episode Ditemukan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.portalGreen,
      backgroundColor: AppTheme.cardBackground,
      onRefresh: () => provider.fetchEpisodes(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Episode (${provider.episodes.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.movie_filter_rounded, size: 14, color: AppTheme.portalTeal),
                      SizedBox(width: 4),
                      Text(
                        'Rick & Morty Series',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.portalTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 4, bottom: 20),
              itemCount: provider.episodes.length,
              itemBuilder: (context, index) {
                final episode = provider.episodes[index];
                return _buildEpisodeCard(episode);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeCard(EpisodeModel episode) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Episode Code Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.inputBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.portalTeal.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.tv_rounded,
                    color: AppTheme.portalTeal,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    episode.episode.isNotEmpty ? episode.episode : '#${episode.id}',
                    style: const TextStyle(
                      color: AppTheme.portalTeal,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Episode Name and Air Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    episode.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: AppTheme.portalGreen,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          episode.airDate,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

