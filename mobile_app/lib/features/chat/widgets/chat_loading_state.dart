import 'package:flutter/material.dart';

import '../../../app/constants.dart';

class ChatLoadingState extends StatelessWidget {
  const ChatLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: 6,
      itemBuilder: (context, index) {
        final mine = index.isEven;
        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: .35, end: 1),
            duration: Duration(milliseconds: 620 + index * 80),
            curve: Curves.easeInOut,
            builder: (context, value, child) =>
                Opacity(opacity: value, child: child),
            child: Container(
              width: index.isEven ? 230 : 280,
              height: index == 1 ? 74 : 58,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: mine ? AppColors.softGreen : AppColors.inkSoft,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      },
    );
  }
}
