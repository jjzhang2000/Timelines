import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:timelines/models/timeline_source.dart';
import 'package:timelines/models/timeline_metadata.dart';
import 'package:timelines/models/timeline_entry.dart';

void main() {
  group('TimelineSource', () {
    test('TC-SRC-001: 从 JSON 创建 TimelineSource', () {
      final json = {
        'metadata': {
          'name': '测试数据源',
          'version': '1.0',
          'description': '测试描述',
          'colorScheme': {'primary': '#FF5722', 'secondary': '#FFC107'},
        },
        'events': [
          {'date': 2024, 'label': '事件1', 'type': 'incident'},
          {'date': 2023, 'label': '事件2', 'type': 'era'},
        ],
      };

      final source = TimelineSource.fromJson('test_source', json);

      expect(source.id, 'test_source');
      expect(source.metadata.name, '测试数据源');
      expect(source.metadata.version, '1.0');
      expect(source.events.length, 2);
      expect(source.events[0].label, '事件1');
      expect(source.events[1].label, '事件2');
    });

    test('TC-SRC-002: 事件关联 sourceId', () {
      final json = {
        'metadata': {
          'name': '测试',
          'version': '1.0',
          'description': '测试',
          'colorScheme': {'primary': '#FF0000', 'secondary': '#00FF00'},
        },
        'events': [
          {'date': 2024, 'label': '事件', 'type': 'incident'},
        ],
      };

      final source = TimelineSource.fromJson('my_source', json);

      expect(source.events[0].sourceId, 'my_source');
    });

    test('TC-SRC-003: 空事件列表', () {
      final json = {
        'metadata': {
          'name': '空数据源',
          'version': '1.0',
          'description': '没有事件',
          'colorScheme': {'primary': '#0000FF', 'secondary': '#FFFF00'},
        },
        'events': [],
      };

      final source = TimelineSource.fromJson('empty', json);

      expect(source.events, isEmpty);
    });

    test('TC-SRC-004: toJson 序列化', () {
      final source = TimelineSource(
        id: 'test',
        metadata: TimelineMetadata(
          name: '测试',
          version: '1.0',
          description: '描述',
          colorScheme: TimelineColorScheme(
            primary: const Color(0xFFFF5722),
            secondary: const Color(0xFFFFC107),
          ),
        ),
        events: [
          TimelineEntry(
            date: 2024,
            label: '事件',
            type: EntryType.incident,
            sourceId: 'test',
          ),
        ],
      );

      final json = source.toJson();

      expect(json['metadata'], isNotNull);
      expect(json['events'], isNotNull);
      expect((json['events'] as List).length, 1);
    });
  });
}
