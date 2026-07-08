import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/images.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/remote_image.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> fade;
  late final Animation<double> scale;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    fade = CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);
    scale = Tween<double>(
      begin: .92,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: AppColors.background)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 260,
            child: RemoteImage(
              imageUrl: AppImages.chapel,
              borderRadius: BorderRadius.zero,
              overlayColor: AppColors.background.withValues(alpha: .38),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  FadeTransition(
                    opacity: fade,
                    child: ScaleTransition(
                      scale: scale,
                      child: Column(
                        children: [
                          const FreedomLogo(size: 96),
                          const SizedBox(height: 24),
                          Text(
                            'FreedomCircle',
                            style: Theme.of(context).textTheme.displaySmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Grow stronger. Heal together. Walk in faith.',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppColors.mutedText),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: 'Begin',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: widget.onContinue,
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
