import 'package:flutter/material.dart';

enum QuietTimeMood {
  tempted,
  alone,
  needStrength,
  needPeace,
  reset,
  grateful,
  silence,
}

extension QuietTimeMoodX on QuietTimeMood {
  String get key => switch (this) {
    QuietTimeMood.tempted => 'tempted',
    QuietTimeMood.alone => 'alone',
    QuietTimeMood.needStrength => 'need_strength',
    QuietTimeMood.needPeace => 'need_peace',
    QuietTimeMood.reset => 'reset',
    QuietTimeMood.grateful => 'grateful',
    QuietTimeMood.silence => 'silence',
  };

  String get label => switch (this) {
    QuietTimeMood.tempted => 'I feel tempted',
    QuietTimeMood.alone => 'I feel alone',
    QuietTimeMood.needStrength => 'I need strength',
    QuietTimeMood.needPeace => 'I need peace',
    QuietTimeMood.reset => 'I want to reset',
    QuietTimeMood.grateful => 'I am grateful',
    QuietTimeMood.silence => 'I want silence',
  };

  IconData get icon => switch (this) {
    QuietTimeMood.tempted => Icons.shield_moon_outlined,
    QuietTimeMood.alone => Icons.self_improvement_rounded,
    QuietTimeMood.needStrength => Icons.fitness_center_rounded,
    QuietTimeMood.needPeace => Icons.spa_outlined,
    QuietTimeMood.reset => Icons.refresh_rounded,
    QuietTimeMood.grateful => Icons.volunteer_activism_rounded,
    QuietTimeMood.silence => Icons.nights_stay_outlined,
  };

  static QuietTimeMood fromKey(String raw) {
    return QuietTimeMood.values.firstWhere(
      (mood) => mood.key == raw,
      orElse: () => QuietTimeMood.needPeace,
    );
  }
}

class QuietTimeCategory {
  const QuietTimeCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.icon,
    required this.sortOrder,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String slug;
  final String description;
  final String icon;
  final int sortOrder;
  final bool isActive;
}

class QuietTimeStep {
  const QuietTimeStep({
    required this.id,
    required this.sessionId,
    required this.stepTitle,
    required this.stepType,
    required this.content,
    required this.durationSeconds,
    required this.sortOrder,
    this.scriptureReference,
  });

  final String id;
  final String sessionId;
  final String stepTitle;
  final String stepType;
  final String content;
  final String? scriptureReference;
  final int durationSeconds;
  final int sortOrder;
}

class QuietTimeSession {
  const QuietTimeSession({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.slug,
    required this.description,
    required this.durationMinutes,
    required this.isPremium,
    required this.isActive,
    required this.sortOrder,
    this.audioUrl,
    this.backgroundImageUrl,
    this.steps = const [],
  });

  final String id;
  final String categoryId;
  final String title;
  final String slug;
  final String description;
  final int durationMinutes;
  final String? audioUrl;
  final String? backgroundImageUrl;
  final bool isPremium;
  final bool isActive;
  final int sortOrder;
  final List<QuietTimeStep> steps;

  String get durationLabel => '$durationMinutes min';
}

class QuietTimeHistory {
  const QuietTimeHistory({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.durationCompletedSeconds,
    required this.completed,
    required this.sharedWithGroup,
    required this.createdAt,
    this.moodBefore,
    this.moodAfter,
    this.privateNote,
    this.sessionTitle,
  });

  final String id;
  final String userId;
  final String sessionId;
  final String? moodBefore;
  final String? moodAfter;
  final int durationCompletedSeconds;
  final bool completed;
  final String? privateNote;
  final bool sharedWithGroup;
  final DateTime createdAt;
  final String? sessionTitle;
}

class QuietTimeFavorite {
  const QuietTimeFavorite({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.createdAt,
    this.sessionTitle,
  });

  final String id;
  final String userId;
  final String sessionId;
  final DateTime createdAt;
  final String? sessionTitle;
}

class QuietTimeHistorySummary {
  const QuietTimeHistorySummary({
    required this.totalSessions,
    required this.totalMinutes,
    required this.currentStreak,
    required this.recentHistory,
    required this.favorites,
    required this.moodSummary,
  });

  final int totalSessions;
  final int totalMinutes;
  final int currentStreak;
  final List<QuietTimeHistory> recentHistory;
  final List<QuietTimeFavorite> favorites;
  final Map<String, int> moodSummary;
}
