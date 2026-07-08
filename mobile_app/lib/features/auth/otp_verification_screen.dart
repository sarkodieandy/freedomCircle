import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/images.dart';
import '../../core/animations/fade_slide_in.dart';
import 'auth_flow_controller.dart';
import 'auth_widgets.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.onVerified,
    this.emailOrPhone,
  });

  final VoidCallback onVerified;
  final String? emailOrPhone;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  final authController = const AuthFlowController();
  late final AnimationController shakeController;

  Timer? timer;
  int secondsLeft = 45;
  String code = '';
  String? errorMessage;
  bool loading = false;
  bool verified = false;

  @override
  void initState() {
    super.initState();
    shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    shakeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    timer?.cancel();
    setState(() => secondsLeft = 45);
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft <= 1) {
        timer.cancel();
        setState(() => secondsLeft = 0);
      } else {
        setState(() => secondsLeft--);
      }
    });
  }

  Future<void> _verify() async {
    if (loading) return;
    setState(() {
      loading = true;
      errorMessage = null;
      verified = false;
    });

    try {
      await authController.verifyOtp(code, emailOrPhone: widget.emailOrPhone);
      if (!mounted) return;
      setState(() => verified = true);
      await Future<void>.delayed(const Duration(milliseconds: 440));
      if (!mounted) return;
      widget.onVerified();
    } on AuthFlowException catch (error) {
      setState(() => errorMessage = error.message);
      shakeController.forward(from: 0);
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      withBack: true,
      header: const AuthHeaderVisual(
        imageUrl: AppImages.mentor,
        title: 'One more secure step',
        subtitle: 'Email and phone verification are ready.',
        icon: Icons.verified_user_outlined,
        height: 190,
      ),
      children: [
        FadeSlideIn(
          child: _OtpCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Verify your account',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the code sent to your phone or email.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 22),
                AnimatedBuilder(
                  animation: shakeController,
                  builder: (context, child) {
                    final offset =
                        math.sin(shakeController.value * math.pi * 6) * 8;
                    return Transform.translate(
                      offset: Offset(offset, 0),
                      child: child,
                    );
                  },
                  child: OtpInputField(
                    hasError: errorMessage != null,
                    isSuccess: verified,
                    onChanged: (value) {
                      setState(() {
                        code = value;
                        errorMessage = null;
                      });
                    },
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 14),
                  AuthErrorMessage(message: errorMessage!),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        secondsLeft > 0
                            ? 'Resend code in ${secondsLeft}s'
                            : 'You can resend the code now',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: secondsLeft == 0 ? _startTimer : null,
                      child: const Text('Resend'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AuthPrimaryButton(
                  label: verified ? 'Verified' : 'Verify',
                  icon: verified
                      ? Icons.check_circle_rounded
                      : Icons.verified_rounded,
                  loading: loading,
                  onPressed: _verify,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Change phone/email'),
                ),
                const AuthDividerNote(
                  icon: Icons.shield_outlined,
                  text:
                      'Verification protects your private goals, groups, and prayer requests.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OtpCard extends StatelessWidget {
  const _OtpCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: .07),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}
