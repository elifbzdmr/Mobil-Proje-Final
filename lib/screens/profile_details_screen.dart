import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/avatar_data.dart';
import '../models/user_profile.dart';
import '../providers/mood_provider.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late String _avatarId;
  late String _genre;

  @override
  void initState() {
    super.initState();
    final profile = context.read<MoodProvider>().userProfile!;
    _firstNameController = TextEditingController(text: profile.firstName);
    _lastNameController = TextEditingController(text: profile.lastName);
    _usernameController = TextEditingController(text: profile.username);
    _emailController = TextEditingController(text: profile.email);
    _phoneController = TextEditingController(text: profile.phone);
    _avatarId = profile.avatarId;
    _genre = profile.favoriteGenre;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MoodProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Detaylari')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Profil Resmi',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: avatarOptions.map((avatar) {
                      final active = avatar.id == _avatarId;
                      return GestureDetector(
                        onTap: () => setState(() => _avatarId = avatar.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: avatar.gradient),
                            border: Border.all(
                              width: active ? 3 : 1,
                              color: active
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(avatar.emoji,
                              style: const TextStyle(fontSize: 24)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'Ad'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Soyad'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Kullanici adi',
                      prefixText: '@',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Telefon'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _genre,
                    decoration: const InputDecoration(labelText: 'Favori Tur'),
                    items: provider.genreOptions
                        .map((genre) => DropdownMenuItem<String>(
                              value: genre,
                              child: Text(genre),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _genre = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final next = UserProfile(
                firstName: _firstNameController.text.trim(),
                lastName: _lastNameController.text.trim(),
                username: _usernameController.text.trim(),
                email: _emailController.text.trim(),
                phone: _phoneController.text.trim(),
                avatarId: _avatarId,
                favoriteGenre: _genre,
                passwordHash: provider.userProfile?.passwordHash ?? '',
              );
              final result =
                  await context.read<MoodProvider>().updateProfile(next);
              if (!context.mounted) return;
              if (result != AccountSaveResult.saved) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_accountSaveMessage(result)),
                  ),
                );
                return;
              }
              Navigator.pop(context);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  String _accountSaveMessage(AccountSaveResult result) {
    switch (result) {
      case AccountSaveResult.duplicateEmail:
        return 'Bu e-posta baska bir hesapta kullaniliyor.';
      case AccountSaveResult.duplicateUsername:
        return 'Bu kullanici adi baska bir hesapta kullaniliyor.';
      case AccountSaveResult.duplicatePhone:
        return 'Bu telefon numarasi baska bir hesapta kullaniliyor.';
      case AccountSaveResult.saved:
        return 'Profil guncellendi.';
    }
  }
}
