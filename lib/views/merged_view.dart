import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/timeline_provider.dart';
import '../providers/data_source_provider.dart';
import '../timeline/timeline_widget.dart';
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
  TimelineEntry? _selectedEntry;
  Offset? _bubblePosition;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Size _windowSize = Size.zero;
  bool _isOverflow = false;
  Alignment _scaleAlignment = Alignment.topLeft;
  final GlobalKey _bubbleKey = GlobalKey();
  Offset _labelPosition = Offset.zero;

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

  void _showBubble(TimelineEntry entry, Offset position) {
    setState(() {
      _selectedEntry = entry;
      _labelPosition = position;
      _bubblePosition = position;
      _isOverflow = false;
      _scaleAlignment = Alignment.topLeft;
    });
    _animController.reset();
    _animController.forward();

    // 首帧渲染后测量气泡实际尺寸，根据是否溢出底部调整位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _selectedEntry != null) {
        _measureAndReposition();
      }
    });
  }

  void _measureAndReposition() {
    final RenderBox? bubbleBox = _bubbleKey.currentContext?.findRenderObject() as RenderBox?;
    if (bubbleBox == null || !bubbleBox.hasSize) return;

    final bubbleSize = bubbleBox.size;
    final labelY = _labelPosition.dy;
    final labelX = _labelPosition.dx;

    // 检查气泡放在标签下方是否会超出窗口底部
    final wouldOverflow = labelY + 10 + bubbleSize.height > _windowSize.height;

    // 根据是否溢出计算气泡位置和缩放原点
    double top;
    Alignment alignment;
    if (wouldOverflow) {
      // 气泡放在标签上方，箭头朝下
      top = labelY - bubbleSize.height;
      alignment = Alignment.bottomLeft;
    } else {
      // 气泡放在标签下方，箭头朝上
      top = labelY + 10;
      alignment = Alignment.topLeft;
    }

    // 检查是否超出窗口右边界
    double left = labelX + 50;
    if (left + bubbleSize.width > _windowSize.width) {
      left = _windowSize.width - bubbleSize.width - 10;
    }

    setState(() {
      _isOverflow = wouldOverflow;
      _scaleAlignment = alignment;
      _bubblePosition = Offset(left, top);
    });
  }

  void _hideBubble() {
    _animController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _selectedEntry = null;
          _bubblePosition = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final timelineState = ref.watch(timelineNotifierProvider);
    final dataSourceState = ref.watch(dataSourceNotifierProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        _windowSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          children: [
            TimelineWidget(
              entries: timelineState.entries,
              sourceColors: {
                for (final source in dataSourceState.sources)
                  source.id: source.metadata.colorScheme.primary,
              },
              onEntryTap: (entry, labelPosition) {
                final index = timelineState.entries.indexOf(entry);
                ref.read(timelineNotifierProvider.notifier).selectEntry(index);
                _showBubble(entry, labelPosition);
              },
            ),
            if (_selectedEntry != null && _bubblePosition != null)
              _buildBubble(),
          ],
        );
      },
    );
  }

  Widget _buildBubble() {
    const maxBubbleWidth = 320.0;
    const cornerRadius = 16.0;
    const arrowSize = 12.0;

    // Arrow direction: if bubble is above label (overflow), arrow points down
    final arrowUp = !_isOverflow;

    double left = _bubblePosition!.dx;
    double top = _bubblePosition!.dy;

    final bgColor = Theme.of(context).colorScheme.surface;
    final borderColor = Theme.of(context).dividerColor;

    return Positioned(
      left: left,
      top: top,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          alignment: _scaleAlignment,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxBubbleWidth),
            child: CustomPaint(
              key: _bubbleKey,
              painter: _BubblePainter(
                arrowUp: arrowUp,
                arrowSize: arrowSize,
                cornerRadius: cornerRadius,
                fillColor: bgColor,
                borderColor: borderColor,
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: arrowSize + 20,
                  right: 20,
                  top: arrowUp ? arrowSize + 16 : 16,
                  bottom: arrowUp ? 16 : arrowSize + 16,
                ),
                child: SummaryBubble(
                  entry: _selectedEntry!,
                  onDetailTap: () {
                    _hideBubble();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DetailPage(entry: _selectedEntry!),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  final bool arrowUp;
  final double arrowSize;
  final double cornerRadius;
  final Color fillColor;
  final Color borderColor;

  _BubblePainter({
    required this.arrowUp,
    required this.arrowSize,
    required this.cornerRadius,
    required this.fillColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bodyLeft = arrowSize;
    final bodyTop = arrowUp ? arrowSize : 0.0;
    final bodyRight = size.width;
    final bodyBottom = size.height - (arrowUp ? 0.0 : arrowSize);
    final bodyRect = Rect.fromLTRB(bodyLeft, bodyTop, bodyRight, bodyBottom);
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, Radius.circular(cornerRadius));

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(bodyRRect, fillPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    if (arrowUp) {
      final arrowPath = Path()
        ..moveTo(bodyLeft, bodyTop)
        ..lineTo(0, 0)
        ..lineTo(bodyLeft, bodyTop + arrowSize);
      canvas.drawPath(arrowPath, fillPaint);

      final border = Path()
        ..moveTo(bodyLeft, bodyTop + arrowSize)
        ..lineTo(0, 0)
        ..lineTo(bodyLeft, bodyTop);
      canvas.drawPath(border, borderPaint);
    } else {
      final arrowPath = Path()
        ..moveTo(bodyLeft, bodyBottom)
        ..lineTo(0, size.height)
        ..lineTo(bodyLeft, bodyBottom - arrowSize);
      canvas.drawPath(arrowPath, fillPaint);

      final border = Path()
        ..moveTo(bodyLeft, bodyBottom - arrowSize)
        ..lineTo(0, size.height)
        ..lineTo(bodyLeft, bodyBottom);
      canvas.drawPath(border, borderPaint);
    }

    canvas.drawRRect(bodyRRect, borderPaint);
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) {
    return oldDelegate.arrowUp != arrowUp ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor;
  }
}
