import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared_preferences_provider.dart';

part 'filter_provider.g.dart';

class FilterState {
  final Map<String, bool> sourceVisibility;

  const FilterState({this.sourceVisibility = const {}});

  FilterState copyWith({Map<String, bool>? sourceVisibility}) {
    return FilterState(
      sourceVisibility: sourceVisibility ?? this.sourceVisibility,
    );
  }

  bool isVisible(String sourceId) => sourceVisibility[sourceId] ?? true;
}

@riverpod
class FilterNotifier extends _$FilterNotifier {
  late final SharedPreferences _prefs;

  @override
  FilterState build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    _loadPersistedState();
    return const FilterState();
  }

  void _loadPersistedState() {
    final json = _prefs.getString('filter_state');
    if (json != null) {
      final map = Map<String, bool>.from(jsonDecode(json));
      state = FilterState(sourceVisibility: map);
    }
  }

  Future<void> _persistState() async {
    final json = jsonEncode(state.sourceVisibility);
    await _prefs.setString('filter_state', json);
  }

  void toggleSource(String sourceId) {
    final current = state.isVisible(sourceId);
    state = state.copyWith(
      sourceVisibility: {...state.sourceVisibility, sourceId: !current},
    );
    _persistState();
  }

  void selectAll() {
    final map = Map<String, bool>.from(state.sourceVisibility);
    for (final key in map.keys) {
      map[key] = true;
    }
    state = FilterState(sourceVisibility: map);
    _persistState();
  }

  void deselectAll() {
    final map = Map<String, bool>.from(state.sourceVisibility);
    for (final key in map.keys) {
      map[key] = false;
    }
    state = FilterState(sourceVisibility: map);
    _persistState();
  }

  void initializeSources(List<String> sourceIds) {
    final map = Map<String, bool>.from(state.sourceVisibility);
    for (final id in sourceIds) {
      map.putIfAbsent(id, () => true);
    }
    state = FilterState(sourceVisibility: map);
  }
}
