import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/images.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/remote_image.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  Timer? _autoSlideTimer;

  int page = 0;
  bool _completed = false;

  final pages = const [
    _OnboardingPageData(
      title: 'You are not alone',
      body:
          'Private accountability, prayer, and Christian support for the habits you are ready to face with grace.',
      image: AppImages.journaling,
      icon: Icons.favorite_rounded,
    ),
    _OnboardingPageData(
      title: 'Track your growth',
      body:
          'Streaks, check-ins, prayer, fasting, and Bible rhythms in one calm place.',
      image: AppImages.study,
      icon: Icons.insights_rounded,
    ),
    _OnboardingPageData(
      title: 'Find your circle',
      body:
          'Join safe groups, request prayer, and connect with verified helpers when you want support.',
      image: AppImages.group,
      icon: Icons.groups_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    controller.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _completed) return;

      if (page >= pages.length - 1) {
        _completed = true;
        _autoSlideTimer?.cancel();
        widget.onFinished();
        return;
      }

      controller.nextPage(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  const FreedomLogo(size: 42),
                  const SizedBox(width: 12),
                  Text(
                    'FreedomCircle',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onFinished,
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: pages.length,
                onPageChanged: (value) {
                  setState(() => page = value);
                  _startAutoSlide();
                },
                itemBuilder: (context, index) =>
                    _OnboardingPage(data: pages[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: page == i ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: page == i ? AppColors.green : AppColors.line,
                        borderRadius: BorderRadius.circular(10),
                      ),
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

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.title,
    required this.body,
    required this.image,
    required this.icon,
  });

  final String title;
  final String body;
  final String image;
  final IconData icon;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: RemoteImage(imageUrl: data.image)),
                Positioned(
                  left: 18,
                  bottom: 18,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.card.withValues(alpha: .92),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(data.icon, color: AppColors.green, size: 30),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(data.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(data.body, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
