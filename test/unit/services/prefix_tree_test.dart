import 'package:flutter_test/flutter_test.dart';
import 'package:timelines/models/timeline_entry.dart';
import 'package:timelines/services/prefix_tree.dart';

void main() {
  group('PrefixTree', () {
    late PrefixTree tree;

    setUp(() {
      tree = PrefixTree();
    });

    test('TC-TRIE-001: 插入单词并搜索', () {
      final entry = TimelineEntry(
        date: 2024,
        label: '测试事件',
        type: EntryType.incident,
        sourceId: 'test',
      );

      tree.insert('hello', entry);
      final results = tree.search('hel');

      expect(results, contains(entry));
    });

    test('TC-TRIE-002: 前缀搜索返回所有匹配条目', () {
      final entry1 = TimelineEntry(
        date: 2024,
        label: '事件1',
        type: EntryType.incident,
        sourceId: 'test',
      );
      final entry2 = TimelineEntry(
        date: 2023,
        label: '事件2',
        type: EntryType.incident,
        sourceId: 'test',
      );

      tree.insert('hello', entry1);
      tree.insert('help', entry2);

      final results = tree.search('hel');

      expect(results.length, 2);
      expect(results, contains(entry1));
      expect(results, contains(entry2));
    });

    test('TC-TRIE-003: 大小写无关搜索', () {
      final entry = TimelineEntry(
        date: 2024,
        label: '测试',
        type: EntryType.incident,
        sourceId: 'test',
      );

      tree.insert('Hello', entry);

      final results1 = tree.search('hello');
      final results2 = tree.search('HELLO');
      final results3 = tree.search('HeLLo');

      expect(results1, contains(entry));
      expect(results2, contains(entry));
      expect(results3, contains(entry));
    });

    test('TC-TRIE-004: 搜索不存在的前缀返回空集合', () {
      final entry = TimelineEntry(
        date: 2024,
        label: '测试',
        type: EntryType.incident,
        sourceId: 'test',
      );

      tree.insert('hello', entry);
      final results = tree.search('xyz');

      expect(results, isEmpty);
    });

    test('TC-TRIE-005: 获取自动补全建议', () {
      final entry = TimelineEntry(
        date: 2024,
        label: '测试',
        type: EntryType.incident,
        sourceId: 'test',
      );

      tree.insert('hello', entry);
      tree.insert('help', entry);
      tree.insert('hero', entry);

      final suggestions = tree.getSuggestions('hel');

      expect(suggestions.length, lessThanOrEqualTo(5));
      expect(suggestions, contains('hello'));
      expect(suggestions, contains('help'));
    });

    test('TC-TRIE-006: 重复插入相同单词使用 Set 去重', () {
      final entry = TimelineEntry(
        date: 2024,
        label: '测试',
        type: EntryType.incident,
        sourceId: 'test',
      );

      tree.insert('hello', entry);
      tree.insert('hello', entry);
      tree.insert('hello', entry);

      final results = tree.search('hello');

      expect(results.length, 1);
    });

    test('TC-TRIE-007: 清空索引', () {
      final entry = TimelineEntry(
        date: 2024,
        label: '测试',
        type: EntryType.incident,
        sourceId: 'test',
      );

      tree.insert('hello', entry);
      tree.clear();
      final results = tree.search('hello');

      expect(results, isEmpty);
    });
  });
}
