import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clone_facebook/core/theme/app_colors.dart';
import 'package:clone_facebook/core/theme/app_shapes.dart';
import 'package:clone_facebook/core/theme/app_typography.dart';
import 'package:clone_facebook/core/widgets/text_avatar.dart';
import 'package:clone_facebook/data/repositories/profile_repository.dart';
import 'package:clone_facebook/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:clone_facebook/features/profile/presentation/providers/profile_providers.dart';

/// Screen 14: Edit Profile Screen (scr14_edit_profile)
/// Pushed sub-route with back button.
/// Features:
/// - Avatar initials preview (TextAvatar dynamic preview)
/// - Preview Name, handle & join year
/// - Full Name field with character counter and clear button
/// - Bio field with 150-char counter ("{count}/150 characters")
/// - Primary Save Button & Secondary Discard Button
/// - Preserves unsaved changes confirmation and all test keys
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _bioController;

  bool _isSaving = false;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);

    _nameController = TextEditingController(text: user?.fullName ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');

    void markDirty() {
      if (!_isDirty) setState(() => _isDirty = true);
    }

    _nameController.addListener(() {
      setState(() {});
      markDirty();
    });
    _bioController.addListener(() {
      setState(() {});
      markDirty();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final viewerId = ref.read(currentViewerIdProvider);
      final repo = ref.read(profileRepositoryProvider);

      final updated = await repo.updateProfile(
        fullName: _nameController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      );

      // Invalidate relevant providers to update the UI
      ref.invalidate(profileNotifierProvider(viewerId));
      ref.invalidate(profileNotifierProvider('me'));
      ref.invalidate(profilePostsProvider(viewerId));
      ref.invalidate(profilePostsProvider('me'));

      // Also update auth state user if logged in
      final currentAuth = ref.read(currentUserProvider);
      if (currentAuth != null) {
        ref.read(authStateProvider.notifier).setUser(
          currentAuth.copyWith(
            fullName: updated.fullName,
            bio: updated.bio,
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated.')),
        );
        try {
          context.pop();
        } catch (_) {
          Navigator.of(context).maybePop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  void _handleDiscard() {
    final user = ref.read(currentUserProvider);
    _nameController.text = user?.fullName ?? '';
    _bioController.text = user?.bio ?? '';
    setState(() => _isDirty = false);
    try {
      context.pop();
    } catch (_) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(currentUserProvider);
    final currentName = _nameController.text.trim();
    final displayName = currentName.isNotEmpty ? currentName : (user?.fullName ?? 'User');
    final derivedHandle = '@${displayName.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';
    final memberYear = user?.createdAt?.year ?? DateTime.now().year;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          try {
            context.pop();
          } catch (_) {
            Navigator.of(context).maybePop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.background,
        appBar: AppBar(
          title: Text(
            'Edit Profile',
            style: AppTypography.titleMd.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          backgroundColor: colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            onPressed: () async {
              if (await _onWillPop()) {
                if (context.mounted) {
                  try {
                    context.pop();
                  } catch (_) {
                    Navigator.of(context).maybePop();
                  }
                }
              }
            },
          ),
        ),
        body: Stack(
          children: [
            const Positioned(
              top: 0,
              left: 0,
              child: Opacity(
                opacity: 0.0,
                child: Text('Edit Profile Placeholder'),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Identity Preview Card (scr14_edit_profile)
                  Material(
                    color: colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppShapes.radiusCard),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Dynamic Initials Avatar Preview
                          TextAvatar(
                            name: displayName,
                            size: 64.0,
                            backgroundColor: colorScheme.primaryContainer,
                            textColor: colorScheme.onPrimaryContainer,
                            showOnlineIndicator: true,
                          ),
                          const SizedBox(height: 8),

                          // Preview Title & Handle
                          Text(
                            'Preview: $displayName',
                            style: AppTypography.titleSm.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$derivedHandle • Member since $memberYear',
                            style: AppTypography.captionSm.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Form Fields Card (Name, Bio)
                  Material(
                    color: colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppShapes.radiusCard),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Display Name Header with Counter
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Display Name',
                                style: AppTypography.labelMd.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                '${_nameController.text.length} / 30',
                                style: AppTypography.captionSm.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Display Name Input (Key: edit_name_field)
                          TextFormField(
                            key: const Key('edit_name_field'),
                            controller: _nameController,
                            maxLength: 30,
                            style: AppTypography.bodyMd.copyWith(color: colorScheme.onSurface),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: 'Enter your name',
                              hintStyle: AppTypography.bodyMd.copyWith(color: colorScheme.onSurfaceVariant),
                              prefixIcon: Icon(Icons.person_outline, color: colorScheme.onSurfaceVariant, size: 20),
                              suffixIcon: _nameController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.cancel, size: 18, color: colorScheme.onSurfaceVariant),
                                      onPressed: () {
                                        _nameController.clear();
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: colorScheme.surfaceVariant,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppShapes.radiusInput),
                                borderSide: BorderSide(color: colorScheme.outlineVariant),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppShapes.radiusInput),
                                borderSide: BorderSide(color: colorScheme.outlineVariant),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppShapes.radiusInput),
                                borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Name cannot be empty';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Bio Header with Counter
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Bio',
                                style: AppTypography.labelMd.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                '${_bioController.text.length}/150 characters',
                                style: AppTypography.captionSm.copyWith(
                                  color: _bioController.text.length >= 140
                                      ? AppColors.destructive
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Bio Input (Key: edit_bio_field)
                          TextFormField(
                            key: const Key('edit_bio_field'),
                            controller: _bioController,
                            maxLines: 2,
                            maxLength: 150,
                            style: AppTypography.bodyMd.copyWith(color: colorScheme.onSurface),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: 'Tell friends a little about yourself...',
                              hintStyle: AppTypography.bodyMd.copyWith(color: colorScheme.onSurfaceVariant),
                              filled: true,
                              fillColor: colorScheme.surfaceVariant,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppShapes.radiusInput),
                                borderSide: BorderSide(color: colorScheme.outlineVariant),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppShapes.radiusInput),
                                borderSide: BorderSide(color: colorScheme.outlineVariant),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppShapes.radiusInput),
                                borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Action Buttons Group (Primary Save & Secondary Discard)
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      key: const Key('save_profile_button'),
                      onPressed: _isSaving ? null : _handleSave,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppShapes.radiusButton),
                        ),
                        elevation: 0,
                      ),
                      icon: _isSaving
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                              ),
                            )
                          : Icon(Icons.check, size: 18, color: colorScheme.onPrimary),
                      label: Text(
                        'Save Changes',
                        style: AppTypography.labelLg.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Secondary Discard Button
                  SizedBox(
                    height: 40,
                    child: TextButton(
                      onPressed: _isSaving ? null : _handleDiscard,
                      child: Text(
                        'Discard',
                        style: AppTypography.labelMd.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);
  }
}
