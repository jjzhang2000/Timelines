import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/timeline_entry.dart';
import '../services/search_manager.dart';
import 'data_source_provider.dart';

part 'search_provider.g.dart';

final searchManagerProvider = Provider<SearchManager>((ref) {
  return SearchManager();
});

class SearchState {
  final String query;
  final List<TimelineEntry> results;
  final List<String> suggestions;
  final bool isSearching;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.suggestions = const [],
    this.isSearching = false,
  });

  SearchState copyWith({
    String? query,
    List<TimelineEntry>? results,
    List<String>? suggestions,
    bool? isSearching,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      suggestions: suggestions ?? this.suggestions,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

@riverpod
class SearchNotifier extends _$SearchNotifier {
  late final SearchManager _searchManager;
  Timer? _debounceTimer;

  @override
  SearchState build() {
    _searchManager = ref.watch(searchManagerProvider);
    ref.onDispose(() => _debounceTimer?.cancel());
    return const SearchState();
  }

  void updateQuery(String query) {
    state = state.copyWith(query: query, isSearching: true);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      state = const SearchState();
      return;
    }

    final dataSourceState = ref.read(dataSourceNotifierProvider);
    if (dataSourceState.status == LoadingStatus.success) {
      await _searchManager.buildIndex(dataSourceState.sources);
    }

    final results = await _searchManager.search(query);
    final suggestions = await _searchManager.getSuggestions(query);

    state = SearchState(
      query: query,
      results: results,
      suggestions: suggestions,
      isSearching: false,
    );
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    state = const SearchState();
  }
}
