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
        spacing: 4,
        children: [
          for (final reaction in reactions)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: reaction.$1,
              onPressed: onReaction == null
                  ? null
                  : () => onReaction!(reaction.$1),
              icon: Icon(reaction.$2, size: compact ? 17 : 20),
              color: AppColors.gold,
            ),
        ],
      ),
    );
  }
}
