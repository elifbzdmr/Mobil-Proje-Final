import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/avatar_data.dart';
import '../providers/mood_provider.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  final _currentPasswordController = TextEditingController();
  final _nextPasswordController = TextEditingController();
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
    _currentPasswordController.dispose();
    _nextPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MoodProvider>();
    final profile = provider.userProfile!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Hesap Ayarlari')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Profil Bilgileri', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: avatarOptions.map((avatar) {
                      final active = avatar.id == _avatarId;
                      return InkWell(
                        borderRadius: BorderRadius.circular(28),
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
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
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
                        .map(
                          (genre) => DropdownMenuItem<String>(
                            value: genre,
                            child: Text(genre),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _genre = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        if (!_validateProfile(context)) return;
                        final next = profile.copyWith(
                          firstName: _firstNameController.text.trim(),
                          lastName: _lastNameController.text.trim(),
                          username: _usernameController.text.trim(),
                          email: _emailController.text.trim(),
                          phone: _phoneController.text.trim(),
                          avatarId: _avatarId,
                          favoriteGenre: _genre,
                        );
                        final result = await context
                            .read<MoodProvider>()
                            .updateProfile(next);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _accountSaveMessage(result),
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Bilgileri Kaydet'),
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
                  Text('Sifre', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _currentPasswordController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Mevcut sifre'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nextPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Yeni sifre'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await context
                            .read<MoodProvider>()
                            .changePassword(
                              currentPassword: _currentPasswordController.text,
                              nextPassword: _nextPasswordController.text,
                            );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'Sifre guncellendi.'
                                  : 'Sifre degistirilemedi. Bilgileri kontrol et.',
                            ),
                          ),
                        );
                        if (ok) {
                          _currentPasswordController.clear();
                          _nextPasswordController.clear();
                        }
                      },
                      icon: const Icon(Icons.key_outlined),
                      label: const Text('Sifreyi Degistir'),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text('Oturum', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await context.read<MoodProvider>().logout();
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Cikis Yap'),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Hesabi Sil'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _validateProfile(BuildContext context) {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty) {
      _snack(context, 'Ad ve soyad zorunlu.');
      return false;
    }
    if (!_emailController.text.contains('@')) {
      _snack(context, 'Gecerli bir email gir.');
      return false;
    }
    if (_usernameController.text.trim().length < 3) {
      _snack(context, 'Kullanici adi en az 3 karakter olmali.');
      return false;
    }
    if (_phoneController.text.trim().length < 10) {
      _snack(context, 'Gecerli bir telefon numarasi gir.');
      return false;
    }
    return true;
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hesabi Sil'),
          content:
              const Text('Profil, playlist ve istatistik verileri silinecek.'),
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
      await context.read<MoodProvider>().deleteAccount();
      if (context.mounted) Navigator.pop(context);
    }
  }

  void _snack(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
        return 'Hesap bilgileri guncellendi.';
    }
  }
}
