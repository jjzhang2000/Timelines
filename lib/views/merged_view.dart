import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/timeline_provider.dart';
import '../providers/data_source_provider.dart';
import '../timeline/timeline_widget.dart';
import '../article/summary_bubble.dart';
import '../article/detail_page.dart';

class MergedView extends ConsumerWidget {
  const MergedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineState = ref.watch(timelineNotifierProvider);
    final dataSourceState = ref.watch(dataSourceNotifierProvider);

    return TimelineWidget(
      entries: timelineState.entries,
      sourceColors: {
        for (final source in dataSourceState.sources)
          source.id: source.metadata.colorScheme.primary,
      },
      onEntryTap: (entry) {
        final index = timelineState.entries.indexOf(entry);
        ref.read(timelineNotifierProvider.notifier).selectEntry(index);

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
    );
  }
}
