import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audio_service/audio_service.dart';
import '../models/song_model.dart';
import '../../../../main.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  final List<SongModel> _songs = [];
  bool _isScanning = false;

  Future<void> _pickMusicFiles() async {
    setState(() => _isScanning = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result != null) {
        for (var file in result.files) {
          if (file.path != null) {
            String fileName = file.name;
            String title = fileName.contains('.')
                ? fileName.substring(0, fileName.lastIndexOf('.'))
                : fileName;
            
            if (!_songs.any((s) => s.filePath == file.path)) {
              setState(() {
                _songs.add(
                  SongModel(
                    id: file.path!,
                    title: title,
                    artist: "Unknown Artist",
                    filePath: file.path!,
                  ),
                );
              });
            }
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading music: $e")),
      );
    } finally {
      setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final audioHandler = ref.watch(audioHandlerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Music Library"),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: "Add Music Files",
            onPressed: _isScanning ? null : _pickMusicFiles,
          ),
        ],
      ),
      body: _songs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_music_outlined, size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  const Text("Your Library is Empty", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Click the folder icon above to add music files.", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isScanning ? null : _pickMusicFiles,
                    icon: const Icon(Icons.add),
                    label: const Text("Scan Local Music"),
                  ),
                ],
              ),
            )
          : StreamBuilder<MediaItem?>(
              stream: audioHandler.mediaItem,
              builder: (context, snapshot) {
                final currentPlayingId = snapshot.data?.id;

                return ListView.builder(
                  itemCount: _songs.length,
                  itemBuilder: (context, index) {
                    final song = _songs[index];
                    final isCurrentTrack = currentPlayingId == song.filePath;

                    return ListTile(
                      leading: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: isCurrentTrack
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isCurrentTrack ? Icons.graphic_eq : Icons.music_note,
                          color: isCurrentTrack ? theme.colorScheme.onPrimary : null,
                        ),
                      ),
                      title: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: isCurrentTrack ? FontWeight.bold : FontWeight.normal,
                          color: isCurrentTrack ? theme.colorScheme.primary : null,
                        ),
                      ),
                      subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: Icon(isCurrentTrack ? Icons.pause_circle_filled : Icons.play_circle_fill),
                        color: isCurrentTrack ? theme.colorScheme.primary : null,
                        onPressed: () async {
                          await (audioHandler as dynamic).playUri(
                            song.filePath,
                            song.title,
                            song.artist,
                          );
                        },
                      ),
                      onTap: () async {
                        await (audioHandler as dynamic).playUri(
                          song.filePath,
                          song.title,
                          song.artist,
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}