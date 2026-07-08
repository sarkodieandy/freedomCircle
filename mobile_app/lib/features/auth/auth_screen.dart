import 'package:flutter/material.dart';

import '../../app/images.dart';
import '../../core/animations/fade_slide_in.dart';
import 'auth_flow_controller.dart';
import 'auth_success_screen.dart';
import 'auth_widgets.dart';
import 'forgot_password_screen.dart';
import 'otp_verification_screen.dart';

enum AuthMode { login, signup }

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.onAuthenticated,
    this.initialMode = AuthMode.login,
  });

  final VoidCallback onAuthenticated;
  final AuthMode initialMode;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final controller = const AuthFlowController();
  final fullNameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();

  late AuthMode mode;
  bool acceptedTerms = false;
  bool loading = false;
  String? errorMessage;

  bool get isLogin => mode == AuthMode.login;

  @override
  void initState() {
    super.initState();
    mode = widget.initialMode;
    passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    fullNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _setMode(AuthMode value) {
    setState(() {
      mode = value;
      errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (loading) return;
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      if (isLogin) {
        await controller.signInWithEmail(
          email: emailController.text,
          password: passwordController.text,
        );
        if (!mounted) return;
        _openSuccess();
      } else {
        await controller.signUpWithEmail(
          fullName: fullNameController.text,
          username: usernameController.text,
          email: emailController.text,
          password: passwordController.text,
          confirmPassword: confirmPasswordController.text,
          phone: phoneController.text,
          acceptedTerms: acceptedTerms,
        );
        if (!mounted) return;
        pushAuthScreen(
          context,
          OtpVerificationScreen(onVerified: _openSuccess),
        );
      }
    } on AuthFlowException catch (error) {
      setState(() => errorMessage = error.message);
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _openSuccess() {
    pushAuthScreen(
      context,
      AuthSuccessScreen(onContinue: _completeAuthentication),
    );
  }

  void _completeAuthentication() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.onAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    final title = isLogin ? 'Welcome back' : 'Create your account';
    final subtitle = isLogin
        ? 'Continue your journey with your circle.'
        : 'Start your private growth and accountability journey.';

    return AuthScaffold(
      withBack: true,
      header: AuthHeaderVisual(
        imageUrl: isLogin ? AppImages.journaling : AppImages.group,
        title: isLogin ? 'Quiet progress, steady grace' : 'Begin with privacy',
        subtitle: isLogin
            ? 'Your goals, prayer, and groups are waiting.'
            : 'Set your profile before joining your circle.',
        icon: isLogin ? Icons.lock_outline_rounded : Icons.shield_outlined,
        height: 190,
      ),
      children: [
        FadeSlideIn(
          child: _AuthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: isLogin ? _loginFields() : _signupFields(),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 14),
                  AuthErrorMessage(message: errorMessage!),
                ],
                const SizedBox(height: 18),
                AuthPrimaryButton(
                  label: isLogin ? 'Login' : 'Create Account',
                  icon: isLogin
                      ? Icons.lock_open_rounded
                      : Icons.verified_user_outlined,
                  loading: loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 8),
                if (isLogin)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          pushAuthScreen(context, const ForgotPasswordScreen()),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                AuthFooterLink(
                  text: isLogin ? 'New here?' : 'Already have an account?',
                  actionText: isLogin ? 'Create account' : 'Login',
                  onPressed: () =>
                      _setMode(isLogin ? AuthMode.signup : AuthMode.login),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _loginFields() {
    return Column(
      key: const ValueKey('login-fields'),
      children: [
        AuthTextField(
          controller: emailController,
          label: 'Email',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        PasswordTextField(
          controller: passwordController,
          label: 'Password',
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _signupFields() {
    return Column(
      key: const ValueKey('signup-fields'),
      children: [
        AuthTextField(
          controller: fullNameController,
          label: 'Full name',
          icon: Icons.person_outline_rounded,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        AuthTextField(
          controller: usernameController,
          label: 'Username',
          icon: Icons.alternate_email_rounded,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        AuthTextField(
          controller: emailController,
          label: 'Email',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        PasswordTextField(
          controller: passwordController,
          label: 'Password',
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 10),
        PasswordStrengthMeter(password: passwordController.text),
        const SizedBox(height: 14),
        PasswordTextField(
          controller: confirmPasswordController,
          label: 'Confirm password',
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        AuthTextField(
          controller: phoneController,
          label: 'Phone optional',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 14),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => acceptedTerms = !acceptedTerms),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: acceptedTerms,
                  onChanged: (value) =>
                      setState(() => acceptedTerms = value ?? false),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'I agree to the terms and privacy promise.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.child});

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
