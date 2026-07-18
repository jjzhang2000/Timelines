import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared_preferences_provider.dart';

part 'view_mode_provider.g.dart';

enum ViewMode { merged, compare }

class ViewModeState {
  final ViewMode mode;
  final List<String> compareSourceIds;

  const ViewModeState({
    this.mode = ViewMode.merged,
    this.compareSourceIds = const [],
  });

  ViewModeState copyWith({ViewMode? mode, List<String>? compareSourceIds}) {
    return ViewModeState(
      mode: mode ?? this.mode,
      compareSourceIds: compareSourceIds ?? this.compareSourceIds,
    );
  }
}

@riverpod
class ViewModeNotifier extends _$ViewModeNotifier {
  late final SharedPreferences _prefs;

  @override
  ViewModeState build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    return _loadPersistedState();
  }

  ViewModeState _loadPersistedState() {
    final modeStr = _prefs.getString('view_mode') ?? 'merged';
    final compareIds = _prefs.getStringList('compare_sources') ?? [];

    return ViewModeState(
      mode: ViewMode.values.firstWhere((e) => e.name == modeStr),
      compareSourceIds: compareIds,
    );
  }

  Future<void> setMode(ViewMode mode) async {
    state = state.copyWith(mode: mode);
    await _prefs.setString('view_mode', mode.name);
  }

  Future<void> setCompareSources(List<String> sourceIds) async {
    state = state.copyWith(compareSourceIds: sourceIds);
    await _prefs.setStringList('compare_sources', sourceIds);
  }
}
