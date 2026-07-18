import 'package:flutter/material.dart';
import '../models/timeline_entry.dart';
import 'timeline_viewport.dart';

class TimelineWidget extends StatefulWidget {
  final List<TimelineEntry> entries;
  final Map<String, Color> sourceColors;
  final ScrollController? scrollController;
  final void Function(TimelineEntry entry)? onEntryTap;

  const TimelineWidget({
    super.key,
    required this.entries,
    this.sourceColors = const {},
    this.scrollController,
    this.onEntryTap,
  });

  @override
  State<TimelineWidget> createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> {
  late TimelineViewport _viewport;
  ScrollController? _internalController;

  @override
  void initState() {
    super.initState();
    _viewport = TimelineViewport();
    if (widget.scrollController == null) {
      _internalController = ScrollController();
    }
  }

  ScrollController get _controller =>
      widget.scrollController ?? _internalController!;

  @override
  void didUpdateWidget(TimelineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalculate layout when entries change
    _viewport.invalidateLayout();
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          _viewport.scrollOffset = notification.metrics.pixels;
          setState(() {});
        }
        return false;
      },
      child: GestureDetector(
        onScaleUpdate: (details) {
          if (details.scale != 1.0) {
            _viewport.zoomBy(details.scale);
            setState(() {});
          }
        },
        child: CustomPaint(
          painter: _TimelinePainter(
            entries: widget.entries,
            viewport: _viewport,
            sourceColors: widget.sourceColors,
            onEntryTap: widget.onEntryTap,
          ),
          child: ListView.builder(
            controller: _controller,
            itemCount: 0, // We use CustomPaint, no children
            itemBuilder: (_, __) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final List<TimelineEntry> entries;
  final TimelineViewport viewport;
  final Map<String, Color> sourceColors;
  final void Function(TimelineEntry entry)? onEntryTap;

  _TimelinePainter({
    required this.entries,
    required this.viewport,
    required this.sourceColors,
    this.onEntryTap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    viewport.setViewportHeight(size.height);
    viewport.setContentBounds(
      entries.first.date.toDouble(),
      entries.last.date.toDouble(),
    );

    // Draw axis
    _drawAxis(canvas, size);

    // Draw entries
    final visible = viewport.getVisibleEntries(entries);
    for (final entry in visible) {
      _drawEntry(canvas, entry, size);
    }
  }

  void _drawAxis(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2;

    final axisX = size.width * 0.15;
    canvas.drawLine(Offset(axisX, 0), Offset(axisX, size.height), paint);

    // Draw time ticks
    final visibleRange = viewport.getVisibleDateRange();
    final tickInterval = _calculateTickInterval(visibleRange);

    final startTick = (visibleRange.start / tickInterval).ceil() * tickInterval;
    for (double t = startTick; t <= visibleRange.end; t += tickInterval) {
      final y = viewport.dateToY(t.round(), size.height);
      if (y >= 0 && y <= size.height) {
        canvas.drawLine(Offset(axisX - 8, y), Offset(axisX, y), paint);

        final textPainter = TextPainter(
          text: TextSpan(
            text: _formatDate(t.round()),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
          ),
        )..layout();

        textPainter.paint(
          canvas,
          Offset(axisX - textPainter.width - 4, y - textPainter.height / 2),
        );
      }
    }
  }

  void _drawEntry(Canvas canvas, TimelineEntry entry, Size size) {
    final y = viewport.dateToY(entry.date, size.height);
    if (y < -50 || y > size.height + 50) return;

    final axisX = size.width * 0.15;
    final color = sourceColors[entry.sourceId] ?? Colors.grey;

    // Draw connector line
    final connectorPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(axisX, y), Offset(axisX + 20, y), connectorPaint);

    // Draw node
    final nodePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(axisX, y), 6, nodePaint);

    // Draw label
    final textPainter = TextPainter(
      text: TextSpan(
        text: entry.label,
        style: TextStyle(
          color: Colors.black87,
          fontSize: 13,
          fontWeight: entry.type == EntryType.era
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
    )..layout(maxWidth: size.width * 0.7);

    textPainter.paint(canvas, Offset(axisX + 24, y - textPainter.height / 2));
  }

  double _calculateTickInterval(DateRange range) {
    final span = range.end - range.start;
    if (span <= 0) return 1;

    final candidates = [
      1.0,
      5.0,
      10.0,
      50.0,
      100.0,
      500.0,
      1000.0,
      5000.0,
      10000.0,
      50000.0,
      100000.0,
      500000.0,
      1000000.0,
      10000000.0,
      100000000.0,
      1000000000.0,
      5000000000.0,
    ];

    for (final c in candidates) {
      if (span / c <= 15) return c;
    }
    return candidates.last;
  }

  String _formatDate(int date) {
    if (date < 0) return '公元前${-date}';
    if (date.abs() >= 1000000000)
      return '${(date / 1000000000).toStringAsFixed(1)}Ga';
    if (date.abs() >= 1000000)
      return '${(date / 1000000).toStringAsFixed(1)}Ma';
    if (date.abs() >= 1000) return '${(date / 1000).toStringAsFixed(1)}Ka';
    return '$date';
  }

  @override
  bool shouldRepaint(_TimelinePainter oldDelegate) {
    return oldDelegate.entries != entries ||
        oldDelegate.viewport.scrollOffset != viewport.scrollOffset ||
        oldDelegate.viewport.zoomLevel != viewport.zoomLevel;
  }
}
