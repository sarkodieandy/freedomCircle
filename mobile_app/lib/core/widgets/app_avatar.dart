import 'package:flutter/material.dart';

import '../../app/constants.dart';
import 'app_remote_image.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, this.imageUrl, this.initials, this.radius = 22});

  final String? imageUrl;
  final String? initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return SizedBox(
        width: diameter,
        height: diameter,
        child: AppRemoteImage(
          imageUrl: imageUrl!,
          borderRadius: BorderRadius.circular(100),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.softGreen,
      child: Text(
        initials ?? 'FC',
        style: const TextStyle(
          color: AppColors.green,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
