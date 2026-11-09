import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:clone_facebook/app/route_names.dart';

class HomeFeedScreen extends StatelessWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bảng tin')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.dynamic_feed_outlined, size: 56),
          const SizedBox(height: 12),
          const Text('Bảng tin của bạn'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.push(AppRoutePaths.createPost),
            icon: const Icon(Icons.add),
            label: const Text('Tạo bài viết'),
          ),
        ],
      ),
    ),
  );
}
