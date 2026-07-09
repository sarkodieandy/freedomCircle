import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/constants.dart';
import '../../app/images.dart';
import '../../core/animations/fade_slide_in.dart';
import '../../core/animations/pressable_scale.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/remote_image.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.children,
    this.header,
    this.withBack = false,
    this.onBack,
    this.bottomPadding = 28,
  });

  final List<Widget> children;
  final Widget? header;
  final bool withBack;
  final VoidCallback? onBack;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(20, 14, 20, bottomPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (withBack)
                          IconButton.filledTonal(
                            onPressed: onBack ?? () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.card,
                              foregroundColor: AppColors.navy,
                            ),
                          )
                        else
                          const FreedomLogo(size: 44),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'freedonCircle',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const AppIconContainer(
                          icon: Icons.shield_outlined,
                          size: 42,
                          iconSize: 20,
                        ),
                      ],
                    ),
                    if (header != null) ...[
                      const SizedBox(height: AppSpacing.xl),
                      header!,
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    ...children,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AuthHeaderVisual extends StatelessWidget {
  const AuthHeaderVisual({
    super.key,
    this.imageUrl = AppImages.journaling,
    required this.title,
    required this.subtitle,
    this.icon = Icons.lock_outline_rounded,
    this.height = 218,
  });

  final String imageUrl;
  final String title;
  final String subtitle;
  final IconData icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: .06),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: RemoteImage(
                  imageUrl: imageUrl,
                  overlayColor: AppColors.navy.withValues(alpha: .12),
                ),
              ),
            ),
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: .2, sigmaY: .2),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.card.withValues(alpha: .9),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: Colors.white.withValues(alpha: .7)),
                ),
                child: Row(
                  children: [
                    AppIconContainer(icon: icon, size: 42, iconSize: 20),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppTextStyles.cardTitle),
                          const SizedBox(height: 2),
                          Text(subtitle, style: AppTextStyles.body),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.errorText,
    this.onChanged,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;
    final hasError = widget.errorText != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          if (focused)
            BoxShadow(
              color: AppColors.green.withValues(alpha: .08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: focusNode,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        inputFormatters: widget.inputFormatters,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          labelText: widget.label,
          errorText: widget.errorText,
          prefixIcon: Icon(
            widget.icon,
            color: hasError
                ? AppColors.support
                : focused
                ? AppColors.green
                : AppColors.mutedText,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(
              color: hasError ? AppColors.support : AppColors.line,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(
              color: hasError ? AppColors.support : AppColors.green,
              width: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}

class PasswordTextField extends StatefulWidget {
  const PasswordTextField({
    super.key,
    required this.controller,
    required this.label,
    this.errorText,
    this.onChanged,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool hidden = true;

  @override
  Widget build(BuildContext context) {
    return AuthTextFieldShell(
      controller: widget.controller,
      label: widget.label,
      icon: Icons.lock_outline_rounded,
      obscureText: hidden,
      errorText: widget.errorText,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      suffix: IconButton(
        onPressed: () => setState(() => hidden = !hidden),
        icon: Icon(
          hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        ),
      ),
    );
  }
}

class AuthTextFieldShell extends StatefulWidget {
  const AuthTextFieldShell({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.errorText,
    this.textInputAction,
    this.onChanged,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final String? errorText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;

  @override
  State<AuthTextFieldShell> createState() => _AuthTextFieldShellState();
}

class _AuthTextFieldShellState extends State<AuthTextFieldShell> {
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;
    final hasError = widget.errorText != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          if (focused)
            BoxShadow(
              color: AppColors.green.withValues(alpha: .08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: focusNode,
        obscureText: widget.obscureText,
        textInputAction: widget.textInputAction,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          labelText: widget.label,
          errorText: widget.errorText,
          prefixIcon: Icon(
            widget.icon,
            color: hasError
                ? AppColors.support
                : focused
                ? AppColors.green
                : AppColors.mutedText,
          ),
          suffixIcon: widget.suffix,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(
              color: hasError ? AppColors.support : AppColors.line,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(
              color: hasError ? AppColors.support : AppColors.green,
              width: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
    this.color = AppColors.green,
    this.foregroundColor = Colors.white,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;
  final Color color;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      enabled: onPressed != null && !loading,
      child: FilledButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: foregroundColor,
                ),
              )
            : Icon(icon),
        label: Text(label, overflow: TextOverflow.ellipsis),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: .78),
          foregroundColor: foregroundColor,
          disabledForegroundColor: foregroundColor,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          elevation: 0,
        ),
      ),
    );
  }
}

class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.text,
    required this.actionText,
    required this.onPressed,
  });

  final String text;
  final String actionText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
        TextButton(onPressed: onPressed, child: Text(actionText)),
      ],
    );
  }
}

class OtpInputField extends StatefulWidget {
  const OtpInputField({
    super.key,
    required this.onChanged,
    this.hasError = false,
    this.isSuccess = false,
  });

  final ValueChanged<String> onChanged;
  final bool hasError;
  final bool isSuccess;

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late final List<TextEditingController> controllers;
  late final List<FocusNode> focusNodes;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(6, (_) => TextEditingController());
    focusNodes = List.generate(6, (_) => FocusNode());
    for (final node in focusNodes) {
      node.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
    for (final node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _emit() {
    widget.onChanged(controllers.map((controller) => controller.text).join());
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(6, (index) {
        final focused = focusNodes[index].hasFocus;
        final color = widget.isSuccess
            ? AppColors.success
            : widget.hasError
            ? AppColors.support
            : focused
            ? AppColors.green
            : AppColors.line;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 5 ? 0 : 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: color, width: focused ? 1.6 : 1),
                boxShadow: [
                  if (focused)
                    BoxShadow(
                      color: AppColors.green.withValues(alpha: .08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                ],
              ),
              child: TextField(
                controller: controllers[index],
                focusNode: focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                textInputAction: index == 5
                    ? TextInputAction.done
                    : TextInputAction.next,
                maxLength: 1,
                style: Theme.of(context).textTheme.titleLarge,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    focusNodes[index + 1].requestFocus();
                  }
                  if (value.isEmpty && index > 0) {
                    focusNodes[index - 1].requestFocus();
                  }
                  _emit();
                },
              ),
            ),
          ),
        );
      }),
    );
  }
}

class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  int get score {
    var value = 0;
    if (password.length >= 8) value++;
    if (RegExp('[A-Z]').hasMatch(password)) value++;
    if (RegExp('[0-9]').hasMatch(password)) value++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) value++;
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final currentScore = score;
    final label = switch (currentScore) {
      0 || 1 => 'Gentle start',
      2 || 3 => 'Getting stronger',
      _ => 'Strong password',
    };
    final color = switch (currentScore) {
      0 || 1 => AppColors.support,
      2 || 3 => AppColors.gold,
      _ => AppColors.green,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            4,
            (index) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == 3 ? 0 : 7),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 6,
                  decoration: BoxDecoration(
                    color: index < currentScore
                        ? color
                        : AppColors.line.withValues(alpha: .75),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: color),
          child: Text(label),
        ),
      ],
    );
  }
}

class AuthErrorMessage extends StatelessWidget {
  const AuthErrorMessage({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.supportBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.support.withValues(alpha: .24)),
      ),
      child: Row(
        children: [
          const AppIconContainer(
            icon: Icons.error_outline_rounded,
            color: AppColors.support,
            size: 36,
            iconSize: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.navy),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthSuccessCard extends StatelessWidget {
  const AuthSuccessCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onContinue,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onContinue;

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
            color: AppColors.navy.withValues(alpha: .05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: .72, end: 1),
            duration: const Duration(milliseconds: 620),
            curve: Curves.elasticOut,
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: AppColors.mintGreen,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.line),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.green,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          AuthPrimaryButton(
            label: buttonLabel,
            icon: Icons.arrow_forward_rounded,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class AuthDividerNote extends StatelessWidget {
  const AuthDividerNote({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.mintGreen,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconContainer(icon: icon, size: 34, iconSize: 16),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.navy),
            ),
          ),
        ],
      ),
    );
  }
}

Future<T?> pushAuthScreen<T>(BuildContext context, Widget screen) {
  return Navigator.of(context).push<T>(
    PageRouteBuilder(
      pageBuilder: (_, animation, _) => screen,
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, .04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}
