import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/timeline_source.dart';
import '../services/data_loader.dart';

part 'data_source_provider.g.dart';

enum LoadingStatus { initial, loading, success, error }

class DataSourceState {
  final List<TimelineSource> sources;
  final LoadingStatus status;
  final String? errorMessage;
  final List<String> failedFiles;

  const DataSourceState({
    this.sources = const [],
    this.status = LoadingStatus.initial,
    this.errorMessage,
    this.failedFiles = const [],
  });

  DataSourceState copyWith({
    List<TimelineSource>? sources,
    LoadingStatus? status,
    String? errorMessage,
    List<String>? failedFiles,
  }) {
    return DataSourceState(
      sources: sources ?? this.sources,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      failedFiles: failedFiles ?? this.failedFiles,
    );
  }

  factory DataSourceState.initial() => const DataSourceState();
  factory DataSourceState.loading() =>
      const DataSourceState(status: LoadingStatus.loading);
  factory DataSourceState.success(
    List<TimelineSource> sources, {
    List<String>? failedFiles,
  }) => DataSourceState(
    sources: sources,
    status: LoadingStatus.success,
    failedFiles: failedFiles ?? [],
  );
  factory DataSourceState.error(String message, {List<String>? failedFiles}) =>
      DataSourceState(
        errorMessage: message,
        status: LoadingStatus.error,
        failedFiles: failedFiles ?? [],
      );
}

@riverpod
class DataSourceNotifier extends _$DataSourceNotifier {
  @override
  DataSourceState build() => DataSourceState.initial();

  Future<void> loadSources() async {
    state = DataSourceState.loading();

    try {
      final service = DataLoaderService(dataDirectory: 'data');

      final sources = await service.discoverSources();
      state = DataSourceState.success(sources);
    } catch (e) {
      state = DataSourceState.error(e.toString());
    }
  }

  void addSource(TimelineSource source) {
    state = state.copyWith(sources: [...state.sources, source]);
  }

  void removeSource(String sourceId) {
    state = state.copyWith(
      sources: state.sources.where((s) => s.id != sourceId).toList(),
    );
  }
}
