import 'model_helpers.dart';

class PrayerLog {
  const PrayerLog({
    required this.id,
    required this.durationMinutes,
    required this.logDate,
    this.prayerTopic,
    this.note,
    this.isPrivate = true,
  });

  final String id;
  final int durationMinutes;
  final DateTime logDate;
  final String? prayerTopic;
  final String? note;
  final bool isPrivate;

  factory PrayerLog.fromMap(JsonMap map) {
    return PrayerLog(
      id: readString(map, 'id'),
      durationMinutes: readInt(map, 'duration_minutes'),
      logDate: readDateTime(map, 'log_date', fallback: DateTime.now()),
      prayerTopic: readNullableString(map, 'prayer_topic'),
      note: readNullableString(map, 'note'),
      isPrivate: readBool(map, 'is_private', fallback: true),
    );
  }
}

class FastingLog {
  const FastingLog({
    required this.id,
    required this.completed,
    required this.createdAt,
    this.fastType,
    this.startedAt,
    this.endedAt,
    this.targetHours,
    this.note,
  });

  final String id;
  final bool completed;
  final DateTime createdAt;
  final String? fastType;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final num? targetHours;
  final String? note;

  factory FastingLog.fromMap(JsonMap map) {
    return FastingLog(
      id: readString(map, 'id'),
      completed: readBool(map, 'completed'),
      createdAt: readDateTime(map, 'created_at', fallback: DateTime.now()),
      fastType: readNullableString(map, 'fast_type'),
      startedAt: DateTime.tryParse(readString(map, 'started_at')),
      endedAt: DateTime.tryParse(readString(map, 'ended_at')),
      targetHours: map['target_hours'] is num
          ? map['target_hours'] as num
          : null,
      note: readNullableString(map, 'note'),
    );
  }
}

class BibleStudyLog {
  const BibleStudyLog({
    required this.id,
    required this.completed,
    required this.logDate,
    this.book,
    this.chapterStart,
    this.chapterEnd,
    this.verseReference,
    this.note,
  });

  final String id;
  final bool completed;
  final DateTime logDate;
  final String? book;
  final int? chapterStart;
  final int? chapterEnd;
  final String? verseReference;
  final String? note;

  factory BibleStudyLog.fromMap(JsonMap map) {
    return BibleStudyLog(
      id: readString(map, 'id'),
      completed: readBool(map, 'completed', fallback: true),
      logDate: readDateTime(map, 'log_date', fallback: DateTime.now()),
      book: readNullableString(map, 'book'),
      chapterStart: map['chapter_start'] == null
          ? null
          : readInt(map, 'chapter_start'),
      chapterEnd: map['chapter_end'] == null
          ? null
          : readInt(map, 'chapter_end'),
      verseReference: readNullableString(map, 'verse_reference'),
      note: readNullableString(map, 'note'),
    );
  }
}

class DailyCheckin {
  const DailyCheckin({
    required this.id,
    required this.checkinDate,
    this.mood,
    this.struggleIntensity,
    this.prayerCompleted = false,
    this.bibleStudyCompleted = false,
    this.fastingCompleted = false,
    this.recoveryStatus,
    this.privateNote,
  });

  final String id;
  final DateTime checkinDate;
  final String? mood;
  final int? struggleIntensity;
  final bool prayerCompleted;
  final bool bibleStudyCompleted;
  final bool fastingCompleted;
  final String? recoveryStatus;
  final String? privateNote;

  factory DailyCheckin.fromMap(JsonMap map) {
    return DailyCheckin(
      id: readString(map, 'id'),
      checkinDate: readDateTime(map, 'checkin_date', fallback: DateTime.now()),
      mood: readNullableString(map, 'mood'),
      struggleIntensity: map['struggle_intensity'] == null
          ? null
          : readInt(map, 'struggle_intensity'),
      prayerCompleted: readBool(map, 'prayer_completed'),
      bibleStudyCompleted: readBool(map, 'bible_study_completed'),
      fastingCompleted: readBool(map, 'fasting_completed'),
      recoveryStatus: readNullableString(map, 'recovery_status'),
      privateNote: readNullableString(map, 'private_note'),
    );
  }
}
