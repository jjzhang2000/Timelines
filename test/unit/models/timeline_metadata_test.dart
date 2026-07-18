import 'package:flutter_test/flutter_test.dart';
import 'package:timelines/models/timeline_metadata.dart';

void main() {
  group('TimelineMetadata', () {
    test('TC-META-001: 从 JSON 创建 TimelineMetadata', () {
      final json = {
        'name': '宇宙历史',
        'version': '1.0',
        'description': '宇宙演化时间线',
        'colorScheme': {'primary': '#FF5722', 'secondary': '#FFC107'},
      };

      final metadata = TimelineMetadata.fromJson(json);

      expect(metadata.name, '宇宙历史');
      expect(metadata.version, '1.0');
      expect(metadata.description, '宇宙演化时间线');
      expect(metadata.colorScheme, isNotNull);
    });

    test('TC-META-002: 颜色方案解析：6 位十六进制', () {
      final json = {'primary': '#FF5722', 'secondary': '#4CAF50'};

      final colorScheme = TimelineColorScheme.fromJson(json);

      expect(colorScheme.primary, isNotNull);
      expect(colorScheme.secondary, isNotNull);
      expect(colorScheme.primary.red, 255);
      expect(colorScheme.primary.green, 87);
      expect(colorScheme.primary.blue, 34);
    });

    test('TC-META-003: 颜色方案解析：8 位十六进制（带透明度）', () {
      final json = {'primary': '#80FF5722', 'secondary': '#FF4CAF50'};

      final colorScheme = TimelineColorScheme.fromJson(json);

      expect(colorScheme.primary.alpha, 128);
      expect(colorScheme.primary.red, 255);
      expect(colorScheme.secondary.alpha, 255);
    });

    test('TC-META-004: 颜色方案解析：无效格式', () {
      final json = {'primary': 'invalid_color', 'secondary': '#FFC107'};

      expect(
        () => TimelineColorScheme.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
