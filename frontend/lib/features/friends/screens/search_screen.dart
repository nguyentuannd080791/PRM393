import 'package:clone_facebook/core/widgets/loading_view.dart';
import 'package:clone_facebook/core/widgets/user_avatar.dart';

import '../widgets/user_result_card.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clone_facebook/app/route_names.dart';

import '../repositories/search_repository.dart';
import '../models/user_result.dart';
import '../providers/search_provider.dart';
import '../widgets/friends_ui.dart';

/// SCR10: People and text-post results remain on the same screen.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _query;
  @override
  void initState() {
    super.initState();
    _query = TextEditingController(text: ref.read(member4SearchProvider).query);
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(member4SearchProvider);
    final notifier = ref.read(member4SearchProvider.notifier);
    return Member4Scaffold(
      title: 'Search',
      body: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            TextField(
              controller: _query,
              maxLength: 100,
              onChanged: notifier.setQuery,
              decoration: InputDecoration(
                hintText: 'Search people or thoughts...',
                counterText: '',
                prefixIcon: const Icon(Icons.search, color: socialBlue),
                suffixIcon: state.query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _query.clear();
                          notifier.setQuery('');
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            SocialSegments(
              labels: const ['People', 'Posts'],
              selected: state.kind.index,
              onSelected: (index) =>
                  notifier.selectKind(SearchKind.values[index]),
            ),
            const SizedBox(height: 20),
            if (state.query.trim().isEmpty)
              const SocialMessage(
                'Search names or text posts to find your community.',
                icon: Icons.search,
              )
            else
              state.results.when(
                loading: () => const LoadingView(),
                error: (error, _) => SocialMessage(
                  error.toString(),
                  icon: Icons.cloud_off,
                  onRetry: notifier.refresh,
                ),
                data: (results) {
                  if (results.total == 0) {
                    return const SocialMessage(
                      'No results found. Try another keyword.',
                      icon: Icons.search_off,
                    );
                  }
                  return Column(
                    children: [
                      if (state.kind == SearchKind.people)
                        for (final person in results.people)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: UserResultCard(person),
                          )
                      else
                        for (final post in results.posts)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PostResult(post),
                          ),
                      const SizedBox(height: 8),
                      Text(
                        '${results.total} ${state.kind == SearchKind.people ? (results.total == 1 ? 'person' : 'people') : (results.total == 1 ? 'post' : 'posts')} found for “${state.query.trim()}”',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: socialMuted,
                          fontSize: 13,
                        ),
                      ),
                      if (results.hasMore)
                        TextButton(
                          onPressed: state.loadingMore
                              ? null
                              : notifier.loadMore,
                          child: state.loadingMore
                              ? const ActionSpinner()
                              : const Text('Load more'),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _PostResult extends ConsumerWidget {
  const _PostResult(this.post);
  final SearchPost post;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailPath = ref.watch(postDetailPathBuilderProvider);
    return SocialCard(
      child: InkWell(
        onTap: detailPath == null
            ? null
            : () => context.push(detailPath(post.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () =>
                  context.push(AppRoutePaths.profilePath(post.author.id)),
              child: Row(
                children: [
                  UserAvatar(post.author.name, radius: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      post.author.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    requestTime(post.createdAt),
                    style: const TextStyle(color: socialMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              post.content,
              style: const TextStyle(fontSize: 15, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
