import 'package:flutter_test/flutter_test.dart';
import 'package:timelines/utils/time_utils.dart';

void main() {
  group('TimeUtils', () {
    test('TC-TIME-001: formatDate：正数年份', () {
      final result = TimeUtils.formatDate(2024);

      expect(result, '2024 年');
    });

    test('TC-TIME-002: formatDate：负数年份', () {
      final result = TimeUtils.formatDate(-5000000000);

      expect(result, '公元前 5000000000 年');
    });

    test('TC-TIME-003: formatDuration：小于 100 年', () {
      final result = TimeUtils.formatDuration(2000, 2050);

      expect(result, '50 年');
    });

    test('TC-TIME-004: formatDuration：100-1000 年', () {
      final result = TimeUtils.formatDuration(1000, 1500);

      expect(result, '5 世纪');
    });

    test('TC-TIME-005: formatDuration：大于 1000 年', () {
      final result = TimeUtils.formatDuration(0, 5000);

      expect(result, '5 千年');
    });
  });
}
