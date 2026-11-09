import 'package:flutter/material.dart';

class EditPostPage extends StatelessWidget {
  const EditPostPage({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Chỉnh sửa bài viết')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Nội dung bài viết',
                helperText: 'Mã bài viết: $postId',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const FilledButton(onPressed: null, child: Text('Lưu thay đổi')),
          ]),
        ),
      );
}
