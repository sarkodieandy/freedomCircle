import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/constants.dart';
import 'app_loading_shimmer.dart';

class AppRemoteImage extends StatelessWidget {
  const AppRemoteImage({
    super.key,
    required this.imageUrl,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.overlayColor,
    this.aspectRatio,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.image_rounded,
  });

  final String imageUrl;
  final BorderRadius borderRadius;
  final Color? overlayColor;
  final double? aspectRatio;
  final BoxFit fit;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: fit,
            placeholder: (_, _) =>
                const AppLoadingShimmer(height: double.infinity),
            errorWidget: (_, _, _) => Container(
              color: AppColors.softGreen,
              alignment: Alignment.center,
              child: Icon(fallbackIcon, color: AppColors.green, size: 34),
            ),
          ),
          if (overlayColor != null) ColoredBox(color: overlayColor!),
        ],
      ),
    );

    if (aspectRatio == null) return image;
    return AspectRatio(aspectRatio: aspectRatio!, child: image);
  }
}
