import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/features/library/presentation/screens/album_detail_screen.dart';
import 'package:nexa_player/features/library/presentation/screens/artist_detail_screen.dart';
import 'package:nexa_player/features/player/player.dart';
import 'package:nexa_player/features/playlists/presentation/screens/playlist_detail_screen.dart';
import 'package:nexa_player/features/search/domain/models/search_result.dart';
import 'package:nexa_player/features/search/domain/models/search_result_category.dart';
import 'package:nexa_player/features/search/presentation/providers/search_providers.dart';
import 'package:nexa_player/features/search/presentation/widgets/recent_searches_section.dart';
import 'package:nexa_player/features/search/presentation/widgets/search_category_chips.dart';
import 'package:nexa_player/features/search/presentation/widgets/search_empty_state.dart';
import 'package:nexa_player/features/search/presentation/widgets/search_suggestions_grid.dart';
import 'package:nexa_player/features/search/presentation/widgets/voice_search_modal.dart';
import 'package:nexa_player/shared/models/album.dart';
import 'package:nexa_player/shared/models/artist.dart';
import 'package:nexa_player/shared/models/genre.dart';
import 'package:nexa_player/shared/models/playlist.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/widgets/cards/album_card.dart';
import 'package:nexa_player/shared/widgets/cards/artist_card.dart';
import 'package:nexa_player/shared/widgets/cards/genre_card.dart';
import 'package:nexa_player/shared/widgets/cards/track_tile.dart';
import 'package:nexa_player/shared/widgets/glass/app_ambient_background.dart';
import 'package:nexa_player/shared/widgets/glass/glass_app_bar.dart';
import 'package:nexa_player/shared/widgets/glass/glass_card.dart';

/// Full-screen instant search interface across songs, albums, artists, genres, and playlists.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final text = _searchController.text;
    if (ref.read(searchQueryProvider) != text) {
      ref.read(searchQueryProvider.notifier).state = text;
    }
  }

  void _setSearchQuery(String query) {
    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    ref.read(searchQueryProvider.notifier).state = query;
  }

  void _onTrackTapped(Track track) {
    HapticFeedback.lightImpact();
    if (_searchController.text.trim().isNotEmpty) {
      ref.read(recentSearchesProvider.notifier).save(_searchController.text.trim());
    }
    ref.read(playerNotifierProvider.notifier).playTrack(track);
  }

  void _onAlbumTapped(Album album) {
    HapticFeedback.lightImpact();
    if (_searchController.text.trim().isNotEmpty) {
      ref.read(recentSearchesProvider.notifier).save(_searchController.text.trim());
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AlbumDetailScreen(album: album),
      ),
    );
  }

  void _onArtistTapped(Artist artist) {
    HapticFeedback.lightImpact();
    if (_searchController.text.trim().isNotEmpty) {
      ref.read(recentSearchesProvider.notifier).save(_searchController.text.trim());
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ArtistDetailScreen(artist: artist),
      ),
    );
  }

  void _onPlaylistTapped(Playlist playlist) {
    HapticFeedback.lightImpact();
    if (_searchController.text.trim().isNotEmpty) {
      ref.read(recentSearchesProvider.notifier).save(_searchController.text.trim());
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlaylistDetailScreen(playlist: playlist),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final query = ref.watch(searchQueryProvider);
    final category = ref.watch(searchCategoryProvider);
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final playerState = ref.watch(playerNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        automaticallyImplyLeading: true,
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(Icons.search_rounded, size: 20, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Search songs, albums, artists...',
                    hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white70),
                  tooltip: 'Clear query',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _searchController.clear();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              IconButton(
                icon: const Icon(Icons.mic_rounded, size: 20, color: Colors.white70),
                tooltip: 'Voice Search',
                onPressed: () {
                  VoiceSearchModal.show(
                    context,
                    onQueryRecognized: _setSearchQuery,
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: SearchCategoryChips(),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AppAmbientBackground(),
          Container(color: Colors.black.withOpacity(0.6)),

          SafeArea(
            child: query.trim().isEmpty
                ? _buildEmptyQueryContent()
                : searchResultsAsync.when(
                    data: (result) {
                      if (result.isEmpty) {
                        return SearchEmptyState(
                          query: query,
                          onClear: () {
                            _searchController.clear();
                          },
                        );
                      }
                      return _buildResultsView(result, category, playerState.currentTrack?.id);
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'Error loading search results: $error',
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyQueryContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RecentSearchesSection(onSelectQuery: _setSearchQuery),
          SearchSuggestionsGrid(onSelectSuggestion: _setSearchQuery),
        ],
      ),
    );
  }

  Widget _buildResultsView(SearchResult result, SearchResultCategory category, String? currentPlayingTrackId) {
    return switch (category) {
      SearchResultCategory.all => _buildAllResultsView(result, currentPlayingTrackId),
      SearchResultCategory.tracks => _buildTracksList(result.tracks, currentPlayingTrackId),
      SearchResultCategory.albums => _buildAlbumsGrid(result.albums),
      SearchResultCategory.artists => _buildArtistsList(result.artists),
      SearchResultCategory.playlists => _buildPlaylistsList(result.playlists),
      SearchResultCategory.genres => _buildGenresGrid(result.genres),
    };
  }

  Widget _buildAllResultsView(SearchResult result, String? currentPlayingTrackId) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // 1. Songs Section
        if (result.tracks.isNotEmpty) ...[
          _buildSectionHeader(
            title: 'Songs',
            count: result.tracks.length,
            onSeeAll: () {
              ref.read(searchCategoryProvider.notifier).state = SearchResultCategory.tracks;
            },
          ),
          ...result.tracks.take(5).map((track) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TrackTile.fromTrack(
                track: track,
                isPlaying: track.id == currentPlayingTrackId,
                onTap: () => _onTrackTapped(track),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // 2. Albums Section
        if (result.albums.isNotEmpty) ...[
          _buildSectionHeader(
            title: 'Albums',
            count: result.albums.length,
            onSeeAll: () {
              ref.read(searchCategoryProvider.notifier).state = SearchResultCategory.albums;
            },
          ),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: result.albums.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final album = result.albums[index];
                return SizedBox(
                  width: 140,
                  child: AlbumCard.fromAlbum(
                    album: album,
                    onTap: () => _onAlbumTapped(album),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],

        // 3. Artists Section
        if (result.artists.isNotEmpty) ...[
          _buildSectionHeader(
            title: 'Artists',
            count: result.artists.length,
            onSeeAll: () {
              ref.read(searchCategoryProvider.notifier).state = SearchResultCategory.artists;
            },
          ),
          ...result.artists.take(4).map((artist) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ArtistCard.fromArtist(
                artist: artist,
                onTap: () => _onArtistTapped(artist),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // 4. Playlists Section
        if (result.playlists.isNotEmpty) ...[
          _buildSectionHeader(
            title: 'Playlists',
            count: result.playlists.length,
            onSeeAll: () {
              ref.read(searchCategoryProvider.notifier).state = SearchResultCategory.playlists;
            },
          ),
          ...result.playlists.take(4).map((playlist) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildPlaylistTile(playlist),
            );
          }),
          const SizedBox(height: 16),
        ],

        // 5. Genres Section
        if (result.genres.isNotEmpty) ...[
          _buildSectionHeader(
            title: 'Genres',
            count: result.genres.length,
            onSeeAll: () {
              ref.read(searchCategoryProvider.notifier).state = SearchResultCategory.genres;
            },
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: result.genres.map((genre) {
              return SizedBox(
                width: 160,
                height: 80,
                child: GenreCard.fromGenre(
                  genre: genre,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _setSearchQuery(genre.name);
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
    VoidCallback? onSeeAll,
  }) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (onSeeAll != null && count > 4)
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                onSeeAll();
              },
              style: TextButton.styleFrom(
                foregroundColor: accent,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('See All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildTracksList(List<Track> tracks, String? currentPlayingTrackId) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: TrackTile.fromTrack(
            track: track,
            isPlaying: track.id == currentPlayingTrackId,
            onTap: () => _onTrackTapped(track),
          ),
        );
      },
    );
  }

  Widget _buildAlbumsGrid(List<Album> albums) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 600
                ? 3
                : 2;

        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.72,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            return AlbumCard.fromAlbum(
              album: album,
              onTap: () => _onAlbumTapped(album),
            );
          },
        );
      },
    );
  }

  Widget _buildArtistsList(List<Artist> artists) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: ArtistCard.fromArtist(
            artist: artist,
            onTap: () => _onArtistTapped(artist),
          ),
        );
      },
    );
  }

  Widget _buildPlaylistsList(List<Playlist> playlists) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: _buildPlaylistTile(playlist),
        );
      },
    );
  }

  Widget _buildGenresGrid(List<Genre> genres) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 600
                ? 3
                : 2;

        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 2.2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemCount: genres.length,
          itemBuilder: (context, index) {
            final genre = genres[index];
            return GenreCard.fromGenre(
              genre: genre,
              onTap: () {
                HapticFeedback.lightImpact();
                _setSearchQuery(genre.name);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPlaylistTile(Playlist playlist) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: () => _onPlaylistTapped(playlist),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [accent.withOpacity(0.4), const Color(0xFF19202E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: accent.withOpacity(0.3)),
            ),
            child: Icon(
              playlist.isSmart ? Icons.auto_awesome_rounded : Icons.playlist_play_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist.name,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  playlist.trackCountLabel,
                  style: AppTypography.bodySmall.copyWith(color: Colors.white60),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 20),
        ],
      ),
    );
  }
}
