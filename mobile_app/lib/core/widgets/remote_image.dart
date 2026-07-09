import 'package:flutter/material.dart';

import 'app_remote_image.dart';

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
    return AppRemoteImage(
      imageUrl: imageUrl,
      borderRadius: borderRadius,
      overlayColor: overlayColor,
      fallbackIcon: Icons.image_rounded,
    );
  }
}
