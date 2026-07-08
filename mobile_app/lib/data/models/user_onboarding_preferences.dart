class UserOnboardingPreferences {
  const UserOnboardingPreferences({
    required this.userId,
    this.focusArea,
    this.privacyLevel,
    this.goalDurationDays,
    this.reminderTime,
    this.wantsGroup = false,
    this.wantsHelper = false,
  });

  final String userId;
  final String? focusArea;
  final String? privacyLevel;
  final int? goalDurationDays;
  final String? reminderTime;
  final bool wantsGroup;
  final bool wantsHelper;

  factory UserOnboardingPreferences.fromJson(Map<String, dynamic> json) {
    return UserOnboardingPreferences(
      userId: (json['user_id'] as String?) ?? '',
      focusArea: json['focus_area'] as String?,
      privacyLevel: json['privacy_level'] as String?,
      goalDurationDays: (json['goal_duration_days'] as num?)?.toInt(),
      reminderTime: json['reminder_time'] as String?,
      wantsGroup: (json['wants_group'] as bool?) ?? false,
      wantsHelper: (json['wants_helper'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'focus_area': focusArea,
    'privacy_level': privacyLevel,
    'goal_duration_days': goalDurationDays,
    'reminder_time': reminderTime,
    'wants_group': wantsGroup,
    'wants_helper': wantsHelper,
  };

  UserOnboardingPreferences copyWith({
    String? userId,
    String? focusArea,
    String? privacyLevel,
    int? goalDurationDays,
    String? reminderTime,
    bool? wantsGroup,
    bool? wantsHelper,
  }) {
    return UserOnboardingPreferences(
      userId: userId ?? this.userId,
      focusArea: focusArea ?? this.focusArea,
      privacyLevel: privacyLevel ?? this.privacyLevel,
      goalDurationDays: goalDurationDays ?? this.goalDurationDays,
      reminderTime: reminderTime ?? this.reminderTime,
      wantsGroup: wantsGroup ?? this.wantsGroup,
      wantsHelper: wantsHelper ?? this.wantsHelper,
    );
  }
}
