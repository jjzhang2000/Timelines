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
  /// 参数：标签位置（Offset）、标签宽度（double）
  final void Function(Offset? labelPosition, double labelWidth)? onTrackedLabelPositionChanged;
  /// 拖拽开始回调
  final VoidCallback? onDragStart;
  /// 拖拽结束回调
  final VoidCallback? onDragEnd;
  /// 共享的视口（用于多时间轴同步滚动/缩放）
  final TimelineViewport? sharedViewport;
  /// 视口变化回调（用于通知外部重建）
  final VoidCallback? onViewportChanged;

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
    this.sharedViewport,
    this.onViewportChanged,
  });

  @override
  State<TimelineWidget> createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> {
  TimelineViewport? _localViewport;
  Size _canvasSize = Size.zero;
  Offset? _lastNotifiedPosition;
  double _lastNotifiedLabelWidth = 0;

  TimelineViewport get _viewport => widget.sharedViewport ?? _localViewport!;

  @override
  void initState() {
    super.initState();
    if (widget.sharedViewport == null) {
      _localViewport = TimelineViewport();
    }
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

  void _notifyViewportChanged() {
    widget.onViewportChanged?.call();
  }

  /// 计算每个条目的水平偏移量（相同日期的条目错开显示）
  Map<TimelineEntry, double> _computeLabelOffsets(List<TimelineEntry> entries, double canvasWidth) {
    final offsets = <TimelineEntry, double>{};
    final dateGroups = <int, List<TimelineEntry>>{};
    
    // 按日期分组
    for (final entry in entries) {
      dateGroups.putIfAbsent(entry.date, () => []).add(entry);
    }
    
    // 为相同日期的条目计算偏移
    const offsetStep = 24.0; // 每个错开的间距
    for (final group in dateGroups.values) {
      if (group.length > 1) {
        for (int i = 0; i < group.length; i++) {
          offsets[group[i]] = i * offsetStep;
        }
      }
    }
    
    return offsets;
  }

  void _handleTap(Offset localPosition) {
    final axisX = _canvasSize.width * 0.15;
    final baseLabelX = axisX + 24;
    final labelOffsets = _computeLabelOffsets(widget.entries, _canvasSize.width);

    TimelineEntry? bestEntry;
    double bestDistance = double.infinity;
    Offset? bestPosition;

    for (final entry in widget.entries) {
      final y = _viewport.dateToY(entry.date, _canvasSize.height);
      final dy = (localPosition.dy - y).abs();
      if (dy < 15) {
        final xOffset = labelOffsets[entry] ?? 0;
        final labelStartX = baseLabelX + xOffset;

        // 测量标签文本范围，同时检查 x 坐标
        final tp = TextPainter(
          text: TextSpan(
            text: entry.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: entry.type == EntryType.era
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: _canvasSize.width * 0.7);
        final labelRight = labelStartX + tp.width;
        tp.dispose();

        // 点击必须在标签文本水平范围内（含少量容差）
        if (localPosition.dx >= labelStartX - 8 &&
            localPosition.dx <= labelRight + 8) {
          // 使用欧几里得距离选择最近的标签
          final dx = (localPosition.dx - (labelStartX + labelRight) / 2).abs();
          final distance = dx * dx + dy * dy;
          if (distance < bestDistance) {
            bestDistance = distance;
            bestEntry = entry;
            bestPosition = Offset(labelRight, y);
          }
        }
      }
    }

    if (bestEntry != null) {
      widget.onEntryTap?.call(bestEntry, bestPosition!);
    } else {
      // 未命中任何标签，视为点击空白区域
      widget.onBlankTap?.call();
    }
  }

  void _notifyTrackedPosition({bool force = false}) {
    if (widget.onTrackedLabelPositionChanged == null) return;
    final tracked = widget.trackedEntry;
    if (tracked == null) {
      if (_lastNotifiedPosition != null) {
        _lastNotifiedPosition = null;
        widget.onTrackedLabelPositionChanged!(null, 0);
      }
      return;
    }

    final y = _viewport.dateToY(tracked.date, _canvasSize.height);
    Offset? newPosition;
    double labelWidth = 0;

    // 检查是否离开视口
    if (y < -50 || y > _canvasSize.height + 50) {
      newPosition = null;
    } else {
      final axisX = _canvasSize.width * 0.15;
      // 计算该条目的偏移量
      final labelOffsets = _computeLabelOffsets(widget.entries, _canvasSize.width);
      final xOffset = labelOffsets[tracked] ?? 0;

      // 测量标签文本宽度
      final tp = TextPainter(
        text: TextSpan(
          text: tracked.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: tracked.type == EntryType.era
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: _canvasSize.width * 0.7);
      labelWidth = tp.width;
      tp.dispose();

      newPosition = Offset(axisX + 24 + xOffset, y);
    }

    // 强制模式：无论位置是否变化都触发回调
    if (force) {
      _lastNotifiedPosition = newPosition;
      _lastNotifiedLabelWidth = labelWidth;
      widget.onTrackedLabelPositionChanged!(newPosition, labelWidth);
      return;
    }

    // 只有位置真正变化时才通知（至少移动 1 像素）
    if (_lastNotifiedPosition == null && newPosition != null) {
      _lastNotifiedPosition = newPosition;
      _lastNotifiedLabelWidth = labelWidth;
      widget.onTrackedLabelPositionChanged!(newPosition, labelWidth);
    } else if (_lastNotifiedPosition != null && newPosition == null) {
      _lastNotifiedPosition = null;
      _lastNotifiedLabelWidth = 0;
      widget.onTrackedLabelPositionChanged!(null, 0);
    } else if (_lastNotifiedPosition != null && newPosition != null) {
      final dx = (newPosition.dx - _lastNotifiedPosition!.dx).abs();
      final dy = (newPosition.dy - _lastNotifiedPosition!.dy).abs();
      if (dx > 1.0 || dy > 1.0 || labelWidth != _lastNotifiedLabelWidth) {
        _lastNotifiedPosition = newPosition;
        _lastNotifiedLabelWidth = labelWidth;
        widget.onTrackedLabelPositionChanged!(newPosition, labelWidth);
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
          _notifyTrackedPosition(force: true);
          _notifyViewportChanged();
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
            setState(() {});
            _notifyTrackedPosition(force: true);
            _notifyViewportChanged();
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
            
            // 计算所有标签的偏移量
            final labelOffsets = _computeLabelOffsets(widget.entries, _canvasSize.width);
            
            return CustomPaint(
              painter: _TimelinePainter(
                entries: widget.entries,
                viewport: _viewport,
                sourceColors: widget.sourceColors,
                labelOffsets: labelOffsets,
                isDark: isDark,
                scrollOffset: _viewport.scrollOffset,
                zoomLevel: _viewport.zoomLevel,
                isSharedViewport: widget.sharedViewport != null,
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
  final Map<TimelineEntry, double> labelOffsets;
  final bool isDark;
  final double scrollOffset;
  final double zoomLevel;
  final bool isSharedViewport;

  _TimelinePainter({
    required this.entries,
    required this.viewport,
    required this.sourceColors,
    this.labelOffsets = const {},
    this.isDark = false,
    required this.scrollOffset,
    required this.zoomLevel,
    this.isSharedViewport = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    viewport.setViewportHeight(size.height);
    // 共享视口时，由外部统一管理日期范围，避免相互覆盖
    if (!isSharedViewport) {
      viewport.setContentBounds(
        entries.first.date.toDouble(),
        entries.last.date.toDouble(),
      );
    }

    // Draw axis
    _drawAxis(canvas, size);

    // Draw entries
    final visible = viewport.getVisibleEntries(entries);
    for (final entry in visible) {
      _drawEntry(canvas, entry, size, labelOffsets[entry] ?? 0);
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

  void _drawEntry(Canvas canvas, TimelineEntry entry, Size size, double xOffset) {
    final y = viewport.dateToY(entry.date, size.height);
    if (y < -50 || y > size.height + 50) return;

    final axisX = size.width * 0.15;
    final color = sourceColors[entry.sourceId] ?? Colors.grey;

    // Draw connector line
    final connectorPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(axisX, y), Offset(axisX + 20 + xOffset, y), connectorPaint);

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

    textPainter.paint(canvas, Offset(axisX + 24 + xOffset, y - textPainter.height / 2));
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
