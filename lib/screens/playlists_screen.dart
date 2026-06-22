import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/mood_provider.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MoodProvider>();
    final playlists = provider.playlistSongs;

    return Scaffold(
      appBar: AppBar(title: const Text('Kitaplik & Playlist')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Yeni Playlist',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ornek: Gece Yolculugu',
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: () async {
                      final result = await context
                          .read<MoodProvider>()
                          .createPlaylist(_controller.text);
                      if (!context.mounted) return;
                      switch (result) {
                        case PlaylistCreateResult.created:
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Playlist olusturuldu.')),
                          );
                          _controller.clear();
                        case PlaylistCreateResult.emptyName:
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Playlist adi bos olamaz.')),
                          );
                        case PlaylistCreateResult.duplicateName:
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Bu isimde playlist var.')),
                          );
                      }
                    },
                    child: const Text('Playlist Olustur'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.library_music),
              title: const Text('Kitapligim'),
              subtitle: Text('${provider.librarySongs.length} sarki'),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              children: provider.librarySongs.isEmpty
                  ? const <Widget>[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Henuz kaydedilen sarki yok.'),
                      ),
                    ]
                  : provider.librarySongs
                      .map(
                        (song) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.music_note),
                          title: Text(song.title),
                          subtitle: Text(song.artist),
                          trailing: IconButton(
                            tooltip: 'Kitapliktan cikar',
                            onPressed: () async {
                              await context
                                  .read<MoodProvider>()
                                  .removeSongFromLibrary(song.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${song.title} kitapliktan cikarildi.',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          const SizedBox(height: 12),
          if (playlists.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Henuz playlist yok.'),
              ),
            ),
          ...playlists.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ExpansionTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  leading: const Icon(Icons.queue_music),
                  title: Text(entry.key),
                  subtitle: Text(
                    '${entry.value.length} sarki - yapan: ${provider.playlistOwners[entry.key] ?? 'Bilinmiyor'}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _openRenameDialog(context, entry.key);
                      } else if (value == 'delete') {
                        _confirmDeletePlaylist(context, entry.key);
                      }
                    },
                    itemBuilder: (context) => const <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Duzenle'),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Sil'),
                      ),
                    ],
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: entry.value.isEmpty
                      ? const <Widget>[
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Bu playlist bos.'),
                          ),
                        ]
                      : entry.value
                          .map(
                            (song) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.music_note),
                              title: Text(song.title),
                              subtitle: Text(song.artist),
                              trailing: IconButton(
                                tooltip: 'Playlistten cikar',
                                onPressed: () async {
                                  await context
                                      .read<MoodProvider>()
                                      .removeSongFromPlaylist(
                                        playlistName: entry.key,
                                        songId: song.id,
                                      );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${song.title} playlistten cikarildi.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRenameDialog(
    BuildContext context,
    String playlistName,
  ) async {
    final controller = TextEditingController(text: playlistName);
    final nextName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Playlisti Duzenle'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Playlist adi'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Iptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                controller.text.trim(),
              ),
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (nextName == null || !context.mounted) return;

    final result = await context.read<MoodProvider>().renamePlaylist(
          oldName: playlistName,
          newName: nextName,
        );
    if (!context.mounted) return;
    switch (result) {
      case PlaylistCreateResult.created:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Playlist guncellendi.')),
        );
      case PlaylistCreateResult.emptyName:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Playlist adi bos olamaz.')),
        );
      case PlaylistCreateResult.duplicateName:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu isimde playlist var.')),
        );
    }
  }

  Future<void> _confirmDeletePlaylist(
    BuildContext context,
    String playlistName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Playlisti Sil'),
          content: Text('$playlistName silinsin mi?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Vazgec'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
      await context.read<MoodProvider>().deletePlaylist(playlistName);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Playlist silindi.')),
        );
      }
    }
  }
}
