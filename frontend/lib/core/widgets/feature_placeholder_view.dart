import 'package:flutter/material.dart';

/// Small shared layout for screens whose full feature UI is not present yet.
class FeaturePlaceholderView extends StatelessWidget {
  const FeaturePlaceholderView({
    super.key,
    required this.title,
    required this.icon,
    this.message,
  });

  final String title;
  final IconData icon;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(message ?? title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
