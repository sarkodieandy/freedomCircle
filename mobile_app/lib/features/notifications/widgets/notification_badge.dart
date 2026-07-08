import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/notification_repository.dart';

class NotificationBadge extends StatelessWidget {
  const NotificationBadge({
    super.key,
    required this.child,
    this.count,
    this.repository = const NotificationRepository(),
  });

  final Widget child;
  final int? count;
  final NotificationRepository repository;

  @override
  Widget build(BuildContext context) {
    if (count != null) {
      return _BadgeStack(count: count!, child: child);
    }

    return StreamBuilder<int>(
      stream: repository.listenToUnreadCount(),
      builder: (context, snapshot) {
        return _BadgeStack(count: snapshot.data ?? 0, child: child);
      },
    );
  }
}

class _BadgeStack extends StatelessWidget {
  const _BadgeStack({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            right: -6,
            top: -6,
            child: AnimatedScale(
              scale: count > 0 ? 1 : .6,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: AppColors.support,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  AppFormatters.compactCount(count),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
