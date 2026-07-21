import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_source_provider.dart';
import '../timeline/timeline_viewport.dart';
import '../timeline/timeline_widget.dart';
import '../article/summary_bubble.dart';
import '../article/detail_page.dart';
import '../models/timeline_entry.dart';

class CompareView extends ConsumerStatefulWidget {
  final List<String> sourceIds;

  const CompareView({super.key, required this.sourceIds});

  @override
  ConsumerState<CompareView> createState() => _CompareViewState();
}

class _CompareViewState extends ConsumerState<CompareView>
    with TickerProviderStateMixin {
  late TimelineViewport _sharedViewport;
  final GlobalKey _stackKey = GlobalKey();
  final List<TimelineEntry?> _selectedEntries = [];
  final List<AnimationController> _animControllers = [];
  final List<Animation<double>> _fadeAnimations = [];
  final List<Animation<double>> _scaleAnimations = [];
  final List<GlobalKey> _timelineKeys = [];

  @override
  void initState() {
    super.initState();
    _sharedViewport = TimelineViewport();

    // 计算所有数据源的全局日期范围
    final dataSourceState = ref.read(dataSourceNotifierProvider);
    final sources = dataSourceState.sources
        .where((s) => widget.sourceIds.contains(s.id))
        .toList();

    if (sources.isNotEmpty) {
      int globalMinDate = sources.first.events.first.date;
      int globalMaxDate = sources.first.events.first.date;

      for (final source in sources) {
        for (final event in source.events) {
          if (event.date < globalMinDate) globalMinDate = event.date;
          if (event.date > globalMaxDate) globalMaxDate = event.date;
        }
      }

      _sharedViewport.setContentBounds(
        globalMinDate.toDouble(),
        globalMaxDate.toDouble(),
      );
    }

    // 为每个面板初始化状态
    for (int i = 0; i < sources.length; i++) {
      _selectedEntries.add(null);
      _timelineKeys.add(GlobalKey());
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 450),
      );
      _animControllers.add(controller);
      _fadeAnimations.add(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ));
      _scaleAnimations.add(Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      )));
    }
  }

  @override
  void dispose() {
    for (final controller in _animControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showBubble(int index, TimelineEntry entry) {
    setState(() {
      // 关闭其他面板的气泡，确保同时只有一个气泡
      for (int i = 0; i < _selectedEntries.length; i++) {
        if (i != index && _selectedEntries[i] != null) {
          _selectedEntries[i] = null;
        }
      }
      _selectedEntries[index] = entry;
    });
    _animControllers[index].reset();
    _animControllers[index].forward();
  }

  void _hideBubble(int index) {
    _animControllers[index].reverse().then((_) {
      if (mounted) {
        setState(() {
          _selectedEntries[index] = null;
        });
      }
    });
  }

  /// 计算每个条目的水平偏移量（相同日期的条目错开显示）
  Map<TimelineEntry, double> _computeLabelOffsets(
      List<TimelineEntry> entries) {
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

  /// 计算气泡相对于最外层 Stack 的位置和翻转状态
  /// 返回 (位置, 是否翻转到标签左侧)
  (Offset, bool)? _computeBubblePosition(
      int index, List<TimelineEntry> entries, double stackWidth) {
    final entry = _selectedEntries[index];
    if (entry == null) return null;

    final renderBox =
        _timelineKeys[index].currentContext?.findRenderObject() as RenderBox?;
    final stackBox =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || stackBox == null) return null;

    final canvasSize = renderBox.size;
    _sharedViewport.setViewportHeight(canvasSize.height);

    final y = _sharedViewport.dateToY(entry.date, canvasSize.height);
    if (y < -50 || y > canvasSize.height + 50) return null;

    final axisX = canvasSize.width * 0.15;
    final labelOffsets = _computeLabelOffsets(entries);
    final xOffset = labelOffsets[entry] ?? 0;

    final tp = TextPainter(
      text: TextSpan(
        text: entry.label,
        style: TextStyle(
          fontSize: 13,
          fontWeight:
              entry.type == EntryType.era ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: canvasSize.width * 0.7);
    final labelWidth = tp.width;
    tp.dispose();

    // 标签左端和右端在 TimelineWidget 中的局部坐标
    final labelLeftLocal = axisX + 24 + xOffset;
    final labelRightLocal = labelLeftLocal + labelWidth;

    // 转换为最外层 Stack 的坐标
    final rightInStack =
        stackBox.globalToLocal(renderBox.localToGlobal(Offset(labelRightLocal, y)));
    final leftInStack =
        stackBox.globalToLocal(renderBox.localToGlobal(Offset(labelLeftLocal, y)));

    // 右侧不够且左侧够时，翻转到标签左侧
    const bubbleWidth = 256.0;
    final flip = (rightInStack.dx + bubbleWidth) > stackWidth &&
        leftInStack.dx >= bubbleWidth;

    final position = flip
        ? Offset(leftInStack.dx - bubbleWidth, rightInStack.dy)
        : Offset(rightInStack.dx, rightInStack.dy);

    return (position, flip);
  }

  @override
  Widget build(BuildContext context) {
    final dataSourceState = ref.watch(dataSourceNotifierProvider);

    final sources = dataSourceState.sources
        .where((s) => widget.sourceIds.contains(s.id))
        .toList();

    if (sources.isEmpty) {
      return const Center(child: Text('请选择要对比的数据源'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackWidth = constraints.maxWidth;

        // 找到当前选中的面板和气泡位置
        int? selectedIndex;
        Offset? bubblePosition;
        bool bubbleFlip = false;
        for (int i = 0; i < _selectedEntries.length; i++) {
          if (_selectedEntries[i] != null) {
            selectedIndex = i;
            final info = _computeBubblePosition(i, sources[i].events, stackWidth);
            if (info != null) {
              bubblePosition = info.$1;
              bubbleFlip = info.$2;
            }
            break;
          }
        }

        return Stack(
          key: _stackKey,
          children: [
            Row(
              children: List.generate(sources.length, (index) {
                final source = sources[index];
                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: source.metadata.colorScheme.primary
                            .withValues(alpha: 0.2),
                        child: Text(
                          source.metadata.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Expanded(
                        child: TimelineWidget(
                          key: _timelineKeys[index],
                          entries: source.events,
                          sharedViewport: _sharedViewport,
                          onViewportChanged: () => setState(() {}),
                          sourceColors: {
                            source.id: source.metadata.colorScheme.primary,
                          },
                          onEntryTap: (entry, labelPosition) {
                            _showBubble(index, entry);
                          },
                          onBlankTap: () {
                            if (_selectedEntries[index] != null) {
                              _hideBubble(index);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            if (selectedIndex != null && bubblePosition != null)
              Positioned(
                left: bubblePosition.dx,
                top: bubblePosition.dy,
                child: _buildBubble(selectedIndex, bubbleFlip),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBubble(int index, bool flip) {
    const maxBubbleWidth = 256.0;
    const cornerRadius = 20.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = (isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFFAFAFA)).withValues(alpha: 0.75);

    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: ScaleTransition(
        scale: _scaleAnimations[index],
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
                entry: _selectedEntries[index]!,
                onDetailTap: () {
                  _hideBubble(index);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          DetailPage(entry: _selectedEntries[index]!),
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
