import 'package:flutter/material.dart';

import '../../app/images.dart';
import '../../core/animations/fade_slide_in.dart';
import 'auth_flow_controller.dart';
import 'auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final authController = const AuthFlowController();
  final emailController = TextEditingController();

  bool loading = false;
  bool sent = false;
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      await authController.sendPasswordReset(emailController.text);
      if (!mounted) return;
      setState(() => sent = true);
    } on AuthFlowException catch (error) {
      setState(() => errorMessage = error.message);
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
        imageUrl: AppImages.study,
        title: 'A secure reset',
        subtitle: 'Quick, private, and tied to your email.',
        icon: Icons.mark_email_read_outlined,
        height: 194,
      ),
      children: [
        FadeSlideIn(child: sent ? _successCard(context) : _formCard(context)),
      ],
    );
  }

  Widget _formCard(BuildContext context) {
    return _ResetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Reset your password',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            "Enter your email and we'll send reset instructions.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          AuthTextField(
            controller: emailController,
            label: 'Email',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 14),
            AuthErrorMessage(message: errorMessage!),
          ],
          const SizedBox(height: 18),
          AuthPrimaryButton(
            label: 'Send reset link',
            icon: Icons.arrow_forward_rounded,
            loading: loading,
            onPressed: _sendReset,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to login'),
          ),
        ],
      ),
    );
  }

  Widget _successCard(BuildContext context) {
    return AuthSuccessCard(
      title: 'Check your email',
      subtitle:
          'Reset instructions are on the way. For privacy, the link expires soon.',
      buttonLabel: 'Back to login',
      onContinue: () => Navigator.pop(context),
    );
  }
}

class _ResetCard extends StatelessWidget {
  const _ResetCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8E2D8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172033).withValues(alpha: .07),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}
