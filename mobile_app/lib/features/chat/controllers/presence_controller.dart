import 'package:flutter/foundation.dart';

class PresenceController extends ChangeNotifier {
  int onlineCount = 0;
  String typingLabel = '';

  void updateOnlineCount(int value) {
    onlineCount = value;
    notifyListeners();
  }

  void showTyping(String label) {
    typingLabel = label;
    notifyListeners();
  }

  void clearTyping() {
    typingLabel = '';
    notifyListeners();
  }
}
