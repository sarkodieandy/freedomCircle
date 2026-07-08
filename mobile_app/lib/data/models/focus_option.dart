import 'package:flutter/material.dart';

class FocusOption {
  const FocusOption({
    required this.title,
    required this.icon,
    required this.color,
    this.iconUrl,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String? iconUrl;
}
