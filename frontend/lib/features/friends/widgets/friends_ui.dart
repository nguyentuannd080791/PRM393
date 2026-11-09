import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:clone_facebook/app/route_names.dart';

const socialBlue = Color(0xFF0866FF);
const socialInk = Color(0xFF182230);
const socialMuted = Color(0xFF667085);
const socialCanvas = Colors.white;
const socialTint = Color(0xFFE6EEFF);

ThemeData member4Theme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: socialBlue,
    brightness: Brightness.light,
  ).copyWith(primary: socialBlue, surface: Colors.white, onSurface: socialInk),
  scaffoldBackgroundColor: socialCanvas,
  appBarTheme: const AppBarTheme(
    backgroundColor: socialCanvas,
    foregroundColor: socialInk,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontSize: 14, color: socialInk, height: 1.45),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: socialInk,
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF0050CD),
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    hintStyle: const TextStyle(color: socialMuted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: socialBlue),
    ),
  ),
);

class Member4Scaffold extends StatelessWidget {
  const Member4Scaffold({
    super.key,
    required this.title,
    required this.body,
    this.brand = true,
  });
  final String title;
  final Widget body;
  final bool brand;

  @override
  Widget build(BuildContext context) => Theme(
    data: member4Theme(),
    child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: brand
            ? null
            : IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutePaths.friends),
              ),
        title: Row(
          children: [
            if (brand) ...[
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: socialBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'M',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: brand
            ? [
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: () => context.push(AppRoutePaths.notifications),
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: socialMuted,
                  ),
                ),
                IconButton(
                  tooltip: 'My profile',
                  onPressed: () => context.go(AppRoutePaths.ownProfile),
                  icon: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFF0050CD),
                    child: Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ]
            : null,
      ),
      body: SafeArea(top: false, child: body),
    ),
  );
}

class SocialCard extends StatelessWidget {
  const SocialCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE4EAF2)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08182230),
          offset: Offset(0, 2),
          blurRadius: 3,
        ),
      ],
    ),
    child: Material(type: MaterialType.transparency, child: child),
  );
}

class SocialSegments extends StatelessWidget {
  const SocialSegments({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: socialTint,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: List.generate(
        labels.length,
        (index) => Expanded(
          child: Semantics(
            selected: index == selected,
            button: true,
            child: Material(
              color: index == selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onSelected(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: index == selected
                          ? const Color(0xFF0050CD)
                          : socialMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class SocialMessage extends StatelessWidget {
  const SocialMessage(
    this.message, {
    super.key,
    this.onRetry,
    this.icon = Icons.people_outline,
  });
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: socialMuted, size: 36),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: socialMuted),
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}

class ActionSpinner extends StatelessWidget {
  const ActionSpinner({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 18,
    height: 18,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}

Future<void> socialAction(
  BuildContext context,
  Future<void> Function() action,
  String success,
) async {
  try {
    await action();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(success)));
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

String requestTime(DateTime date) {
  final age = DateTime.now().difference(date);
  if (age.inMinutes < 1) return 'Just now';
  if (age.inHours < 1) return '${age.inMinutes}m ago';
  if (age.inDays < 1) return '${age.inHours}h ago';
  if (age.inDays == 1) return 'Yesterday';
  return '${date.day}/${date.month}/${date.year}';
}

String friendSince(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return 'Friend since ${months[date.month - 1]} ${date.year}';
}
