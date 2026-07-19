import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../models/timeline_entry.dart';
import 'timeline_viewport.dart';

class TimelineWidget extends StatefulWidget {
  final List<TimelineEntry> entries;
  final Map<String, Color> sourceColors;
  final ScrollController? scrollController;
  final void Function(TimelineEntry entry, Offset labelPosition)? onEntryTap;

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
  Size _canvasSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _viewport = TimelineViewport();
  }

  @override
  void didUpdateWidget(TimelineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalculate layout when entries change
    _viewport.invalidateLayout();
  }

  void _handleTap(Offset localPosition) {
    if (widget.onEntryTap == null) return;
    final axisX = _canvasSize.width * 0.15;
    for (final entry in widget.entries) {
      final y = _viewport.dateToY(entry.date, _canvasSize.height);
      if ((localPosition.dy - y).abs() < 15) {
        // 标签位置：canvas 内 axisX + 24, y
        // 气泡应出现在标签右侧
        final labelX = axisX + 24;
        final labelY = y;
        widget.onEntryTap!(entry, Offset(labelX, labelY));
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          // 滚轮缩放：向下滚放大，向上滚缩小
          final factor = event.scrollDelta.dy > 0 ? 1.1 : 0.9;
          _viewport.zoomBy(factor);
          setState(() {});
        }
      },
      child: GestureDetector(
          onTapUp: (details) {
            _handleTap(details.localPosition);
          },
          onPanUpdate: (details) {
            _viewport.scrollBy(-details.delta.dy);
            setState(() {});
          },
        child: LayoutBuilder(
          builder: (context, constraints) {
            _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
            return CustomPaint(
              painter: _TimelinePainter(
                entries: widget.entries,
                viewport: _viewport,
                sourceColors: widget.sourceColors,
                isDark: isDark,
                scrollOffset: _viewport.scrollOffset,
                zoomLevel: _viewport.zoomLevel,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final List<TimelineEntry> entries;
  final TimelineViewport viewport;
  final Map<String, Color> sourceColors;
  final bool isDark;
  final double scrollOffset;
  final double zoomLevel;

  _TimelinePainter({
    required this.entries,
    required this.viewport,
    required this.sourceColors,
    this.isDark = false,
    required this.scrollOffset,
    required this.zoomLevel,
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
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(axisX - textPainter.width - 10, y - textPainter.height / 2),
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
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 13,
          fontWeight: entry.type == EntryType.era
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
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
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.zoomLevel != zoomLevel ||
        oldDelegate.isDark != isDark;
  }
}
