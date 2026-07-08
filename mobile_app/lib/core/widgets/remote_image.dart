import 'package:flutter/material.dart';

import '../../app/constants.dart';

class RemoteImage extends StatelessWidget {
  const RemoteImage({
    super.key,
    required this.imageUrl,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.overlayColor,
  });

  final String imageUrl;
  final BorderRadius borderRadius;
  final Color? overlayColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppColors.softGreen,
              alignment: Alignment.center,
              child: const Icon(
                Icons.image_rounded,
                color: AppColors.green,
                size: 42,
              ),
            ),
          ),
          if (overlayColor != null) ColoredBox(color: overlayColor!),
        ],
      ),
    );
  }
}
