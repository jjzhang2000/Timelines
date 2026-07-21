import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/timeline_provider.dart';
import '../providers/data_source_provider.dart';
import '../timeline/timeline_widget.dart';
import '../timeline/timeline_viewport.dart';
import '../article/summary_bubble.dart';
import '../article/detail_page.dart';
import '../models/timeline_entry.dart';

class MergedView extends ConsumerStatefulWidget {
  const MergedView({super.key});

  @override
  ConsumerState<MergedView> createState() => _MergedViewState();
}

class _MergedViewState extends ConsumerState<MergedView>
    with SingleTickerProviderStateMixin {
  final TimelineViewport _viewport = TimelineViewport();
  TimelineEntry? _selectedEntry;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showBubble(TimelineEntry entry) {
    setState(() {
      _selectedEntry = entry;
    });
    _animController.reset();
    _animController.forward();
  }

  void _hideBubble() {
    _animController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _selectedEntry = null;
        });
      }
    });
  }

  /// 计算每个条目的水平偏移量（相同日期的条目错开显示）
  Map<TimelineEntry, double> _computeLabelOffsets(List<TimelineEntry> entries) {
    final offsets = <TimelineEntry, double>{};
    final dateGroups = <int, List<TimelineEntry>>{};

    for (final entry in entries) {
      dateGroups.putIfAbsent(entry.date, () => []).add(entry);
    }

    const offsetStep = 24.0;
    for (final group in dateGroups.values) {
      if (group.length > 1) {
        for (int i = 0; i < group.length; i++) {
          offsets[group[i]] = i * offsetStep;
        }
      }
    }

    return offsets;
  }

  /// 计算气泡位置和翻转状态
  /// 返回 (位置, 是否翻转到标签左侧)
  (Offset, bool)? _computeBubblePosition(
      List<TimelineEntry> entries, double canvasWidth, double canvasHeight) {
    if (_selectedEntry == null) return null;

    _viewport.setViewportHeight(canvasHeight);

    final y = _viewport.dateToY(_selectedEntry!.date, canvasHeight);
    if (y < -50 || y > canvasHeight + 50) return null;

    final axisX = canvasWidth * 0.15;
    final labelOffsets = _computeLabelOffsets(entries);
    final xOffset = labelOffsets[_selectedEntry] ?? 0;

    final tp = TextPainter(
      text: TextSpan(
        text: _selectedEntry!.label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: _selectedEntry!.type == EntryType.era
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: canvasWidth * 0.7);
    final labelWidth = tp.width;
    tp.dispose();

    final labelLeft = axisX + 24 + xOffset;
    final labelRight = labelLeft + labelWidth;

    // 右侧不够且左侧够时，翻转到标签左侧
    const bubbleWidth = 256.0;
    final flip = (labelRight + bubbleWidth) > canvasWidth &&
        labelLeft >= bubbleWidth;

    final position =
        flip ? Offset(labelLeft - bubbleWidth, y) : Offset(labelRight, y);

    return (position, flip);
  }

  @override
  Widget build(BuildContext context) {
    final timelineState = ref.watch(timelineNotifierProvider);
    final dataSourceState = ref.watch(dataSourceNotifierProvider);

    final entries = timelineState.entries;

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasWidth = constraints.maxWidth;
        final canvasHeight = constraints.maxHeight;

        // 先设置视口高度，再设置内容边界，确保 _pixelsPerUnit 正确
        _viewport.setViewportHeight(canvasHeight);
        if (entries.isNotEmpty) {
          _viewport.setContentBounds(
            entries.first.date.toDouble(),
            entries.last.date.toDouble(),
          );
        }

        // 在 build 中直接计算气泡位置，确保跟随滚动/缩放
        final bubbleInfo =
            _computeBubblePosition(entries, canvasWidth, canvasHeight);
        final bubblePosition = bubbleInfo?.$1;
        final bubbleFlip = bubbleInfo?.$2 ?? false;

        return Stack(
          children: [
            TimelineWidget(
              entries: entries,
              sourceColors: {
                for (final source in dataSourceState.sources)
                  source.id: source.metadata.colorScheme.primary,
              },
              sharedViewport: _viewport,
              onViewportChanged: () => setState(() {}),
              onEntryTap: (entry, labelPosition) {
                final index = entries.indexOf(entry);
                ref.read(timelineNotifierProvider.notifier).selectEntry(index);
                _showBubble(entry);
              },
              onBlankTap: () {
                if (_selectedEntry != null) {
                  _hideBubble();
                }
              },
            ),
            if (_selectedEntry != null && bubblePosition != null)
              Positioned(
                left: bubblePosition.dx,
                top: bubblePosition.dy,
                child: _buildBubble(bubbleFlip),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBubble(bool flip) {
    const maxBubbleWidth = 256.0;
    const cornerRadius = 20.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = (isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFFAFAFA)).withValues(alpha: 0.75);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        alignment: flip ? Alignment.topRight : Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxBubbleWidth),
          child: Material(
            elevation: 8,
            borderRadius: flip
                ? BorderRadius.only(
                    topLeft: Radius.circular(cornerRadius),
                    topRight: Radius.zero,
                    bottomLeft: Radius.circular(cornerRadius),
                    bottomRight: Radius.circular(cornerRadius),
                  )
                : BorderRadius.only(
                    topLeft: Radius.zero,
                    topRight: Radius.circular(cornerRadius),
                    bottomLeft: Radius.circular(cornerRadius),
                    bottomRight: Radius.circular(cornerRadius),
                  ),
            color: bgColor,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 20, 16),
              child: SummaryBubble(
                entry: _selectedEntry!,
                onDetailTap: () {
                  _hideBubble();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          DetailPage(entry: _selectedEntry!),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
