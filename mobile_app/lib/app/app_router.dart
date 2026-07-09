import '../data/models/accountability_group.dart';
import '../data/models/helper_profile.dart';

class NavigationShellRouteArgs {
  const NavigationShellRouteArgs({this.initialTab = 0});

  final int initialTab;
}

class GroupDetailRouteArgs {
  const GroupDetailRouteArgs({required this.group});

  final AccountabilityGroup group;
}

class GroupChatRouteArgs {
  const GroupChatRouteArgs({
    required this.groupId,
    required this.title,
    this.prayerGroup = false,
  });

  final String groupId;
  final String title;
  final bool prayerGroup;
}

class HelperProfileRouteArgs {
  const HelperProfileRouteArgs({required this.helper});

  final HelperProfile helper;
}

class BookingRouteArgs {
  const BookingRouteArgs({required this.helper});

  final HelperProfile helper;
}
