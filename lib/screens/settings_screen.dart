import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/avatar_data.dart';
import '../providers/mood_provider.dart';
import 'account_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MoodProvider>();
    final profile = provider.userProfile!;
    final avatar = avatarOptions.firstWhere(
      (a) => a.id == profile.avatarId,
      orElse: () => avatarOptions.first,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: avatar.gradient),
                ),
                alignment: Alignment.center,
                child: Text(avatar.emoji, style: const TextStyle(fontSize: 24)),
              ),
              title: Text(
                '@${profile.username}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text('${profile.fullName} - ${profile.email}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const AccountSettingsScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Tema', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const <ButtonSegment<ThemeMode>>[
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        label: Text('Sistem'),
                        icon: Icon(Icons.brightness_auto),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.light,
                        label: Text('Acik'),
                        icon: Icon(Icons.light_mode),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark,
                        label: Text('Koyu'),
                        icon: Icon(Icons.dark_mode),
                      ),
                    ],
                    selected: <ThemeMode>{provider.themeMode},
                    onSelectionChanged: (selection) async {
                      await context
                          .read<MoodProvider>()
                          .setThemeMode(selection.first);
                    },
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
                  Text('Veriler',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await context.read<MoodProvider>().resetMoodStats();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Istatistikler sifirlandi.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Mood Istatistiklerini Sifirla'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
