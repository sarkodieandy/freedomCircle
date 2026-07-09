import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../app/constants.dart';

class AppLoadingShimmer extends StatelessWidget {
  const AppLoadingShimmer({
    super.key,
    this.height = 16,
    this.width,
    this.radius = 12,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.softCream,
      highlightColor: Colors.white,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.softCream,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
