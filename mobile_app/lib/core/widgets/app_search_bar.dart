import 'package:flutter/material.dart';

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    required this.hintText,
    this.onChanged,
    this.onFilterTap,
  });

  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: onFilterTap == null
            ? null
            : IconButton(
                onPressed: onFilterTap,
                icon: const Icon(Icons.tune_rounded),
              ),
      ),
    );
  }
}
