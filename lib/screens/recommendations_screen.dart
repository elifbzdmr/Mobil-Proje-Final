import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recommendation.dart';
import '../models/song.dart';
import '../providers/mood_provider.dart';
import '../widgets/song_card.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({
    super.key,
    required this.resetToken,
  });

  final int resetToken;

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final _analysisController = TextEditingController();
  String _selectedGenre = 'Karisik';

  @override
  void didUpdateWidget(covariant RecommendationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetToken != widget.resetToken) {
      _analysisController.clear();
      _selectedGenre = 'Karisik';
    }
  }

  @override
  void dispose() {
    _analysisController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MoodProvider>();
    final recommendations = provider.recommendations;
    final hasMood = provider.selectedMood != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Onerilen Sarkilar'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Playlist Olustur',
            onPressed: recommendations.isEmpty
                ? null
                : () => _createPlaylistFromResults(context, recommendations),
            icon: const Icon(Icons.playlist_add),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Hislerini Yaz', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    hasMood
                        ? 'Secili mood: ${provider.selectedMood}.'
                        : 'Once Home ekranindan bir mood sec.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGenre,
                    decoration: const InputDecoration(
                      labelText: 'Dinlemek istedigin tur',
                    ),
                    items: provider.genreOptions
                        .map(
                          (genre) => DropdownMenuItem<String>(
                            value: genre,
                            child: Text(genre),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedGenre = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _analysisController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Bugun nasil sarkilar duymak istiyorsun?',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: !hasMood || provider.isPreparingRecommendations
                          ? null
                          : () async {
                              await context
                                  .read<MoodProvider>()
                                  .prepareRecommendations(
                                    _analysisController.text,
                                    listeningGenre: _selectedGenre,
                                  );
                            },
                      icon: provider.isPreparingRecommendations
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.queue_music),
                      label: Text(
                        provider.isPreparingRecommendations
                            ? 'Oneriler Hazirlaniyor'
                            : 'Onerileri Getir',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (recommendations.isEmpty)
            const _EmptyRecommendation()
          else ...<Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Onerilen Sarkilar',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${recommendations.length} sarki bulundu. Tur: ${provider.listeningGenre}. Yenileyerek farkli oneriler alabilirsin.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: provider.isPreparingRecommendations
                                ? null
                                : () async {
                                    await context
                                        .read<MoodProvider>()
                                        .prepareRecommendations(
                                          _analysisController.text,
                                          listeningGenre: _selectedGenre,
                                        );
                                  },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Yenile'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _createPlaylistFromResults(
                              context,
                              recommendations,
                            ),
                            icon: const Icon(Icons.library_music),
                            label: const Text('Playlist Olustur'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...recommendations.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: <Widget>[
                    SongCard(
                      song: item.song,
                      moodLabel: item.song.moodKey.toUpperCase(),
                      genreLabel: item.song.genre,
                      reason: item.reason,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await context
                                  .read<MoodProvider>()
                                  .addSongToLibrary(item.song);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${item.song.title} kitapliga eklendi.',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.library_add),
                            label: const Text('Kitapliga Ekle'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () =>
                                _openPlaylistPicker(context, item.song),
                            icon: const Icon(Icons.playlist_add),
                            label: const Text('Playlist'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _createPlaylistFromResults(
    BuildContext context,
    List<Recommendation> recommendations,
  ) async {
    final provider = context.read<MoodProvider>();
    final songs = recommendations.take(6).map((rec) => rec.song).toList();
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Playlist Olustur'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Playlist adi',
              hintText: 'Ornek: Sakin Gece',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Iptal'),
            ),
            FilledButton(
              onPressed: () {
                final playlistName = controller.text.trim();
                FocusScope.of(dialogContext).unfocus();
                Navigator.pop(dialogContext, playlistName);
              },
              child: const Text('Olustur'),
            ),
          ],
        );
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
    if (name == null) return;
    if (!context.mounted) return;

    final result = await provider.createPlaylistWithSongs(name, songs);
    if (!context.mounted) return;
    if (result != PlaylistCreateResult.created) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == PlaylistCreateResult.emptyName
                ? 'Playlist adi bos olamaz.'
                : 'Bu isimde playlist var.',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name playlisti olusturuldu.')),
    );
  }

  Future<void> _openPlaylistPicker(BuildContext context, Song song) async {
    final provider = context.read<MoodProvider>();
    if (provider.playlists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Once Playlist ekranindan bir playlist olustur.'),
        ),
      );
      return;
    }

    final selectedPlaylist = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: provider.playlists.keys.map((name) {
              return ListTile(
                leading: const Icon(Icons.queue_music),
                title: Text(name),
                onTap: () => Navigator.pop(sheetContext, name),
              );
            }).toList(),
          ),
        );
      },
    );

    if (selectedPlaylist == null) return;
    await provider.addSongToPlaylist(selectedPlaylist, song);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${song.title} playliste eklendi.')),
    );
  }
}

class _EmptyRecommendation extends StatelessWidget {
  const _EmptyRecommendation();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.music_note_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Oneri almak icin hislerini yazip butona bas.'),
            ),
          ],
        ),
      ),
    );
  }
}
