import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/mood_provider.dart';
import 'onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  bool _hidePassword = true;

  @override
  void initState() {
    super.initState();
    final profile = context.read<MoodProvider>().userProfile;
    _emailController = TextEditingController(text: profile?.email ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<MoodProvider>().userProfile;
    final hasAnyAccount = context.select<MoodProvider, bool>(
      (provider) => provider.hasAnyAccount,
    );
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.lock_person_outlined,
                        size: 42,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 14),
                      Text('biMüzik Giris',
                          style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 6),
                      Text(
                        profile == null
                            ? 'Hesabina giris yap.'
                            : '@${profile.username} hesabi ile devam et.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: _hidePassword,
                        decoration: InputDecoration(
                          labelText: 'Sifre',
                          prefixIcon: const Icon(Icons.password),
                          suffixIcon: IconButton(
                            tooltip: _hidePassword
                                ? 'Sifreyi goster'
                                : 'Sifreyi gizle',
                            onPressed: () {
                              setState(() => _hidePassword = !_hidePassword);
                            },
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            if (!hasAnyAccount) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Bu cihazda kayitli hesap yok. Once kayit ol.',
                                  ),
                                ),
                              );
                              return;
                            }
                            final ok = await context.read<MoodProvider>().login(
                                  email: _emailController.text,
                                  password: _passwordController.text,
                                );
                            if (!ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Email veya sifre hatali.'),
                                ),
                              );
                            }
                            if (ok && context.mounted) {
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst);
                            }
                          },
                          icon: const Icon(Icons.login),
                          label: const Text('Giris Yap'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const OnboardingScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.person_add_alt_outlined),
                          label: const Text('Kayit Ol'),
                        ),
                      ),
                      if (profile?.passwordHash.isEmpty ?? false) ...<Widget>[
                        const SizedBox(height: 12),
                        Text(
                          'Eski kayit icin girdigin sifre yeni hesap sifren olarak kaydedilir.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
