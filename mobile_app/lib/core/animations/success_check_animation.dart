import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SuccessCheckAnimation extends StatelessWidget {
  const SuccessCheckAnimation({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.network(
        'https://assets5.lottiefiles.com/packages/lf20_jbrw3hcz.json',
        repeat: false,
        fit: BoxFit.contain,
      ),
    );
  }
}
