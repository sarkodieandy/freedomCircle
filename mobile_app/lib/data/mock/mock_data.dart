import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/images.dart';
import '../models/accountability_group.dart';
import '../models/community_post.dart';
import '../models/focus_option.dart';
import '../models/helper_profile.dart';

class MockDataService {
  const MockDataService._();

  static const focusOptions = [
    FocusOption(
      title: 'Prayer discipline',
      icon: Icons.volunteer_activism_rounded,
      color: AppColors.gold,
      iconUrl: 'https://img.icons8.com/color/96/praying-hands.png',
    ),
    FocusOption(
      title: 'Fasting discipline',
      icon: Icons.local_fire_department_rounded,
      color: AppColors.support,
      iconUrl: 'https://img.icons8.com/color/96/fire-element.png',
    ),
    FocusOption(
      title: 'Bible study consistency',
      icon: Icons.auto_stories_rounded,
      color: AppColors.green,
      iconUrl: 'https://img.icons8.com/color/96/open-book--v1.png',
    ),
    FocusOption(
      title: 'Screen discipline',
      icon: Icons.phonelink_lock_rounded,
      color: AppColors.navy,
      iconUrl: 'https://img.icons8.com/color/96/privacy.png',
    ),
    FocusOption(
      title: 'Recovery support',
      icon: Icons.shield_rounded,
      color: AppColors.success,
      iconUrl: 'https://img.icons8.com/color/96/shield.png',
    ),
    FocusOption(
      title: 'Anger control',
      icon: Icons.self_improvement_rounded,
      color: AppColors.support,
      iconUrl: 'https://img.icons8.com/color/96/meditation-guru.png',
    ),
    FocusOption(
      title: 'General accountability',
      icon: Icons.groups_rounded,
      color: AppColors.green,
      iconUrl: 'https://img.icons8.com/color/96/conference-call--v1.png',
    ),
    FocusOption(
      title: 'New believer growth',
      icon: Icons.spa_rounded,
      color: AppColors.gold,
      iconUrl: 'https://img.icons8.com/color/96/sprout.png',
    ),
  ];

  static const groups = [
    AccountabilityGroup(
      name: 'Men of Discipline',
      description:
          'A private weekly circle for prayer, honesty, screen discipline, and practical check-ins.',
      imageUrl: AppImages.group,
      type: 'Private',
      members: 142,
      online: 18,
      checkInRate: .82,
      tags: ['Men', 'Recovery', 'Prayer'],
      isPremium: false,
    ),
    AccountabilityGroup(
      name: 'Students Freedom Circle',
      description:
          'Campus support for study rhythm, temptation pressure, and spiritual consistency.',
      imageUrl: AppImages.study,
      type: 'Public',
      members: 284,
      online: 41,
      checkInRate: .76,
      tags: ['Students', 'Bible study', 'Youth'],
      isPremium: false,
    ),
    AccountabilityGroup(
      name: '21-Day Prayer Reset',
      description:
          'A guided challenge with devotion prompts, prayer wall, and group encouragement.',
      imageUrl: AppImages.praying,
      type: 'Premium',
      members: 96,
      online: 12,
      checkInRate: .89,
      tags: ['Prayer', 'Fasting', 'Challenge'],
      isPremium: true,
    ),
    AccountabilityGroup(
      name: 'Grace Chapel Youth',
      description:
          'Church-only space with moderators, announcements, check-ins, and helper assignment.',
      imageUrl: AppImages.chapel,
      type: 'Church-only',
      members: 210,
      online: 29,
      checkInRate: .71,
      tags: ['Church', 'Youth', 'Private'],
      isPremium: false,
    ),
  ];

  static const posts = [
    CommunityPost(
      type: 'Prayer Request',
      content:
          'Please pray for consistency this week. I want to keep my phone away during quiet time.',
      author: 'Anonymous member',
      isAnonymous: true,
      prayers: 42,
      comments: 8,
      reviewed: true,
    ),
    CommunityPost(
      type: 'Testimony',
      content:
          'Seven days of morning prayer today. Small steps, but I feel steadier and less isolated.',
      author: 'Nana K.',
      isAnonymous: false,
      prayers: 61,
      comments: 14,
      reviewed: false,
    ),
    CommunityPost(
      type: 'Struggle',
      content:
          'I had a hard evening. I logged it privately and reset with prayer instead of hiding.',
      author: 'Anonymous member',
      isAnonymous: true,
      prayers: 39,
      comments: 6,
      reviewed: true,
    ),
  ];

  static const helpers = [
    HelperProfile(
      name: 'Pastor Ama Mensah',
      photoUrl: AppImages.avatarOne,
      organization: 'Grace Harbor Church',
      focusAreas: ['Prayer discipline', 'Women', 'New believers'],
      rating: 4.9,
      price: 'Free intro',
      availability: 'Today, 6:30 PM',
      bio:
          'Ama mentors young adults through prayer rhythms, accountability groups, and gentle habit recovery plans rooted in Scripture.',
      languages: ['English', 'Twi'],
      isFreeAvailable: true,
    ),
    HelperProfile(
      name: 'Daniel Owusu',
      photoUrl: AppImages.avatarTwo,
      organization: 'Renewal Recovery Network',
      focusAreas: ['Screen discipline', 'Men', 'Recovery support'],
      rating: 4.8,
      price: 'GHS 60/session',
      availability: 'Tomorrow, 8:00 PM',
      bio:
          'Daniel supports men with weekly check-ins, relapse reflection, and structured recovery plans without shame.',
      languages: ['English', 'Ga'],
      isFreeAvailable: false,
    ),
    HelperProfile(
      name: 'Esi Boateng',
      photoUrl: AppImages.avatarThree,
      organization: 'Campus Fellowship',
      focusAreas: ['Students', 'Bible study', 'Anger control'],
      rating: 4.7,
      price: 'GHS 35/session',
      availability: 'Friday, 5:00 PM',
      bio:
          'Esi works with students on spiritual discipline, emotional regulation, and community-based accountability.',
      languages: ['English'],
      isFreeAvailable: true,
    ),
  ];
}
