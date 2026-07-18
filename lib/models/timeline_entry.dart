import 'dart:ui';

enum EntryType { era, incident }

class TimelineEntry {
  final int date;
  final String label;
  final String? summary;
  final String? description;
  final EntryType type;
  final Color? background;
  final Color? accent;
  final String sourceId;

  const TimelineEntry({
    required this.date,
    required this.label,
    required this.type,
    required this.sourceId,
    this.summary,
    this.description,
    this.background,
    this.accent,
  });

  factory TimelineEntry.fromJson(Map<String, dynamic> json, String sourceId) {
    return TimelineEntry(
      date: json['date'] as int,
      label: json['label'] as String,
      summary: json['summary'] as String?,
      description: json['description'] as String?,
      type: EntryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EntryType.incident,
      ),
      background: json['background'] != null
          ? _colorFromList(json['background'] as List<dynamic>)
          : null,
      accent: json['accent'] != null
          ? _colorFromList(json['accent'] as List<dynamic>)
          : null,
      sourceId: sourceId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'label': label,
      'summary': summary,
      'description': description,
      'type': type.name,
      'background': background != null ? _colorToList(background!) : null,
      'accent': accent != null ? _colorToList(accent!) : null,
    };
  }

  TimelineEntry copyWith({
    int? date,
    String? label,
    String? summary,
    String? description,
    EntryType? type,
    Color? background,
    Color? accent,
    String? sourceId,
  }) {
    return TimelineEntry(
      date: date ?? this.date,
      label: label ?? this.label,
      summary: summary ?? this.summary,
      description: description ?? this.description,
      type: type ?? this.type,
      background: background ?? this.background,
      accent: accent ?? this.accent,
      sourceId: sourceId ?? this.sourceId,
    );
  }

  static Color _colorFromList(List<dynamic> list) {
    if (list.length == 3) {
      return Color.fromARGB(
        255,
        list[0] as int,
        list[1] as int,
        list[2] as int,
      );
    } else if (list.length == 4) {
      return Color.fromARGB(
        list[3] as int,
        list[0] as int,
        list[1] as int,
        list[2] as int,
      );
    }
    throw ArgumentError('Invalid color list length: ${list.length}');
  }

  static List<int> _colorToList(Color color) {
    return [color.red, color.green, color.blue, color.alpha];
  }
}
