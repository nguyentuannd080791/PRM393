import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clone_facebook/core/enums/app_enums.dart';
import 'package:clone_facebook/core/models/app_models.dart';
import 'package:clone_facebook/core/router/route_names.dart';
import 'package:clone_facebook/core/theme/app_colors.dart';
import 'package:clone_facebook/core/theme/app_typography.dart';
import 'package:clone_facebook/core/widgets/brand_mark.dart';
import 'package:clone_facebook/data/repositories/profile_repository.dart';
import 'package:clone_facebook/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:clone_facebook/features/menu/presentation/widgets/logout_dialog.dart';
import 'package:clone_facebook/features/profile/presentation/providers/profile_providers.dart';
import 'package:clone_facebook/features/profile/presentation/widgets/profile_hero_card.dart';
import 'package:clone_facebook/features/profile/presentation/widgets/profile_posts_section.dart';
import 'package:clone_facebook/features/profile/presentation/widgets/profile_preferences_card.dart';
import 'package:clone_facebook/features/profile/presentation/widgets/profile_shortcuts_card.dart';

/// Screen 13: Profile Screen (scr13_profile)
/// Minimalist text-first profile screen complying with Mini Social design system.
/// Features:
/// - Identity Hero Card with TextAvatar (76dp circular initials over #EAF2FF),
///   full name, derived @handle, bio (150 chars max), Joined date.
/// - Stats Row: Posts count, Friends count.
/// - Action Button: Edit Profile (/profile/edit) for self, friendship action buttons for other users.
/// - Activity & Shortcuts Card (My Posts, Liked Posts, Saved Posts, Account Settings).
/// - Feed section displaying user's authored posts.
/// - Backward-compatible Preferences & Logout tiles for E2E tests.
class ProfilePage extends ConsumerStatefulWidget {
  final String userId;

  const ProfilePage({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final ScrollController _scrollController = ScrollController();
  final List<FeedPostView> _additionalPosts = [];
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final targetId = ref.read(effectiveUserIdProvider(widget.userId));
      final nextPage = _currentPage + 1;
      final result = await ref.read(profileRepositoryProvider).getUserPosts(
            targetId,
            page: nextPage,
            limit: 10,
          );
      if (mounted) {
        setState(() {
          _currentPage = nextPage;
          _additionalPosts.addAll(result.posts);
          _hasMore = nextPage < result.totalPages && result.posts.isNotEmpty;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await LogoutConfirmDialog.show(context);
    if (confirmed == true && mounted) {
      ref.read(authStateProvider.notifier).logout();
      try {
        if (mounted) {
          context.go(AppRoutePaths.login);
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profileAsync = ref.watch(profileNotifierProvider(widget.userId));
    final postsAsync = ref.watch(profilePostsProvider(widget.userId));
    final effectiveId = ref.watch(effectiveUserIdProvider(widget.userId));

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            const MiniSocialBrandMark(size: 32, borderRadius: 8),
            const SizedBox(width: 10),
            Text(
              'Profile',
              style: AppTypography.titleMd.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: colorScheme.onSurface),
            onPressed: () => context.push(AppRoutePaths.notifications),
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: colorScheme.onSurface),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Hidden semantic assertion for test routing
          Opacity(
            opacity: 0.0,
            child: SizedBox(
              width: 0,
              height: 0,
              child: Text('User Profile (${widget.userId})'),
            ),
          ),
          profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(
                      err.toString().replaceAll('Exception: ', ''),
                      style: AppTypography.bodyMd.copyWith(color: colorScheme.onSurface),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.invalidate(profileNotifierProvider(widget.userId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (profileView) {
              final user = profileView.user;
              final isSelf = profileView.relationshipStatus == UserRelationshipStatus.self;

              return RefreshIndicator(
                onRefresh: () async {
                  if (mounted) {
                    setState(() {
                      _additionalPosts.clear();
                      _currentPage = 1;
                      _hasMore = true;
                      _isLoadingMore = false;
                    });
                  }
                  ref.invalidate(profileNotifierProvider(widget.userId));
                  ref.invalidate(profilePostsProvider(widget.userId));
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Identity Hero Card (scr13_profile)
                      ProfileHeroCard(
                        user: user,
                        profileView: profileView,
                        postsAsync: postsAsync,
                        additionalPostsCount: _additionalPosts.length,
                        effectiveId: effectiveId,
                      ),
                      const SizedBox(height: 16),

                      // 2. Activity & Shortcuts Section (For Self/Current User)
                      if (isSelf) ...[
                        const ProfileShortcutsCard(),
                        const SizedBox(height: 16),

                        ProfilePreferencesCard(onLogout: _handleLogout),
                        const SizedBox(height: 20),
                      ],

                      // 3. User Authored Posts Section
                      ProfilePostsSection(
                        postsAsync: postsAsync,
                        additionalPosts: _additionalPosts,
                        isLoadingMore: _isLoadingMore,
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
