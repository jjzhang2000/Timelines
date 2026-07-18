import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_source_provider.dart';
import '../providers/filter_provider.dart';
import '../providers/view_mode_provider.dart';
import '../l10n/l10n.dart';
import 'merged_view.dart';
import 'compare_view.dart';
import '../filter/filter_panel.dart';
import '../search/search_widget.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(dataSourceNotifierProvider.notifier).loadSources();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataSourceState = ref.watch(dataSourceNotifierProvider);
    final viewModeState = ref.watch(viewModeNotifierProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
            tooltip: l10n.search,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilter(context),
            tooltip: l10n.filter,
          ),
          PopupMenuButton<ViewMode>(
            icon: const Icon(Icons.view_module),
            onSelected: (mode) {
              ref.read(viewModeNotifierProvider.notifier).setMode(mode);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ViewMode.merged,
                child: Text(l10n.mergedView),
              ),
              PopupMenuItem(
                value: ViewMode.compare,
                child: Text(l10n.compareView),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(dataSourceState, viewModeState, l10n),
    );
  }

  Widget _buildBody(
    DataSourceState dataSourceState,
    ViewModeState viewModeState,
    AppLocalizations l10n,
  ) {
    switch (dataSourceState.status) {
      case LoadingStatus.initial:
      case LoadingStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case LoadingStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                l10n.error,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(dataSourceState.errorMessage ?? ''),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(dataSourceNotifierProvider.notifier).loadSources();
                },
                child: Text(l10n.retry),
              ),
            ],
          ),
        );

      case LoadingStatus.success:
        if (dataSourceState.sources.isEmpty) {
          return Center(child: Text(l10n.noData));
        }

        _initializeFilter(dataSourceState.sources.map((s) => s.id).toList());

        if (viewModeState.mode == ViewMode.compare) {
          return CompareView(sourceIds: viewModeState.compareSourceIds);
        } else {
          return const MergedView();
        }
    }
  }

  void _initializeFilter(List<String> sourceIds) {
    final filterNotifier = ref.read(filterNotifierProvider.notifier);
    filterNotifier.initializeSources(sourceIds);
  }

  void _showSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const SearchWidget(),
    );
  }

  void _showFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const FilterPanel(),
    );
  }
}
