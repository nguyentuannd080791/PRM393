import 'package:flutter/material.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tạo bài viết')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Bạn đang nghĩ gì?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _controller.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Đăng'),
            ),
          ),
        ],
      ),
    ),
  );
}

class EditPostPage extends StatelessWidget {
  const EditPostPage({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chỉnh sửa bài viết')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: 'Nội dung bài viết',
              helperText: 'Mã bài viết: $postId',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const FilledButton(onPressed: null, child: Text('Lưu thay đổi')),
        ],
      ),
    ),
  );
}
