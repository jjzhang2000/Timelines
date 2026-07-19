import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../models/timeline_entry.dart';
import 'timeline_viewport.dart';

class TimelineWidget extends StatefulWidget {
  final List<TimelineEntry> entries;
  final Map<String, Color> sourceColors;
  final ScrollController? scrollController;
  final void Function(TimelineEntry entry, Offset labelPosition)? onEntryTap;
  /// 点击空白区域回调
  final VoidCallback? onBlankTap;
  /// 需要跟踪标签位置的条目（气泡跟随用）
  final TimelineEntry? trackedEntry;
  /// 跟踪条目的标签位置变化回调（位置为 null 表示离开视口）
  final void Function(Offset? labelPosition)? onTrackedLabelPositionChanged;
  /// 拖拽开始回调
  final VoidCallback? onDragStart;
  /// 拖拽结束回调
  final VoidCallback? onDragEnd;
  /// CompositedTransform 链接（用于气泡跟随）
  final LayerLink? layerLink;

  const TimelineWidget({
    super.key,
    required this.entries,
    this.sourceColors = const {},
    this.scrollController,
    this.onEntryTap,
    this.onBlankTap,
    this.trackedEntry,
    this.onTrackedLabelPositionChanged,
    this.onDragStart,
    this.onDragEnd,
    this.layerLink,
  });

  @override
  State<TimelineWidget> createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> {
  late TimelineViewport _viewport;
  Size _canvasSize = Size.zero;
  Offset? _lastNotifiedPosition;

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
    // trackedEntry 变化时重置缓存
    if (widget.trackedEntry != oldWidget.trackedEntry) {
      _lastNotifiedPosition = null;
    }
  }

  void _handleTap(Offset localPosition) {
    final axisX = _canvasSize.width * 0.15;
    for (final entry in widget.entries) {
      final y = _viewport.dateToY(entry.date, _canvasSize.height);
      if ((localPosition.dy - y).abs() < 15) {
        final labelX = axisX + 24;
        final labelY = y;
        widget.onEntryTap?.call(entry, Offset(labelX, labelY));
        return;
      }
    }
    // 未命中任何标签，视为点击空白区域
    widget.onBlankTap?.call();
  }

  void _notifyTrackedPosition({bool force = false}) {
    if (widget.onTrackedLabelPositionChanged == null) return;
    final tracked = widget.trackedEntry;
    if (tracked == null) {
      if (_lastNotifiedPosition != null) {
        _lastNotifiedPosition = null;
        widget.onTrackedLabelPositionChanged!(null);
      }
      return;
    }

    final y = _viewport.dateToY(tracked.date, _canvasSize.height);
    Offset? newPosition;
    
    // 检查是否离开视口
    if (y < -50 || y > _canvasSize.height + 50) {
      newPosition = null;
    } else {
      final axisX = _canvasSize.width * 0.15;
      newPosition = Offset(axisX + 24, y);
    }

    // 强制模式：无论位置是否变化都触发回调
    if (force) {
      _lastNotifiedPosition = newPosition;
      widget.onTrackedLabelPositionChanged!(newPosition);
      return;
    }

    // 只有位置真正变化时才通知（至少移动 1 像素）
    if (_lastNotifiedPosition == null && newPosition != null) {
      _lastNotifiedPosition = newPosition;
      widget.onTrackedLabelPositionChanged!(newPosition);
    } else if (_lastNotifiedPosition != null && newPosition == null) {
      _lastNotifiedPosition = null;
      widget.onTrackedLabelPositionChanged!(null);
    } else if (_lastNotifiedPosition != null && newPosition != null) {
      final dx = (newPosition.dx - _lastNotifiedPosition!.dx).abs();
      final dy = (newPosition.dy - _lastNotifiedPosition!.dy).abs();
      if (dx > 1.0 || dy > 1.0) {
        _lastNotifiedPosition = newPosition;
        widget.onTrackedLabelPositionChanged!(newPosition);
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
          setState(() {
            _notifyTrackedPosition();
          });
        }
      },
      child: GestureDetector(
          onTapUp: (details) {
            _handleTap(details.localPosition);
          },
          onPanStart: (details) {
            widget.onDragStart?.call();
          },
          onPanUpdate: (details) {
            _viewport.scrollBy(-details.delta.dy);
            setState(() {
              _notifyTrackedPosition();
            });
          },
          onPanEnd: (details) {
            // 先通知拖拽结束（重置 _isDragging）
            widget.onDragEnd?.call();
            // 延迟到下一帧再通知位置，确保气泡已渲染
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _lastNotifiedPosition = null;
                _notifyTrackedPosition(force: true);
              }
            });
          },
        child: LayoutBuilder(
          builder: (context, constraints) {
            _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
            
            // 计算跟踪标签的位置（用于 CompositedTransformTarget）
            Offset? trackedLabelPosition;
            if (widget.layerLink != null && widget.trackedEntry != null) {
              final y = _viewport.dateToY(widget.trackedEntry!.date, _canvasSize.height);
              final axisX = _canvasSize.width * 0.15;
              trackedLabelPosition = Offset(axisX + 24, y);
            }
            
            return Stack(
              children: [
                CustomPaint(
                  painter: _TimelinePainter(
                    entries: widget.entries,
                    viewport: _viewport,
                    sourceColors: widget.sourceColors,
                    isDark: isDark,
                    scrollOffset: _viewport.scrollOffset,
                    zoomLevel: _viewport.zoomLevel,
                  ),
                  size: Size.infinite,
                ),
                // 添加 CompositedTransformTarget 用于气泡跟随
                if (trackedLabelPosition != null && widget.layerLink != null)
                  Positioned(
                    left: trackedLabelPosition.dx,
                    top: trackedLabelPosition.dy,
                    child: CompositedTransformTarget(
                      link: widget.layerLink!,
                      child: const SizedBox(width: 0, height: 0),
                    ),
                  ),
              ],
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
