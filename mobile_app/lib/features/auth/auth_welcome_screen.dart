import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/images.dart';
import '../../core/animations/fade_slide_in.dart';
import '../../core/widgets/app_logo.dart';
import 'auth_widgets.dart';

class AuthWelcomeScreen extends StatelessWidget {
  const AuthWelcomeScreen({
    super.key,
    required this.onCreateAccount,
    required this.onLogin,
  });

  final VoidCallback onCreateAccount;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      header: const AuthHeaderVisual(
        imageUrl: AppImages.praying,
        title: 'Private, steady support',
        subtitle: 'Prayer, tracking, circles, and trusted help.',
        icon: Icons.privacy_tip_outlined,
        height: 252,
      ),
      children: [
        FadeSlideIn(
          delay: const Duration(milliseconds: 80),
          child: Row(
            children: [
              const FreedomLogo(size: 54),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'freedonCircle',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Grow stronger. Heal together. Walk in faith.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        FadeSlideIn(
          delay: const Duration(milliseconds: 140),
          child: AuthPrimaryButton(
            label: 'Create Account',
            icon: Icons.person_add_alt_1_rounded,
            onPressed: onCreateAccount,
          ),
        ),
        const SizedBox(height: 12),
        FadeSlideIn(
          delay: const Duration(milliseconds: 190),
          child: AuthPrimaryButton(
            label: 'Login',
            icon: Icons.login_rounded,
            onPressed: onLogin,
            color: AppColors.card,
            foregroundColor: AppColors.green,
          ),
        ),
        const SizedBox(height: 18),
        const FadeSlideIn(
          delay: Duration(milliseconds: 240),
          child: AuthDividerNote(
            icon: Icons.shield_outlined,
            text: 'Your journey stays private. You control what you share.',
          ),
        ),
      ],
    );
  }
}
