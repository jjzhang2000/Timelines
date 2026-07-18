import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_provider.dart';
import '../providers/data_source_provider.dart';
import '../l10n/l10n.dart';
import '../models/timeline_entry.dart';

class SearchWidget extends ConsumerStatefulWidget {
  const SearchWidget({super.key});

  @override
  ConsumerState<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends ConsumerState<SearchWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchNotifierProvider);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.search,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchState.query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          ref
                              .read(searchNotifierProvider.notifier)
                              .clearSearch();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref.read(searchNotifierProvider.notifier).updateQuery(value);
              },
            ),
          ),
          if (searchState.isSearching)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else if (searchState.suggestions.isNotEmpty)
            _buildSuggestions(searchState.suggestions)
          else if (searchState.results.isNotEmpty)
            _buildResults(searchState.results)
          else if (searchState.query.isNotEmpty && !searchState.isSearching)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(l10n.noData),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(List<String> suggestions) {
    return Flexible(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.search),
            title: Text(suggestions[index]),
            onTap: () {
              _controller.text = suggestions[index];
              ref
                  .read(searchNotifierProvider.notifier)
                  .updateQuery(suggestions[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildResults(List<TimelineEntry> results) {
    final dataSourceState = ref.watch(dataSourceNotifierProvider);
    final sources = {
      for (final source in dataSourceState.sources) source.id: source,
    };

    return Flexible(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: results.length,
        itemBuilder: (context, index) {
          final entry = results[index];
          final source = sources[entry.sourceId];

          return ListTile(
            leading: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: source?.metadata.colorScheme.primary ?? Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            title: Text(entry.label),
            subtitle: Text(source?.metadata.name ?? ''),
            onTap: () {
              Navigator.of(context).pop(entry);
            },
          );
        },
      ),
    );
  }
}
