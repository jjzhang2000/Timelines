import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:timelines/models/timeline_entry.dart';

void main() {
  group('TimelineEntry', () {
    test('TC-ENTRY-001: 从 JSON 创建 TimelineEntry（完整数据）', () {
      final json = {
        'date': -13800000000,
        'label': '大爆炸',
        'summary': '宇宙诞生的时刻',
        'description': 'big_bang.html',
        'type': 'incident',
        'background': [0, 38, 75],
        'accent': [246, 76, 130, 255],
      };

      final entry = TimelineEntry.fromJson(json, 'universe');

      expect(entry.date, -13800000000);
      expect(entry.label, '大爆炸');
      expect(entry.summary, '宇宙诞生的时刻');
      expect(entry.description, 'big_bang.html');
      expect(entry.type, EntryType.incident);
      expect(entry.sourceId, 'universe');
      expect(entry.background, isNotNull);
      expect(entry.accent, isNotNull);
    });

    test('TC-ENTRY-002: 从 JSON 创建 TimelineEntry（可选字段缺失）', () {
      final json = {'date': 2024, 'label': '现代事件', 'type': 'incident'};

      final entry = TimelineEntry.fromJson(json, 'modern');

      expect(entry.date, 2024);
      expect(entry.label, '现代事件');
      expect(entry.summary, isNull);
      expect(entry.description, isNull);
      expect(entry.background, isNull);
      expect(entry.accent, isNull);
    });

    test('TC-ENTRY-003: 颜色解析：RGB 格式（3 元素）', () {
      final json = {
        'date': 2024,
        'label': '测试',
        'type': 'incident',
        'background': [255, 128, 64],
      };

      final entry = TimelineEntry.fromJson(json, 'test');

      expect(entry.background, isNotNull);
      expect(entry.background!.red, 255);
      expect(entry.background!.green, 128);
      expect(entry.background!.blue, 64);
      expect(entry.background!.alpha, 255);
    });

    test('TC-ENTRY-004: 颜色解析：RGBA 格式（4 元素）', () {
      final json = {
        'date': 2024,
        'label': '测试',
        'type': 'incident',
        'accent': [100, 150, 200, 128],
      };

      final entry = TimelineEntry.fromJson(json, 'test');

      expect(entry.accent, isNotNull);
      expect(entry.accent!.red, 100);
      expect(entry.accent!.green, 150);
      expect(entry.accent!.blue, 200);
      expect(entry.accent!.alpha, 128);
    });

    test('TC-ENTRY-005: 颜色解析：无效长度', () {
      final json = {
        'date': 2024,
        'label': '测试',
        'type': 'incident',
        'background': [255, 128],
      };

      expect(
        () => TimelineEntry.fromJson(json, 'test'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('TC-ENTRY-006: 类型解析：era', () {
      final json = {'date': 2024, 'label': '时代', 'type': 'era'};

      final entry = TimelineEntry.fromJson(json, 'test');

      expect(entry.type, EntryType.era);
    });

    test('TC-ENTRY-007: 类型解析：incident', () {
      final json = {'date': 2024, 'label': '事件', 'type': 'incident'};

      final entry = TimelineEntry.fromJson(json, 'test');

      expect(entry.type, EntryType.incident);
    });

    test('TC-ENTRY-008: 类型解析：未知类型默认为 incident', () {
      final json = {'date': 2024, 'label': '未知', 'type': 'unknown_type'};

      final entry = TimelineEntry.fromJson(json, 'test');

      expect(entry.type, EntryType.incident);
    });

    test('TC-ENTRY-009: toJson 序列化', () {
      final entry = TimelineEntry(
        date: 2024,
        label: '测试事件',
        summary: '测试简述',
        description: 'test.html',
        type: EntryType.incident,
        sourceId: 'test_source',
        background: const Color.fromARGB(255, 255, 128, 64),
        accent: const Color.fromARGB(128, 100, 150, 200),
      );

      final json = entry.toJson();

      expect(json['date'], 2024);
      expect(json['label'], '测试事件');
      expect(json['summary'], '测试简述');
      expect(json['description'], 'test.html');
      expect(json['type'], 'incident');
      expect(json['background'], isNotNull);
      expect(json['accent'], isNotNull);
    });

    test('TC-ENTRY-010: copyWith 方法', () {
      final original = TimelineEntry(
        date: 2024,
        label: '原始',
        type: EntryType.incident,
        sourceId: 'source1',
      );

      final copied = original.copyWith(label: '修改后', summary: '新增简述');

      expect(copied.date, 2024);
      expect(copied.label, '修改后');
      expect(copied.summary, '新增简述');
      expect(copied.sourceId, 'source1');
    });

    test('TC-ENTRY-011: 负数时间戳（公元前）', () {
      final json = {'date': -5000000000, 'label': '远古事件', 'type': 'incident'};

      final entry = TimelineEntry.fromJson(json, 'ancient');

      expect(entry.date, -5000000000);
      expect(entry.date, isNegative);
    });
  });
}
