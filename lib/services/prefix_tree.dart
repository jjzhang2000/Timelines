import '../models/timeline_entry.dart';

class PrefixTreeNode {
  final Map<String, PrefixTreeNode> children = {};
  final Set<TimelineEntry> entries = {};

  void insert(String word, TimelineEntry entry) {
    var node = this;
    for (final char in word.toLowerCase().split('')) {
      node = node.children.putIfAbsent(char, () => PrefixTreeNode());
    }
    node.entries.add(entry);
  }

  Set<TimelineEntry> search(String prefix) {
    var node = this;
    for (final char in prefix.toLowerCase().split('')) {
      node = node.children[char] ?? (node = PrefixTreeNode());
    }

    final results = <TimelineEntry>{};
    _collectEntries(node, results);
    return results;
  }

  void _collectEntries(PrefixTreeNode node, Set<TimelineEntry> results) {
    results.addAll(node.entries);
    for (final child in node.children.values) {
      _collectEntries(child, results);
    }
  }

  List<String> getSuggestions(String prefix, {int limit = 5}) {
    final suggestions = <String>[];
    _collectSuggestions(this, prefix.toLowerCase(), '', suggestions, limit);
    return suggestions;
  }

  void _collectSuggestions(
    PrefixTreeNode node,
    String target,
    String current,
    List<String> suggestions,
    int limit,
  ) {
    if (suggestions.length >= limit) return;

    if (target.isEmpty && node.entries.isNotEmpty) {
      suggestions.add(current);
    }

    for (final entry in node.children.entries) {
      if (target.isEmpty || entry.key == target[0]) {
        _collectSuggestions(
          entry.value,
          target.isEmpty ? '' : target.substring(1),
          current + entry.key,
          suggestions,
          limit,
        );
      }
    }
  }
}

class PrefixTree {
  final PrefixTreeNode root = PrefixTreeNode();

  void insert(String word, TimelineEntry entry) {
    root.insert(word, entry);
  }

  Set<TimelineEntry> search(String prefix) {
    return root.search(prefix);
  }

  List<String> getSuggestions(String prefix, {int limit = 5}) {
    return root.getSuggestions(prefix, limit: limit);
  }

  void clear() {
    root.children.clear();
    root.entries.clear();
  }
}
