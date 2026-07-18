import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:timelines/models/timeline_entry.dart';
import 'package:timelines/models/timeline_source.dart';
import 'package:timelines/models/timeline_metadata.dart';
import 'package:timelines/services/search_manager.dart';

void main() {
  group('SearchManager', () {
    late SearchManager manager;

    setUp(() {
      manager = SearchManager();
    });

    test('TC-SEARCH-002: 分词：空格分割', () async {
      final source = TimelineSource(
        id: 'test',
        metadata: TimelineMetadata(
          name: '测试',
          version: '1.0',
          description: '测试',
          colorScheme: TimelineColorScheme(
            primary: const Color(0xFFFF0000),
            secondary: const Color(0xFF00FF00),
          ),
        ),
        events: [
          TimelineEntry(
            date: 2024,
            label: 'hello world',
            type: EntryType.incident,
            sourceId: 'test',
          ),
        ],
      );

      await manager.buildIndex([source]);
      final results = await manager.search('hello');

      expect(results.length, 1);
      expect(results[0].label, 'hello world');
    });

    test('TC-SEARCH-003: 分词：驼峰识别', () async {
      final source = TimelineSource(
        id: 'test',
        metadata: TimelineMetadata(
          name: '测试',
          version: '1.0',
          description: '测试',
          colorScheme: TimelineColorScheme(
            primary: const Color(0xFFFF0000),
            secondary: const Color(0xFF00FF00),
          ),
        ),
        events: [
          TimelineEntry(
            date: 2024,
            label: 'camelCase',
            type: EntryType.incident,
            sourceId: 'test',
          ),
        ],
      );

      await manager.buildIndex([source]);
      final results = await manager.search('camel');

      expect(results.length, 1);
    });

    test('TC-SEARCH-004: 分词：连字符分割', () async {
      final source = TimelineSource(
        id: 'test',
        metadata: TimelineMetadata(
          name: '测试',
          version: '1.0',
          description: '测试',
          colorScheme: TimelineColorScheme(
            primary: const Color(0xFFFF0000),
            secondary: const Color(0xFF00FF00),
          ),
        ),
        events: [
          TimelineEntry(
            date: 2024,
            label: 'hello-world',
            type: EntryType.incident,
            sourceId: 'test',
          ),
        ],
      );

      await manager.buildIndex([source]);
      final results = await manager.search('hello');

      expect(results.length, 1);
    });

    test('TC-SEARCH-005: 分词：下划线分割', () async {
      final source = TimelineSource(
        id: 'test',
        metadata: TimelineMetadata(
          name: '测试',
          version: '1.0',
          description: '测试',
          colorScheme: TimelineColorScheme(
            primary: const Color(0xFFFF0000),
            secondary: const Color(0xFF00FF00),
          ),
        ),
        events: [
          TimelineEntry(
            date: 2024,
            label: 'hello_world',
            type: EntryType.incident,
            sourceId: 'test',
          ),
        ],
      );

      await manager.buildIndex([source]);
      final results = await manager.search('world');

      expect(results.length, 1);
    });

    test('TC-SEARCH-006: 多词 AND 查询', () async {
      final source = TimelineSource(
        id: 'test',
        metadata: TimelineMetadata(
          name: '测试',
          version: '1.0',
          description: '测试',
          colorScheme: TimelineColorScheme(
            primary: const Color(0xFFFF0000),
            secondary: const Color(0xFF00FF00),
          ),
        ),
        events: [
          TimelineEntry(
            date: 2024,
            label: 'hello world',
            type: EntryType.incident,
            sourceId: 'test',
          ),
          TimelineEntry(
            date: 2023,
            label: 'hello dart',
            type: EntryType.incident,
            sourceId: 'test',
          ),
        ],
      );

      await manager.buildIndex([source]);
      final results = await manager.search('hello world');

      expect(results.length, 1);
      expect(results[0].label, 'hello world');
    });

    test('TC-SEARCH-007: 搜索结果按时间排序', () async {
      final source = TimelineSource(
        id: 'test',
        metadata: TimelineMetadata(
          name: '测试',
          version: '1.0',
          description: '测试',
          colorScheme: TimelineColorScheme(
            primary: const Color(0xFFFF0000),
            secondary: const Color(0xFF00FF00),
          ),
        ),
        events: [
          TimelineEntry(
            date: 2024,
            label: 'event 2024',
            type: EntryType.incident,
            sourceId: 'test',
          ),
          TimelineEntry(
            date: 2022,
            label: 'event 2022',
            type: EntryType.incident,
            sourceId: 'test',
          ),
          TimelineEntry(
            date: 2023,
            label: 'event 2023',
            type: EntryType.incident,
            sourceId: 'test',
          ),
        ],
      );

      await manager.buildIndex([source]);
      final results = await manager.search('event');

      expect(results[0].date, 2022);
      expect(results[1].date, 2023);
      expect(results[2].date, 2024);
    });

    test('TC-SEARCH-008: 索引未构建时搜索抛出 StateError', () {
      expect(() => manager.search('test'), throwsA(isA<StateError>()));
    });

    test('TC-SEARCH-009: 空查询返回空列表', () async {
      final source = TimelineSource(
        id: 'test',
        metadata: TimelineMetadata(
          name: '测试',
          version: '1.0',
          description: '测试',
          colorScheme: TimelineColorScheme(
            primary: const Color(0xFFFF0000),
            secondary: const Color(0xFF00FF00),
          ),
        ),
        events: [
          TimelineEntry(
            date: 2024,
            label: '测试事件',
            type: EntryType.incident,
            sourceId: 'test',
          ),
        ],
      );

      await manager.buildIndex([source]);
      final results = await manager.search('');

      expect(results, isEmpty);
    });
  });
}
