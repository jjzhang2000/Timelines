import 'timeline_entry.dart';
import 'timeline_metadata.dart';

class TimelineSource {
  final String id;
  final TimelineMetadata metadata;
  final List<TimelineEntry> events;

  const TimelineSource({
    required this.id,
    required this.metadata,
    required this.events,
  });

  factory TimelineSource.fromJson(String id, Map<String, dynamic> json) {
    final metadata = TimelineMetadata.fromJson(
      json['metadata'] as Map<String, dynamic>,
    );
    final eventsJson = json['events'] as List<dynamic>;
    final events = eventsJson
        .map((e) => TimelineEntry.fromJson(e as Map<String, dynamic>, id))
        .toList();

    return TimelineSource(id: id, metadata: metadata, events: events);
  }

  Map<String, dynamic> toJson() {
    return {
      'metadata': metadata.toJson(),
      'events': events.map((e) => e.toJson()).toList(),
    };
  }
}
