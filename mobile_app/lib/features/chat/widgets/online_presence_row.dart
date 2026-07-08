import 'package:flutter/material.dart';

import '../../../app/constants.dart';

class OnlinePresenceRow extends StatelessWidget {
  const OnlinePresenceRow({
    super.key,
    required this.onlineCount,
    this.subtitle,
    this.accent = AppColors.green,
  });

  final int onlineCount;
  final String? subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: .18)),
      ),
      child: Row(
        children: [
          for (final item in const ['A', 'D', 'E'])
            Align(
              widthFactor: .74,
              child: CircleAvatar(
                radius: 13,
                backgroundColor: AppColors.card,
                child: Text(
                  item,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              subtitle ?? '$onlineCount online now',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}
