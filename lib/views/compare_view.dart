import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_source_provider.dart';
import '../timeline/timeline_widget.dart';
import '../article/summary_bubble.dart';
import '../article/detail_page.dart';

class CompareView extends ConsumerStatefulWidget {
  final List<String> sourceIds;

  const CompareView({super.key, required this.sourceIds});

  @override
  ConsumerState<CompareView> createState() => _CompareViewState();
}

class _CompareViewState extends ConsumerState<CompareView> {
  final List<ScrollController> _controllers = [];
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final dataSourceState = ref.read(dataSourceNotifierProvider);

    final sources = dataSourceState.sources
        .where((s) => widget.sourceIds.contains(s.id))
        .toList();

    for (var i = 0; i < sources.length; i++) {
      final controller = ScrollController();
      controller.addListener(() => _syncScroll(i, controller.offset));
      _controllers.add(controller);
    }
  }

  void _syncScroll(int sourceIndex, double offset) {
    if (_isSyncing) return;
    _isSyncing = true;

    for (var i = 0; i < _controllers.length; i++) {
      if (i != sourceIndex && _controllers[i].hasClients) {
        _controllers[i].jumpTo(offset);
      }
    }

    _isSyncing = false;
  }

  @override
  Widget build(BuildContext context) {
    final dataSourceState = ref.watch(dataSourceNotifierProvider);

    final sources = dataSourceState.sources
        .where((s) => widget.sourceIds.contains(s.id))
        .toList();

    if (sources.isEmpty) {
      return const Center(child: Text('请选择要对比的数据源'));
    }

    return Row(
      children: List.generate(sources.length, (index) {
        final source = sources[index];
        return Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                color: source.metadata.colorScheme.primary.withOpacity(0.2),
                child: Text(
                  source.metadata.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: TimelineWidget(
                  entries: source.events,
                  scrollController: _controllers[index],
                  sourceColors: {
                    source.id: source.metadata.colorScheme.primary,
                  },
                  onEntryTap: (entry) {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SummaryBubble(
                        entry: entry,
                        onDetailTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DetailPage(entry: entry),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
