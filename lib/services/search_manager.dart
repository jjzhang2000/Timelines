import 'dart:async';
import '../models/timeline_entry.dart';
import '../models/timeline_source.dart';
import 'prefix_tree.dart';

class SearchManager {
  final PrefixTree _prefixTree = PrefixTree();
  bool _isIndexBuilt = false;

  Future<void> buildIndex(List<TimelineSource> sources) async {
    if (_isIndexBuilt) return;

    for (final source in sources) {
      for (final entry in source.events) {
        final words = _tokenize(entry.label);
        if (entry.summary != null) {
          words.addAll(_tokenize(entry.summary!));
        }

        for (final word in words) {
          _prefixTree.insert(word, entry);
        }
      }
    }

    _isIndexBuilt = true;
  }

  List<String> _tokenize(String text) {
    final words = <String>[];

    final parts = text.split(RegExp(r'\s+'));

    for (final part in parts) {
      final camelParts = part.split(RegExp(r'(?=[A-Z])'));

      for (final camelPart in camelParts) {
        final subParts = camelPart.split(RegExp(r'[-_]'));
        words.addAll(subParts.where((s) => s.isNotEmpty));
      }
    }

    return words.map((w) => w.toLowerCase()).toList();
  }

  Future<List<TimelineEntry>> search(String query) async {
    if (!_isIndexBuilt) {
      throw StateError('Search index not built');
    }

    final queryWords = _tokenize(query);
    if (queryWords.isEmpty) return [];

    Set<TimelineEntry>? results;
    for (final word in queryWords) {
      final wordResults = _prefixTree.search(word);
      if (results == null) {
        results = wordResults;
      } else {
        results = results.intersection(wordResults);
      }
    }

    final resultList = results?.toList() ?? [];
    resultList.sort((a, b) => a.date.compareTo(b.date));

    return resultList;
  }

  Future<List<String>> getSuggestions(String query, {int limit = 5}) async {
    if (!_isIndexBuilt) {
      throw StateError('Search index not built');
    }

    final queryWords = _tokenize(query);
    if (queryWords.isEmpty) return [];

    return _prefixTree.getSuggestions(queryWords.last, limit: limit);
  }

  void clearIndex() {
    _prefixTree.clear();
    _isIndexBuilt = false;
  }
}
