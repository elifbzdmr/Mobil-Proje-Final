import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/community_post.dart';
import '../providers/mood_provider.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _moodPostController = TextEditingController();
  final _songTitleController = TextEditingController();
  final _artistController = TextEditingController();
  final _songNoteController = TextEditingController();
  final _playlistNoteController = TextEditingController();
  String _songGenre = 'Pop';
  String? _selectedPlaylist;

  @override
  void dispose() {
    _moodPostController.dispose();
    _songTitleController.dispose();
    _artistController.dispose();
    _songNoteController.dispose();
    _playlistNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MoodProvider>();
    final posts = provider.communityPosts;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Topluluk'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(icon: Icon(Icons.edit_note), text: 'Mood Yaz'),
              Tab(icon: Icon(Icons.music_note), text: 'Sarki Ekle'),
              Tab(icon: Icon(Icons.queue_music), text: 'Playlist'),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            SizedBox(
              height: 340,
              child: TabBarView(
                children: <Widget>[
                  _MoodPostComposer(
                    controller: _moodPostController,
                    onShare: () async {
                      await context
                          .read<MoodProvider>()
                          .addCommunityMoodPost(_moodPostController.text);
                      _moodPostController.clear();
                    },
                  ),
                  _SongPostComposer(
                    titleController: _songTitleController,
                    artistController: _artistController,
                    noteController: _songNoteController,
                    genre: _songGenre,
                    genreOptions: provider.genreOptions
                        .where((genre) => genre != 'Karisik')
                        .toList(),
                    onGenreChanged: (value) =>
                        setState(() => _songGenre = value),
                    onShare: () async {
                      await context.read<MoodProvider>().addCommunitySongPost(
                            title: _songTitleController.text,
                            artist: _artistController.text,
                            genre: _songGenre,
                            note: _songNoteController.text,
                          );
                      _songTitleController.clear();
                      _artistController.clear();
                      _songNoteController.clear();
                    },
                  ),
                  _PlaylistPostComposer(
                    selectedPlaylist: _selectedPlaylist,
                    playlistNames: provider.playlists.keys.toList(),
                    noteController: _playlistNoteController,
                    onPlaylistChanged: (value) {
                      setState(() => _selectedPlaylist = value);
                    },
                    onShare: () async {
                      final playlist = _selectedPlaylist;
                      if (playlist == null) return;
                      await context
                          .read<MoodProvider>()
                          .addCommunityPlaylistPost(
                            playlistName: playlist,
                            note: _playlistNoteController.text,
                          );
                      _playlistNoteController.clear();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Akis', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (posts.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Henuz topluluk paylasimi yok.'),
                ),
              )
            else
              ...posts.map(
                (post) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CommunityPostCard(post: post),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MoodPostComposer extends StatelessWidget {
  const _MoodPostComposer({
    required this.controller,
    required this.onShare,
  });

  final TextEditingController controller;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Moodunu Paylas',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Bugun moodun nasil?',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.send),
                label: const Text('Paylas'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SongPostComposer extends StatelessWidget {
  const _SongPostComposer({
    required this.titleController,
    required this.artistController,
    required this.noteController,
    required this.genre,
    required this.genreOptions,
    required this.onGenreChanged,
    required this.onShare,
  });

  final TextEditingController titleController;
  final TextEditingController artistController;
  final TextEditingController noteController;
  final String genre;
  final List<String> genreOptions;
  final ValueChanged<String> onGenreChanged;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: <Widget>[
            Text('Dinledigin Sarkiyi Ekle',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Sarki adi'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: artistController,
              decoration: const InputDecoration(labelText: 'Sanatci'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: genre,
              decoration: const InputDecoration(labelText: 'Tur'),
              items: genreOptions
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) onGenreChanged(value);
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Kisa not'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.add),
              label: const Text('Sarkiyi Paylas'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistPostComposer extends StatelessWidget {
  const _PlaylistPostComposer({
    required this.selectedPlaylist,
    required this.playlistNames,
    required this.noteController,
    required this.onPlaylistChanged,
    required this.onShare,
  });

  final String? selectedPlaylist;
  final List<String> playlistNames;
  final TextEditingController noteController;
  final ValueChanged<String?> onPlaylistChanged;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: playlistNames.isEmpty
            ? const Center(
                child: Text('Paylasmak icin once bir playlist olustur.'),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Playlist Paylas',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPlaylist,
                    decoration: const InputDecoration(labelText: 'Playlist'),
                    items: playlistNames
                        .map(
                          (name) => DropdownMenuItem<String>(
                            value: name,
                            child: Text(name),
                          ),
                        )
                        .toList(),
                    onChanged: onPlaylistChanged,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Playlist hakkinda not',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: selectedPlaylist == null ? null : onShare,
                      icon: const Icon(Icons.send),
                      label: const Text('Playlisti Paylas'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CommunityPostCard extends StatefulWidget {
  const _CommunityPostCard({required this.post});

  final CommunityPost post;

  @override
  State<_CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends State<_CommunityPostCard> {
  final _replyController = TextEditingController();
  bool _showReply = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MoodProvider>();
    final post = widget.post;
    final currentEmail = provider.userProfile?.email ?? '';
    final isOwn = post.authorEmail == currentEmail;
    final isLiked = post.likedBy.contains(currentEmail);
    final isSong = post.type == CommunityPostType.song;
    final isPlaylist = post.type == CommunityPostType.playlist;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(
                  child: Icon(
                    isPlaylist
                        ? Icons.queue_music
                        : isSong
                            ? Icons.music_note
                            : Icons.person,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              post.authorName,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            _formatDateTime(post.createdAt),
                            textAlign: TextAlign.end,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (isSong)
                        Text(
                          '${post.songTitle ?? 'Sarki'} - ${post.artist ?? '-'}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (isSong)
                        Text(
                          post.genre ?? '-',
                          style: theme.textTheme.bodySmall,
                        ),
                      if (isPlaylist)
                        Text(
                          post.playlistName ?? 'Playlist',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (isPlaylist)
                        Text(
                          '${post.playlistSongs.length} sarki - yapan: ${post.authorName}',
                          style: theme.textTheme.bodySmall,
                        ),
                      if (isSong || isPlaylist) const SizedBox(height: 6),
                      Text(post.text),
                    ],
                  ),
                ),
                if (isOwn)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _openEditDialog(context, post);
                      } else if (value == 'delete') {
                        _confirmDelete(context, post.id);
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
              ],
            ),
            const SizedBox(height: 12),
            if (isSong || isPlaylist) ...<Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  if (isSong) ...<Widget>[
                    OutlinedButton.icon(
                      onPressed: () async {
                        await context
                            .read<MoodProvider>()
                            .saveCommunitySongToLibrary(post);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sarki kitapliga eklendi.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.library_add),
                      label: const Text('Kitapliga Ekle'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openPlaylistPicker(context, post),
                      icon: const Icon(Icons.playlist_add),
                      label: const Text('Playliste Ekle'),
                    ),
                  ],
                  if (isPlaylist)
                    FilledButton.icon(
                      onPressed: () async {
                        await context
                            .read<MoodProvider>()
                            .saveSharedPlaylist(post);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Playlist kitapliga kaydedildi.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.download_done),
                      label: const Text('Playlisti Kaydet'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: <Widget>[
                TextButton.icon(
                  onPressed: () {
                    setState(() => _showReply = !_showReply);
                  },
                  icon: const Icon(Icons.mode_comment_outlined),
                  label: Text('${post.replies.length} Yanit'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    context.read<MoodProvider>().toggleCommunityLike(post.id);
                  },
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                  ),
                  label: Text('${post.likedBy.length} Begeni'),
                ),
              ],
            ),
            if (_showReply) ...<Widget>[
              const SizedBox(height: 8),
              TextField(
                controller: _replyController,
                decoration: InputDecoration(
                  labelText: '${post.authorName} gonderisine yanit yaz',
                  suffixIcon: IconButton(
                    tooltip: 'Yanitla',
                    onPressed: () async {
                      await context.read<MoodProvider>().addCommunityReply(
                            postId: post.id,
                            text: _replyController.text,
                          );
                      _replyController.clear();
                    },
                    icon: const Icon(Icons.send),
                  ),
                ),
              ),
            ],
            if (post.replies.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              ...post.replies.map(
                (reply) => Padding(
                  padding: const EdgeInsets.only(top: 8, left: 44),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      dense: true,
                      title: Text(reply.authorName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(reply.text),
                          const SizedBox(height: 2),
                          Text(
                            _formatDateTime(reply.createdAt),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      trailing: reply.authorEmail == currentEmail
                          ? PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _openReplyEditDialog(
                                    context: context,
                                    postId: post.id,
                                    reply: reply,
                                  );
                                } else if (value == 'delete') {
                                  _confirmReplyDelete(
                                    context: context,
                                    postId: post.id,
                                    replyId: reply.id,
                                  );
                                }
                              },
                              itemBuilder: (context) =>
                                  const <PopupMenuEntry<String>>[
                                PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Text('Duzenle'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Text('Sil'),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openEditDialog(BuildContext context, CommunityPost post) async {
    final textController = TextEditingController(text: post.text);
    final titleController = TextEditingController(text: post.songTitle ?? '');
    final artistController = TextEditingController(text: post.artist ?? '');
    final playlistController =
        TextEditingController(text: post.playlistName ?? '');
    var genre = post.genre ?? 'Pop';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Gonderiyi Duzenle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (post.type == CommunityPostType.song) ...<Widget>[
                      TextField(
                        controller: titleController,
                        decoration:
                            const InputDecoration(labelText: 'Sarki adi'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: artistController,
                        decoration: const InputDecoration(labelText: 'Sanatci'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: genre,
                        decoration: const InputDecoration(labelText: 'Tur'),
                        items: const <String>[
                          'Pop',
                          'Rock',
                          'Lo-fi',
                          'Acoustic',
                          'Electronic',
                          'Turkce Pop',
                        ]
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => genre = value);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (post.type == CommunityPostType.playlist) ...<Widget>[
                      TextField(
                        controller: playlistController,
                        decoration:
                            const InputDecoration(labelText: 'Playlist adi'),
                      ),
                      const SizedBox(height: 10),
                    ],
                    TextField(
                      controller: textController,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Yazi'),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Iptal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true && context.mounted) {
      await context.read<MoodProvider>().updateCommunityPost(
            postId: post.id,
            text: textController.text,
            songTitle: titleController.text,
            artist: artistController.text,
            genre: genre,
            playlistName: playlistController.text,
          );
    }
    textController.dispose();
    titleController.dispose();
    artistController.dispose();
    playlistController.dispose();
  }

  Future<void> _openReplyEditDialog({
    required BuildContext context,
    required String postId,
    required CommunityReply reply,
  }) async {
    final controller = TextEditingController(text: reply.text);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Yaniti Duzenle'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Yanit'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Iptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );

    if (saved == true && context.mounted) {
      await context.read<MoodProvider>().updateCommunityReply(
            postId: postId,
            replyId: reply.id,
            text: controller.text,
          );
    }
    controller.dispose();
  }

  Future<void> _confirmReplyDelete({
    required BuildContext context,
    required String postId,
    required String replyId,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Yaniti Sil'),
          content: const Text('Bu yanit gonderinin altindan kaldirilacak.'),
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
      await context.read<MoodProvider>().deleteCommunityReply(
            postId: postId,
            replyId: replyId,
          );
    }
  }

  Future<void> _openPlaylistPicker(
    BuildContext context,
    CommunityPost post,
  ) async {
    final provider = context.read<MoodProvider>();
    if (provider.playlists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Once bir playlist olustur.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: provider.playlists.keys.map((name) {
              return ListTile(
                leading: const Icon(Icons.queue_music),
                title: Text(name),
                subtitle: Text(
                  'Yapan: ${provider.playlistOwners[name] ?? 'Bilinmiyor'}',
                ),
                onTap: () => Navigator.pop(sheetContext, name),
              );
            }).toList(),
          ),
        );
      },
    );

    if (selected == null) return;
    await provider.addCommunitySongToPlaylist(
      post: post,
      playlistName: selected,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sarki $selected playlistine eklendi.')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Gonderiyi Sil'),
          content: const Text('Bu paylasim topluluk akisindan kaldirilacak.'),
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
      await context.read<MoodProvider>().deleteCommunityPost(postId);
    }
  }

  String _formatDateTime(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }
}
