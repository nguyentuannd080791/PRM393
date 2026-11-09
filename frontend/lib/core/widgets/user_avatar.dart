import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar(this.name, {super.key, this.radius = 24});
  final String name;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    final initials = words.isEmpty
        ? '?'
        : '${words.first.characters.first}${words.length > 1 ? words.last.characters.first : ''}'
              .toUpperCase();
    const colors = [
      Color(0xFFE6EEFF),
      Color(0xFFDDE1FF),
      Color(0xFFFFDAD6),
      Color(0xFFDBE3F0),
    ];
    final index = name.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return CircleAvatar(
      radius: radius,
      backgroundColor: colors[index],
      child: Text(
        initials,
        style: TextStyle(
          color: const Color(0xFF0050CD),
          fontSize: radius * .75,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
