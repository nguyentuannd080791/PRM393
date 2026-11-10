import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clone_facebook/features/auth/providers/auth_provider.dart';

import '../repositories/search_repository.dart';
import '../models/user_result.dart';

class Member4SearchState {
  const Member4SearchState({
    this.query = '',
    this.kind = SearchKind.people,
    this.results = const AsyncData(SearchResults()),
    this.loadingMore = false,
  });
  final String query;
  final SearchKind kind;
  final AsyncValue<SearchResults> results;
  final bool loadingMore;
}

class Member4Search extends Notifier<Member4SearchState> {
  Timer? _debounce;
  int _generation = 0;

  @override
  Member4SearchState build() {
    ref.watch(sessionUserIdProvider);
    _generation++;
    ref.onDispose(() {
      _debounce?.cancel();
      _generation++;
    });
    return const Member4SearchState();
  }

  void setQuery(String query) => _schedule(query, state.kind);
  void selectKind(SearchKind kind) => _schedule(state.query, kind);

  void _schedule(String query, SearchKind kind) {
    _debounce?.cancel();
    final generation = ++_generation;
    final empty = query.trim().isEmpty;
    state = Member4SearchState(
      query: query,
      kind: kind,
      results: empty ? const AsyncData(SearchResults()) : const AsyncLoading(),
    );
    if (!empty) {
      _debounce = Timer(
        const Duration(milliseconds: 350),
        () => _fetch(generation, query, kind),
      );
    }
  }

  Future<void> _fetch(
    int generation,
    String query,
    SearchKind kind, {
    bool more = false,
  }) async {
    final previous = state.results.asData?.value;
    try {
      final result = await ref
          .read(searchRepositoryProvider)
          .search(
            query.trim(),
            kind,
            page: more ? (previous?.page ?? 0) + 1 : 1,
          );
      if (!ref.mounted || generation != _generation) return;
      state = Member4SearchState(
        query: query,
        kind: kind,
        results: AsyncData(
          more && previous != null ? previous.append(result) : result,
        ),
      );
    } catch (error, stack) {
      if (!ref.mounted || generation != _generation) return;
      state = Member4SearchState(
        query: query,
        kind: kind,
        results: AsyncError(error, stack),
      );
    }
  }

  Future<void> refresh() async {
    _debounce?.cancel();
    final generation = ++_generation;
    if (state.query.trim().isNotEmpty) {
      await _fetch(generation, state.query, state.kind);
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !(state.results.asData?.value.hasMore ?? false)) {
      return;
    }
    state = Member4SearchState(
      query: state.query,
      kind: state.kind,
      results: state.results,
      loadingMore: true,
    );
    await _fetch(_generation, state.query, state.kind, more: true);
  }
}

final member4SearchProvider =
    NotifierProvider<Member4Search, Member4SearchState>(Member4Search.new);
