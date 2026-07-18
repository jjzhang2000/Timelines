import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/timeline_entry.dart';
import 'data_source_provider.dart';
import 'filter_provider.dart';

part 'timeline_provider.g.dart';

class TimelineState {
  final List<TimelineEntry> entries;
  final int? selectedEntryIndex;

  const TimelineState({this.entries = const [], this.selectedEntryIndex});

  TimelineState copyWith({
    List<TimelineEntry>? entries,
    int? selectedEntryIndex,
  }) {
    return TimelineState(
      entries: entries ?? this.entries,
      selectedEntryIndex: selectedEntryIndex ?? this.selectedEntryIndex,
    );
  }
}

@riverpod
class TimelineNotifier extends _$TimelineNotifier {
  @override
  TimelineState build() {
    final dataSourceState = ref.watch(dataSourceNotifierProvider);
    final filterState = ref.watch(filterNotifierProvider);

    if (dataSourceState.status != LoadingStatus.success) {
      return const TimelineState();
    }

    final entries = <TimelineEntry>[];
    for (final source in dataSourceState.sources) {
      if (filterState.isVisible(source.id)) {
        entries.addAll(source.events);
      }
    }

    entries.sort((a, b) => a.date.compareTo(b.date));

    return TimelineState(entries: entries);
  }

  void selectEntry(int index) {
    state = state.copyWith(selectedEntryIndex: index);
  }

  void clearSelection() {
    state = state.copyWith(selectedEntryIndex: null);
  }
}
