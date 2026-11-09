import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:clone_facebook/core/router/route_names.dart';

class FriendsTabPage extends StatelessWidget {
  const FriendsTabPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Bạn bè')),
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.people_outline, size: 56),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.push(AppRoutePaths.friendsSearch),
            child: const Text('Tìm bạn bè'),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutePaths.allFriends),
            child: const Text('Xem tất cả bạn bè'),
          ),
        ])),
      );
}
