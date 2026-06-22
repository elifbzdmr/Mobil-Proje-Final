import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mood_data.dart';
import '../providers/mood_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MoodProvider>();
    final totalMoodCount = provider.moodCounts.values.fold<int>(
      0,
      (total, count) => total + count,
    );
    final topMood = _topMood(provider);

    return Scaffold(
      appBar: AppBar(title: const Text('Istatistikler')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: <Widget>[
              _MetricTile(
                icon: Icons.mood,
                label: 'Mood Secimi',
                value: '$totalMoodCount',
              ),
              _MetricTile(
                icon: Icons.star_outline,
                label: 'En Yogun Mood',
                value: topMood,
              ),
              _MetricTile(
                icon: Icons.library_music,
                label: 'Kitaplik',
                value: '${provider.librarySongs.length}',
              ),
              _MetricTile(
                icon: Icons.queue_music,
                label: 'Playlist',
                value: '${provider.playlists.length}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Mood Dagilimi',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (totalMoodCount == 0)
                    const _EmptyState(text: 'Mood sectikce dagilim olusur.')
                  else
                    SizedBox(
                      height: 230,
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: PieChart(
                              PieChartData(
                                centerSpaceRadius: 44,
                                sectionsSpace: 3,
                                sections: moodOptions.map((mood) {
                                  final count =
                                      provider.moodCounts[mood.key] ?? 0;
                                  return PieChartSectionData(
                                    value: count.toDouble(),
                                    color: Color(mood.colorHex),
                                    title: count == 0 ? '' : '$count',
                                    radius: 54,
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: moodOptions.map((mood) {
                                final count =
                                    provider.moodCounts[mood.key] ?? 0;
                                final percent = totalMoodCount == 0
                                    ? 0
                                    : (count * 100 / totalMoodCount).round();
                                return _LegendRow(
                                  color: Color(mood.colorHex),
                                  label: mood.label,
                                  value: '$percent%',
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Muzik Aktivitesi',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _ProgressRow(
                    label: 'Kitapliga eklenen sarki',
                    value: provider.librarySongs.length,
                    maxValue: _activityMax(provider),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  _ProgressRow(
                    label: 'Olusturulan playlist',
                    value: provider.playlists.length,
                    maxValue: _activityMax(provider),
                    color: const Color(0xFF16A34A),
                  ),
                  _ProgressRow(
                    label: 'Topluluk paylasimi',
                    value: provider.communityPosts.length,
                    maxValue: _activityMax(provider),
                    color: const Color(0xFFEA580C),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _topMood(MoodProvider provider) {
    var topLabel = '-';
    var topCount = 0;
    for (final mood in moodOptions) {
      final count = provider.moodCounts[mood.key] ?? 0;
      if (count > topCount) {
        topCount = count;
        topLabel = mood.label;
      }
    }
    return topCount == 0 ? '-' : topLabel;
  }

  int _activityMax(MoodProvider provider) {
    final values = <int>[
      provider.librarySongs.length,
      provider.playlists.length,
      provider.communityPosts.length,
      1,
    ];
    return values.reduce((a, b) => a > b ? a : b);
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final String label;
  final int value;
  final int maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = maxValue == 0 ? 0.0 : value / maxValue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(label)),
              Text('$value', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: color,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(child: Text(text)),
    );
  }
}
