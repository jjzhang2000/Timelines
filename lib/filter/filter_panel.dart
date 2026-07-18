import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_source_provider.dart';
import '../providers/filter_provider.dart';
import '../l10n/l10n.dart';

class FilterPanel extends ConsumerWidget {
  const FilterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataSourceState = ref.watch(dataSourceNotifierProvider);
    final filterState = ref.watch(filterNotifierProvider);
    final l10n = AppLocalizations.of(context);

    if (dataSourceState.status != LoadingStatus.success) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.filter, style: Theme.of(context).textTheme.titleLarge),
              Row(
                children: [
                  TextButton(
                    onPressed: () =>
                        ref.read(filterNotifierProvider.notifier).selectAll(),
                    child: Text(l10n.selectAll),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () =>
                        ref.read(filterNotifierProvider.notifier).deselectAll(),
                    child: Text(l10n.deselectAll),
                  ),
                ],
              ),
            ],
          ),
          const Divider(),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: dataSourceState.sources.length,
              itemBuilder: (context, index) {
                final source = dataSourceState.sources[index];
                final isVisible = filterState.isVisible(source.id);

                return CheckboxListTile(
                  value: isVisible,
                  onChanged: (value) {
                    ref
                        .read(filterNotifierProvider.notifier)
                        .toggleSource(source.id);
                  },
                  title: Text(source.metadata.name),
                  subtitle: Text('${source.events.length} 个事件'),
                  secondary: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: source.metadata.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
