import 'package:flutter/material.dart';

import '../../../app/constants.dart';

class MessageReactionBar extends StatelessWidget {
  const MessageReactionBar({
    super.key,
    required this.messageId,
    this.onReaction,
    this.compact = true,
  });

  final String messageId;
  final ValueChanged<String>? onReaction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final reactions = const [
      ('amen', Icons.volunteer_activism_rounded),
      ('pray', Icons.church_rounded),
      ('encourage', Icons.handshake_rounded),
      ('heart', Icons.favorite_rounded),
    ];

    return Padding(
      padding: EdgeInsets.only(top: compact ? 4 : 8),
      child: Wrap(
        spacing: 6,
        children: [
          for (final reaction in reactions)
            InkWell(
              borderRadius: BorderRadius.circular(100),
              onTap: onReaction == null ? null : () => onReaction!(reaction.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.paleGold,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: .4),
                  ),
                ),
                child: Icon(
                  reaction.$2,
                  size: compact ? 14 : 18,
                  color: AppColors.gold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
