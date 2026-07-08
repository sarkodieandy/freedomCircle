import 'package:flutter/material.dart';

import '../animations/fade_slide_in.dart';

class ScreenShell extends StatelessWidget {
  const ScreenShell({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.trailing,
    this.withBack = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? trailing;
  final bool withBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: withBack
          ? AppBar(
              title: Text(title),
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            )
          : null,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, withBack ? 4 : 20, 20, 104),
          children: [
            if (!withBack)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              )
            else if (subtitle != null)
              Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
            SizedBox(height: withBack ? 16 : 22),
            for (var i = 0; i < children.length; i++)
              FadeSlideIn(
                delay: Duration(milliseconds: i * 32),
                child: children[i],
              ),
          ],
        ),
      ),
    );
  }
}
