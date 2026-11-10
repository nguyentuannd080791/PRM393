import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clone_facebook/app/route_names.dart';
import 'package:clone_facebook/features/auth/providers/auth_provider.dart';
import 'package:clone_facebook/features/auth/repositories/auth_repository.dart';
import 'package:clone_facebook/features/friends/widgets/friends_ui.dart';

/// SCR15: change password and log out from one page.
class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  // Same rule as the backend (validation.js PASSWORD_REGEX).
  static final _passwordRule = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$');

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _changePassword() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      _formKey.currentState!.reset();
      _current.clear();
      _next.clear();
      _confirm.clear();
      if (mounted) _toast('Changes saved successfully.');
    } catch (error) {
      if (mounted) _toast(error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(authStateProvider.notifier).logout();
    if (mounted) context.go(AppRoutePaths.login);
  }

  Widget _field(
    String label,
    TextEditingController controller,
    String? Function(String) validator,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      obscureText: true,
      enableSuggestions: false,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) => (value ?? '').isEmpty
          ? 'Please enter the required information.'
          : validator(value!),
    ),
  );

  @override
  Widget build(BuildContext context) => Member4Scaffold(
    title: 'Account Settings',
    brand: false,
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SocialCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Change Password',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                _field('Current Password', _current, (_) => null),
                _field(
                  'New Password',
                  _next,
                  (value) => !_passwordRule.hasMatch(value)
                      ? 'At least 8 characters with a letter and a number.'
                      : value == _current.text
                      ? 'New password must differ from the current one.'
                      : null,
                ),
                _field(
                  'Confirm New Password',
                  _confirm,
                  (value) =>
                      value != _next.text ? 'Passwords do not match.' : null,
                ),
                const SizedBox(height: 4),
                FilledButton(
                  onPressed: _saving ? null : _changePassword,
                  child: _saving
                      ? const ActionSpinner()
                      : const Text('Change Password'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SocialCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Log Out',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            onTap: _logout,
          ),
        ),
      ],
    ),
  );
}
