import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/notification_preferences.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final NotificationRepository _repository = const NotificationRepository();
  late Future<NotificationPreferences> _future;
  NotificationPreferences? _preferences;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _repository.getPreferences();
  }

  Future<void> _save() async {
    final preferences = _preferences;
    if (preferences == null) return;
    setState(() => _saving = true);
    await _repository.updatePreferences(preferences);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification preferences saved')),
    );
  }

  void _update(NotificationPreferences preferences) {
    setState(() => _preferences = preferences);
  }

  Future<void> _pickQuietHour({required bool start}) async {
    final preferences = _preferences;
    if (preferences == null) return;

    final initial = _parseTime(
      start ? preferences.quietHoursStart : preferences.quietHoursEnd,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;

    final value = _formatTime(picked);
    _update(
      preferences.copyWith(
        quietHoursStart: start ? value : null,
        quietHoursEnd: start ? null : value,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      title: 'Notification Preferences',
      subtitle: 'Choose what reaches you and when push alerts stay quiet.',
      withBack: true,
      children: [
        FutureBuilder<NotificationPreferences>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ErrorRetryCard(
                title: 'Could not load preferences',
                body: snapshot.error.toString(),
                onRetry: () => setState(() {
                  _future = _repository.getPreferences();
                }),
              );
            }

            _preferences ??= snapshot.data;
            final preferences = _preferences!;

            return Column(
              children: [
                AppCard(
                  child: Column(
                    children: [
                      _SwitchRow(
                        title: 'Group messages',
                        value: preferences.groupMessages,
                        onChanged: (value) =>
                            _update(preferences.copyWith(groupMessages: value)),
                      ),
                      _SwitchRow(
                        title: 'Prayer requests',
                        value: preferences.prayerRequests,
                        onChanged: (value) => _update(
                          preferences.copyWith(prayerRequests: value),
                        ),
                      ),
                      _SwitchRow(
                        title: 'Community replies',
                        value: preferences.communityReplies,
                        onChanged: (value) => _update(
                          preferences.copyWith(communityReplies: value),
                        ),
                      ),
                      _SwitchRow(
                        title: 'Helper messages',
                        value: preferences.helperMessages,
                        onChanged: (value) => _update(
                          preferences.copyWith(helperMessages: value),
                        ),
                      ),
                      _SwitchRow(
                        title: 'Booking updates',
                        value: preferences.bookingUpdates,
                        onChanged: (value) => _update(
                          preferences.copyWith(bookingUpdates: value),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    children: [
                      _SwitchRow(
                        title: 'Recovery reminders',
                        value: preferences.recoveryReminders,
                        onChanged: (value) => _update(
                          preferences.copyWith(recoveryReminders: value),
                        ),
                      ),
                      _SwitchRow(
                        title: 'Quiet Time reminders',
                        value: preferences.quietTimeReminders,
                        onChanged: (value) => _update(
                          preferences.copyWith(quietTimeReminders: value),
                        ),
                      ),
                      _SwitchRow(
                        title: 'Fasting reminders',
                        value: preferences.fastingReminders,
                        onChanged: (value) => _update(
                          preferences.copyWith(fastingReminders: value),
                        ),
                      ),
                      _SwitchRow(
                        title: 'Subscription alerts',
                        value: preferences.subscriptionAlerts,
                        onChanged: (value) => _update(
                          preferences.copyWith(subscriptionAlerts: value),
                        ),
                      ),
                      _SwitchRow(
                        title: 'Church announcements',
                        value: preferences.churchAnnouncements,
                        onChanged: (value) => _update(
                          preferences.copyWith(churchAnnouncements: value),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(title: 'Delivery'),
                      _SwitchRow(
                        title: 'Push notifications',
                        value: preferences.pushEnabled,
                        onChanged: (value) =>
                            _update(preferences.copyWith(pushEnabled: value)),
                      ),
                      _SwitchRow(
                        title: 'Email notifications',
                        value: preferences.emailEnabled,
                        onChanged: (value) =>
                            _update(preferences.copyWith(emailEnabled: value)),
                      ),
                      _SwitchRow(
                        title: 'Quiet hours',
                        value: preferences.quietHoursEnabled,
                        onChanged: (value) => _update(
                          preferences.copyWith(quietHoursEnabled: value),
                        ),
                      ),
                      if (preferences.quietHoursEnabled) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _TimeButton(
                                label: 'Start',
                                value:
                                    preferences.quietHoursStart ?? '21:00:00',
                                onTap: () => _pickQuietHour(start: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TimeButton(
                                label: 'End',
                                value: preferences.quietHoursEnd ?? '07:00:00',
                                onTap: () => _pickQuietHour(start: false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: _saving ? 'Saving...' : 'Save preferences',
                  icon: Icons.save_rounded,
                  onPressed: _saving ? () {} : _save,
                  color: AppColors.green,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  TimeOfDay _parseTime(String? value) {
    final parts = (value ?? '21:00:00').split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 21,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.green,
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.schedule_rounded),
      label: Text('$label ${value.substring(0, 5)}'),
    );
  }
}
