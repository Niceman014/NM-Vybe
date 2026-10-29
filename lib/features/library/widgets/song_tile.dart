import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../models/song_model.dart';

/// Reusable row used by the library, search and playlist screens.
class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    this.onTap,
    this.subtitle,
    this.trailing,
    this.selected = false,
  });

  final Song song;
  final VoidCallback? onTap;
  final String? subtitle;
  final Widget? trailing;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleText = subtitle ?? song.displayArtist;
    return ListTile(
      selected: selected,
      selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: _SongArtwork(selected: selected),
      title: Text(
        song.displayTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          color: selected ? theme.colorScheme.primary : null,
        ),
      ),
      subtitle: Text(
        subtitleText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: trailing ??
          Text(
            formatDuration(song.duration),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      onTap: onTap,
    );
  }
}

class _SongArtwork extends StatelessWidget {
  const _SongArtwork({this.selected = false});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: selected
              ? [scheme.primary, scheme.tertiary]
              : [scheme.surfaceContainerHighest, scheme.surfaceContainer],
        ),
      ),
      child: Icon(
        Icons.music_note_rounded,
        color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
      ),
    );
  }
}
