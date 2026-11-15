import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/character_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/character_card.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  final List<String> _statusOptions = ['All', 'Alive', 'Dead', 'unknown'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final characterProvider = context.read<CharacterProvider>();
      if (characterProvider.characters.isEmpty &&
          !characterProvider.isLoading &&
          characterProvider.errorMessage == null) {
        characterProvider.fetchCharacters();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        context.read<CharacterProvider>().setSearchQuery(query);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<CharacterProvider>().clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final characterProvider = context.watch<CharacterProvider>();

    return Scaffold(
      body: Column(
        children: [
          // Search Bar & Filter Section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: AppTheme.darkBackground,
            child: Column(
              children: [
                // Search Input Field
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Cari karakter (cth: Rick, Morty)...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.portalGreen),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted),
                            onPressed: _clearSearch,
                          )
                        : null,
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Status Filter Chips
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _statusOptions.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final status = _statusOptions[index];
                      final isSelected = characterProvider.selectedStatus.toLowerCase() ==
                          status.toLowerCase();

                      return ChoiceChip(
                        label: Text(
                          status == 'unknown' ? 'Unknown' : status,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.portalGreen,
                        backgroundColor: AppTheme.cardBackground,
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? AppTheme.portalGreen : Colors.transparent,
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            characterProvider.setStatus(status);
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Main Character List / States
          Expanded(
            child: _buildBody(characterProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(CharacterProvider provider) {
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
              'Memuat data karakter...',
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
                'Gagal Memuat Karakter',
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
                label: const Text('Coba Lagi', style: TextStyle(color: Colors.black)),
                onPressed: provider.retry,
              ),
            ],
          ),
        ),
      );
    }

    if (provider.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 64,
                color: AppTheme.textMuted,
              ),
              const SizedBox(height: 16),
              const Text(
                'Tidak Ada Karakter Ditemukan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Coba gunakan kata kunci pencarian atau filter status yang berbeda.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  _clearSearch();
                  provider.setStatus('All');
                },
                child: const Text(
                  'Reset Pencarian & Filter',
                  style: TextStyle(color: AppTheme.portalTeal),
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
      onRefresh: () => provider.fetchCharacters(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: provider.characters.length,
        itemBuilder: (context, index) {
          final character = provider.characters[index];
          return CharacterCard(
            character: character,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailScreen(character: character),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
