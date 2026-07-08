import 'package:flutter/material.dart';

import '../../app/images.dart';
import 'auth_widgets.dart';

class AuthSuccessScreen extends StatelessWidget {
  const AuthSuccessScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      withBack: false,
      header: const AuthHeaderVisual(
        imageUrl: AppImages.chapel,
        title: 'Welcome into the circle',
        subtitle: 'Your next step is a simple private setup.',
        icon: Icons.verified_outlined,
        height: 210,
      ),
      children: [
        AuthSuccessCard(
          title: "You're all set",
          subtitle: "Let's personalize your FreedomCircle journey.",
          buttonLabel: 'Continue setup',
          onContinue: onContinue,
        ),
      ],
    );
  }
}
