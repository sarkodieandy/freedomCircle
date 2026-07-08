import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  int selectedTab = 0;
  String selectedFocus = 'Recovery support';
  String privacyLevel = 'Anonymous community';
  String goalLength = '21 days';
  String reminderTime = '8:00 PM';

  void selectTab(int index) {
    selectedTab = index;
    notifyListeners();
  }

  void saveSetup({
    required String focus,
    required String privacy,
    required String goal,
    required String reminder,
  }) {
    selectedFocus = focus;
    privacyLevel = privacy;
    goalLength = goal;
    reminderTime = reminder;
    notifyListeners();
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState super.notifier,
    required super.child,
  });

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope?.notifier != null, 'AppStateScope not found in widget tree.');
    return scope!.notifier!;
  }
}
