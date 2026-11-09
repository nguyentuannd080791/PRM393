import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clone_facebook/core/router/route_names.dart';
import 'package:clone_facebook/core/theme/theme_provider.dart';
import 'package:clone_facebook/features/auth/presentation/providers/auth_state_provider.dart';

class MenuPage extends ConsumerWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: ListView(children: [
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('Trang cá nhân'),
          onTap: () => context.push(AppRoutePaths.profilePath('me')),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.dark_mode_outlined),
          title: const Text('Giao diện tối'),
          value: isDark,
          onChanged: (_) => ref.read(themeModeProvider.notifier).toggleTheme(),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Đăng xuất'),
          onTap: () async {
            await ref.read(authStateProvider.notifier).logout();
            if (context.mounted) context.go(AppRoutePaths.login);
          },
        ),
      ]),
    );
  }
}
