import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/services/settings_service.dart';
import '../../player/views/now_playing_page.dart';
import '../models/song_model.dart';
import '../widgets/song_tile.dart';

/// Songs tab: the heart of the library.
class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final songs = ref.watch(sortedSongsProvider);
    final isLoading = ref.watch(isLoadingLibraryProvider);
    final error = ref.watch(libraryErrorProvider);
    final settings = ref.watch(settingsControllerProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: Text('Your library', style: theme.textTheme.headlineSmall),
            actions: [
              PopupMenuButton<SongsSortMode>(
                tooltip: 'Sort songs',
                icon: const Icon(Icons.sort),
                initialValue: settings.songsSortMode,
                onSelected: (mode) => ref
                    .read(settingsControllerProvider.notifier)
                    .setSongsSortMode(mode),
                itemBuilder: (context) => [
                  for (final mode in SongsSortMode.values)
                    PopupMenuItem(value: mode, child: Text(mode.label)),
                ],
              ),
              IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.search),
                onPressed: () {
                  // Search lives in the app bar of the library; the full
                  // search experience is provided by the library feature.
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const _SearchOverlayPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          if (isLoading && songs.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _ErrorState(message: '$error'),
            )
          else if (songs.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: LibraryEmptyState(),
            )
          else
            SliverList.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return SongTile(
                  song: song,
                  onTap: () {
                    ref
                        .read(playerControllerProvider.notifier)
                        .playSongs(songs, initialIndex: index);
                    openNowPlaying(context);
                  },
                );
              },
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
        ],
      ),
    );
  }
}

class LibraryEmptyState extends StatelessWidget {
  const LibraryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.tertiaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(
              Icons.graphic_eq_rounded,
              size: 48,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 24),
          Text('Your vibe starts here', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Add the music you already own. NM VYBE reads your files, '
            'artwork and playlists — no account, no ads, no tracking.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Library scanning is being wired up next.'),
                ),
              );
            },
            icon: const Icon(Icons.folder_open),
            label: const Text('Scan my music'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text('Could not load the library', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SearchOverlayPage extends ConsumerWidget {
  const _SearchOverlayPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Songs, artists, albums…',
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: (value) =>
              ref.read(searchQueryProvider.notifier).state = value,
        ),
      ),
      body: query.trim().isEmpty
          ? const Center(child: Text('Type to search your library'))
          : results.isEmpty
              ? const Center(child: Text('Nothing found'))
              : ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final Song song = results[index];
                    return SongTile(
                      song: song,
                      subtitle: song.displayAlbum,
                      onTap: () {
                        ref
                            .read(playerControllerProvider.notifier)
                            .playSongs(results, initialIndex: index);
                        openNowPlaying(context);
                      },
                    );
                  },
                ),
    );
  }
}
