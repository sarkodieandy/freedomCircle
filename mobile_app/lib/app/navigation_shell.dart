import 'package:flutter/material.dart';

import '../features/home/freedom_shell.dart';

class NavigationShell extends StatelessWidget {
  const NavigationShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return FreedomShell(initialTab: initialTab);
  }
}
