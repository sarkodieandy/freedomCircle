import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/constants.dart';
import '../../app/images.dart';
import '../../core/animations/fade_slide_in.dart';
import '../../core/utils/app_logger.dart';
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
  final imagePicker = ImagePicker();
  final fullNameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();

  late AuthMode mode;
  bool acceptedTerms = false;
  bool loading = false;
  bool pickingAvatar = false;
  String? errorMessage;
  Uint8List? avatarBytes;

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
    AppLogger.auth('Auth mode changed', data: {'mode': value.name});
    setState(() {
      mode = value;
      errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (loading) return;
    AppLogger.auth(
      'Auth submit tapped',
      data: {'mode': isLogin ? 'login' : 'signup'},
    );
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
        AppLogger.auth('Login flow completed at screen level');
        if (!mounted) return;
        _openSuccess();
      } else {
        final phone = phoneController.text.trim();
        await controller.signUpWithEmail(
          fullName: fullNameController.text,
          username: usernameController.text,
          email: emailController.text,
          password: passwordController.text,
          confirmPassword: confirmPasswordController.text,
          avatarBytes: avatarBytes,
          phone: phone,
          acceptedTerms: acceptedTerms,
        );
        AppLogger.auth('Signup flow completed at screen level');
        if (!mounted) return;
        pushAuthScreen(
          context,
          OtpVerificationScreen(
            onVerified: _openSuccess,
            emailOrPhone: phone.isNotEmpty
                ? phone
                : emailController.text.trim(),
          ),
        );
      }
    } on AuthFlowException catch (error) {
      AppLogger.warning(
        'Validation or auth error shown to user',
        tag: 'UI',
        data: {'screen': 'AuthScreen', 'message': error.message},
      );
      setState(() => errorMessage = error.message);
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _openSuccess() {
    AppLogger.navigation('Auth success screen opened');
    pushAuthScreen(
      context,
      AuthSuccessScreen(onContinue: _completeAuthentication),
    );
  }

  void _completeAuthentication() {
    AppLogger.navigation('Auth complete, redirecting to app shell');
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.onAuthenticated();
  }

  Future<void> _showAvatarSourcePicker() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Choose profile photo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Use your camera or pick one from your device.',
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Photo library'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                if (avatarBytes != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded),
                    title: const Text('Remove photo'),
                    onTap: () => Navigator.pop(context, ImageSource.values.first),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || source == null) return;
    if (avatarBytes != null && source == ImageSource.values.first) {
      setState(() => avatarBytes = null);
      return;
    }
    await _pickAvatar(source);
  }

  Future<void> _pickAvatar(ImageSource source) async {
    if (pickingAvatar) return;
    setState(() => pickingAvatar = true);
    try {
      final file = await imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1400,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => avatarBytes = bytes);
    } catch (_) {
      if (!mounted) return;
      setState(() => errorMessage = 'Could not select photo. Try again.');
    } finally {
      if (mounted) {
        setState(() => pickingAvatar = false);
      }
    }
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
                Text(subtitle, style: AppTextStyles.body),
                const SizedBox(height: AppSpacing.xl),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: isLogin ? _loginFields() : _signupFields(),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  AuthErrorMessage(message: errorMessage!),
                ],
                const SizedBox(height: AppSpacing.lg),
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
        _ProfilePhotoPicker(
          imageBytes: avatarBytes,
          onTap: _showAvatarSourcePicker,
          loading: pickingAvatar,
        ),
        const SizedBox(height: 14),
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

class _ProfilePhotoPicker extends StatelessWidget {
  const _ProfilePhotoPicker({
    required this.imageBytes,
    required this.onTap,
    required this.loading,
  });

  final Uint8List? imageBytes;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.line),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.softGreen.withValues(alpha: .58),
              AppColors.card,
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.green.withValues(alpha: .18)),
                color: AppColors.softGreen,
              ),
              child: ClipOval(
                child: imageBytes != null
                    ? Image.memory(imageBytes!, fit: BoxFit.cover)
                    : const Icon(Icons.add_a_photo_outlined, color: AppColors.green),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Profile photo', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    imageBytes == null
                        ? 'Choose a photo from your device to personalize your account.'
                        : 'Tap to change or remove your selected photo.',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    imageBytes == null
                        ? Icons.chevron_right_rounded
                        : Icons.edit_outlined,
                    color: AppColors.green,
                  ),
          ],
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: .04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
