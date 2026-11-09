import 'package:flutter/material.dart';

class PeopleSearchPage extends StatelessWidget {
  const PeopleSearchPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Tìm bạn bè')),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Nhập tên để tìm kiếm',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      );
}
