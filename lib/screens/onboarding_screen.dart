import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/avatar_data.dart';
import '../providers/mood_provider.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  int _currentStep = 0;
  String _avatarId = avatarOptions.first.id;
  String _favoriteGenre = 'Karisik';

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<MoodProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('biMüzik', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                '3 adimda profilini olustur. Tum bilgiler cihazinda local saklanir.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Hesabim Var, Giris Yap'),
                ),
              ),
              const SizedBox(height: 24),
              _StepIndicator(currentStep: _currentStep),
              const SizedBox(height: 20),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: <Widget>[
                    _IdentityStep(
                      firstNameController: _firstNameController,
                      lastNameController: _lastNameController,
                      usernameController: _usernameController,
                    ),
                    _ContactStep(
                      emailController: _emailController,
                      phoneController: _phoneController,
                      passwordController: _passwordController,
                    ),
                    _AvatarStep(
                      selectedAvatar: _avatarId,
                      selectedGenre: _favoriteGenre,
                      genreOptions: provider.genreOptions,
                      onAvatarChanged: (id) => setState(() => _avatarId = id),
                      onGenreChanged: (genre) =>
                          setState(() => _favoriteGenre = genre),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _currentStep == 0
                          ? null
                          : () {
                              setState(() => _currentStep -= 1);
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                            },
                      child: const Text('Geri'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final moodProvider = context.read<MoodProvider>();
                        if (_currentStep < 2) {
                          if (!await _validateStep(
                            context,
                            _currentStep,
                            moodProvider,
                          )) {
                            return;
                          }
                          setState(() => _currentStep += 1);
                          await _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                          return;
                        }
                        if (!await _validateStep(
                          context,
                          _currentStep,
                          moodProvider,
                        )) {
                          return;
                        }
                        final result = await moodProvider.completeProfile(
                          firstName: _firstNameController.text,
                          lastName: _lastNameController.text,
                          username: _usernameController.text,
                          email: _emailController.text,
                          phone: _phoneController.text,
                          avatarId: _avatarId,
                          favoriteGenre: _favoriteGenre,
                          password: _passwordController.text,
                        );
                        if (result != AccountSaveResult.saved) {
                          if (!context.mounted) return;
                          _snack(context, _accountSaveMessage(result));
                          return;
                        }
                        if (context.mounted) {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        }
                      },
                      child:
                          Text(_currentStep == 2 ? 'Kaydi Tamamla' : 'Ileri'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _validateStep(
    BuildContext context,
    int step,
    MoodProvider provider,
  ) async {
    switch (step) {
      case 0:
        if (_firstNameController.text.trim().isEmpty ||
            _lastNameController.text.trim().isEmpty) {
          _snack(context, 'Ad ve soyad zorunlu.');
          return false;
        }
        if (_usernameController.text.trim().length < 3) {
          _snack(context, 'Kullanici adi en az 3 karakter olmali.');
          return false;
        }
        final identityResult = provider.validateNewAccountIdentity(
          username: _usernameController.text,
        );
        if (identityResult != AccountSaveResult.saved) {
          _snack(context, _accountSaveMessage(identityResult));
          return false;
        }
        return true;
      case 1:
        final email = _emailController.text.trim();
        final phone = _phoneController.text.trim();
        if (!email.contains('@') || email.length < 6) {
          _snack(context, 'Gecerli bir email gir.');
          return false;
        }
        if (phone.length < 10) {
          _snack(context, 'Gecerli bir telefon numarasi gir.');
          return false;
        }
        if (_passwordController.text.trim().length < 6) {
          _snack(context, 'Sifre en az 6 karakter olmali.');
          return false;
        }
        final contactResult = provider.validateNewAccountContact(
          email: email,
          phone: phone,
        );
        if (contactResult != AccountSaveResult.saved) {
          _snack(context, _accountSaveMessage(contactResult));
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _accountSaveMessage(AccountSaveResult result) {
    switch (result) {
      case AccountSaveResult.duplicateEmail:
        return 'Bu e-posta ile zaten hesap var. Giris yap.';
      case AccountSaveResult.duplicateUsername:
        return 'Bu kullanici adi zaten kullaniliyor.';
      case AccountSaveResult.duplicatePhone:
        return 'Bu telefon numarasi zaten kullaniliyor.';
      case AccountSaveResult.saved:
        return 'Kayit tamamlandi.';
    }
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(3, (index) {
        final active = index <= currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        );
      }),
    );
  }
}

class _IdentityStep extends StatelessWidget {
  const _IdentityStep({
    required this.firstNameController,
    required this.lastNameController,
    required this.usernameController,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController usernameController;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Adim 1', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Temel kimlik bilgileri',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(labelText: 'Ad'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: 'Soyad'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Kullanici adi',
                prefixText: '@',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactStep extends StatelessWidget {
  const _ContactStep({
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
  });

  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Adim 2', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Iletisim bilgilerini ekle',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefon'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Sifre'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarStep extends StatelessWidget {
  const _AvatarStep({
    required this.selectedAvatar,
    required this.selectedGenre,
    required this.genreOptions,
    required this.onAvatarChanged,
    required this.onGenreChanged,
  });

  final String selectedAvatar;
  final String selectedGenre;
  final List<String> genreOptions;
  final ValueChanged<String> onAvatarChanged;
  final ValueChanged<String> onGenreChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Adim 3', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Profil resmi ve muzik tercihi',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: avatarOptions.map((avatar) {
                final active = selectedAvatar == avatar.id;
                return GestureDetector(
                  onTap: () => onAvatarChanged(avatar.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
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
            DropdownButtonFormField<String>(
              initialValue: selectedGenre,
              decoration: const InputDecoration(labelText: 'Favori Muzik Turu'),
              items: genreOptions
                  .map((genre) => DropdownMenuItem<String>(
                        value: genre,
                        child: Text(genre),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) onGenreChanged(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
