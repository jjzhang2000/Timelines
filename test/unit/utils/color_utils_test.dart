import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:timelines/utils/color_utils.dart';

void main() {
  group('ColorUtils', () {
    test('TC-COLOR-001: hexToColor：6 位十六进制', () {
      final color = ColorUtils.hexToColor('#FF5722');

      expect(color.red, 255);
      expect(color.green, 87);
      expect(color.blue, 34);
      expect(color.alpha, 255);
    });

    test('TC-COLOR-002: hexToColor：8 位十六进制', () {
      final color = ColorUtils.hexToColor('#80FF5722');

      expect(color.alpha, 128);
      expect(color.red, 255);
      expect(color.green, 87);
      expect(color.blue, 34);
    });

    test('TC-COLOR-003: hexToColor：带 # 前缀', () {
      final color1 = ColorUtils.hexToColor('#FF5722');
      final color2 = ColorUtils.hexToColor('FF5722');

      expect(color1, equals(color2));
    });

    test('TC-COLOR-004: colorToHex', () {
      final color = const Color(0xFFFF5722);
      final hex = ColorUtils.colorToHex(color);

      expect(hex, '#FFFF5722');
    });

    test('TC-COLOR-005: interpolateColor：t=0', () {
      final start = const Color(0xFFFF0000);
      final end = const Color(0xFF0000FF);
      final result = ColorUtils.interpolateColor(start, end, 0);

      expect(result, equals(start));
    });

    test('TC-COLOR-006: interpolateColor：t=1', () {
      final start = const Color(0xFFFF0000);
      final end = const Color(0xFF0000FF);
      final result = ColorUtils.interpolateColor(start, end, 1);

      expect(result, equals(end));
    });

    test('TC-COLOR-007: interpolateColor：t=0.5', () {
      final start = const Color(0xFFFF0000);
      final end = const Color(0xFF0000FF);
      final result = ColorUtils.interpolateColor(start, end, 0.5);

      expect(result.red, closeTo(128, 1));
      expect(result.blue, closeTo(128, 1));
    });
  });
}
