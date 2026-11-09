import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:clone_facebook/core/router/route_names.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Trang cá nhân')),
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
          const SizedBox(height: 12),
          Text(userId == 'me' ? 'Trang cá nhân của bạn' : 'Người dùng $userId'),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.push(AppRoutePaths.profileEdit),
            child: const Text('Chỉnh sửa hồ sơ'),
          ),
        ])),
      );
}
