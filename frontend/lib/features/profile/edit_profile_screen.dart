import 'package:flutter/material.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const TextField(
            maxLines: 3,
            maxLength: 150,
            decoration: InputDecoration(
              labelText: 'Tiểu sử',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const FilledButton(onPressed: null, child: Text('Lưu')),
        ],
      ),
    ),
  );
}
