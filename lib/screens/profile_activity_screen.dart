import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/avatar_data.dart';
import '../models/community_post.dart';
import '../models/user_profile.dart';
import '../providers/mood_provider.dart';

class ProfileActivityScreen extends StatelessWidget {
  const ProfileActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MoodProvider>();
    final profile = provider.userProfile!;
    final email = profile.email;
    final posts = provider.communityPosts;
    final myPosts = posts.where((post) => post.authorEmail == email).toList();
    final repliedPosts = posts
        .where(
          (post) =>
              post.authorEmail != email &&
              post.replies.any((reply) => reply.authorEmail == email),
        )
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(icon: Icon(Icons.article_outlined), text: 'Paylasimlarim'),
              Tab(icon: Icon(Icons.reply_outlined), text: 'Yanitlarim'),
            ],
          ),
        ),
        body: Column(
          children: <Widget>[
            _ProfileHeader(profile: profile),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  _PostList(
                    emptyText: 'Henuz paylasim yapmadin.',
                    children: myPosts
                        .map((post) => _ProfilePostCard(post: post))
                        .toList(),
                  ),
                  _PostList(
                    emptyText: 'Henuz bir gonderiye yanit yazmadin.',
                    children: repliedPosts
                        .map(
                          (post) => _RepliedPostCard(
                            post: post,
                            currentEmail: email,
                          ),
                        )
                        .toList(),
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final avatar = avatarOptions.firstWhere(
      (item) => item.id == profile.avatarId,
      orElse: () => avatarOptions.first,
    );
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: avatar.gradient),
            ),
            alignment: Alignment.center,
            child: Text(avatar.emoji, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('@${profile.username}', style: theme.textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(profile.email, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostList extends StatelessWidget {
  const _PostList({
    required this.emptyText,
    required this.children,
  });

  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(emptyText),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: children.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => children[index],
    );
  }
}

class _ProfilePostCard extends StatelessWidget {
  const _ProfilePostCard({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _PostHeader(post: post),
            const SizedBox(height: 10),
            _PostBody(post: post),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Icon(Icons.mode_comment_outlined,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text('${post.replies.length} yanit'),
                const SizedBox(width: 16),
                Icon(Icons.favorite_border,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text('${post.likedBy.length} begeni'),
              ],
            ),
            if (post.replies.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              ...post.replies.map(_ReplyTile.new),
            ],
          ],
        ),
      ),
    );
  }
}

class _RepliedPostCard extends StatelessWidget {
  const _RepliedPostCard({
    required this.post,
    required this.currentEmail,
  });

  final CommunityPost post;
  final String currentEmail;

  @override
  Widget build(BuildContext context) {
    final myReplies = post.replies
        .where((reply) => reply.authorEmail == currentEmail)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _PostHeader(post: post),
            const SizedBox(height: 10),
            _PostBody(post: post),
            const SizedBox(height: 12),
            Text(
              'Yanitlarim',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...myReplies.map(_ReplyTile.new),
          ],
        ),
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = switch (post.type) {
      CommunityPostType.playlist => Icons.queue_music,
      CommunityPostType.song => Icons.music_note,
      CommunityPostType.mood => Icons.person,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CircleAvatar(child: Icon(icon)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(post.authorName, style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                _formatDateTime(post.createdAt),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PostBody extends StatelessWidget {
  const _PostBody({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (post.type == CommunityPostType.song)
          Text(
            '${post.songTitle ?? 'Sarki'} - ${post.artist ?? '-'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        if (post.type == CommunityPostType.song)
          Text(post.genre ?? '-', style: theme.textTheme.bodySmall),
        if (post.type == CommunityPostType.playlist)
          Text(
            post.playlistName ?? 'Playlist',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        if (post.type == CommunityPostType.playlist)
          Text(
            '${post.playlistSongs.length} sarki',
            style: theme.textTheme.bodySmall,
          ),
        if (post.type != CommunityPostType.mood) const SizedBox(height: 6),
        Text(post.text),
      ],
    );
  }
}

class _ReplyTile extends StatelessWidget {
  const _ReplyTile(this.reply);

  final CommunityReply reply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
        ),
      ),
    );
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
