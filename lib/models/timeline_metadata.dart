import 'dart:ui';

class TimelineColorScheme {
  final Color primary;
  final Color secondary;

  const TimelineColorScheme({required this.primary, required this.secondary});

  factory TimelineColorScheme.fromJson(Map<String, dynamic> json) {
    return TimelineColorScheme(
      primary: _hexToColor(json['primary'] as String),
      secondary: _hexToColor(json['secondary'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary': _colorToHex(primary),
      'secondary': _colorToHex(secondary),
    };
  }

  static Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }
}

class TimelineMetadata {
  final String name;
  final String version;
  final String description;
  final TimelineColorScheme colorScheme;

  const TimelineMetadata({
    required this.name,
    required this.version,
    required this.description,
    required this.colorScheme,
  });

  factory TimelineMetadata.fromJson(Map<String, dynamic> json) {
    return TimelineMetadata(
      name: json['name'] as String,
      version: json['version'] as String,
      description: json['description'] as String,
      colorScheme: TimelineColorScheme.fromJson(
        json['colorScheme'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'version': version,
      'description': description,
      'colorScheme': colorScheme.toJson(),
    };
  }
}
