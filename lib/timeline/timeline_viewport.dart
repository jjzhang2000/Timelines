import '../models/timeline_entry.dart';

class DateRange {
  final int start;
  final int end;

  const DateRange({required this.start, required this.end});
}

class TimelineViewport {
  double scrollOffset;
  double zoomLevel;
  double _viewportHeight;
  double _minDate;
  double _maxDate;
  double _pixelsPerUnit;

  TimelineViewport({
    this.scrollOffset = 0,
    this.zoomLevel = 1.0,
    double viewportHeight = 600,
    double minDate = 0,
    double maxDate = 1000,
    double pixelsPerUnit = 1.0,
  }) : _viewportHeight = viewportHeight,
       _minDate = minDate,
       _maxDate = maxDate,
       _pixelsPerUnit = pixelsPerUnit;

  double get viewportHeight => _viewportHeight;
  double get bufferZone => 100;

  void setViewportHeight(double height) {
    _viewportHeight = height;
  }

  void setContentBounds(double minDate, double maxDate) {
    _minDate = minDate;
    _maxDate = maxDate;
    _recalculatePixelsPerUnit();
  }

  void _recalculatePixelsPerUnit() {
    final dateRange = _maxDate - _minDate;
    if (dateRange <= 0) {
      _pixelsPerUnit = 1.0;
      return;
    }
    _pixelsPerUnit = (_viewportHeight / dateRange) * zoomLevel;
  }

  void scrollBy(double delta) {
    scrollOffset += delta;
    final maxScroll = _getMaxScroll();
    scrollOffset = scrollOffset.clamp(0.0, maxScroll);
  }

  void zoomBy(double factor) {
    zoomLevel *= factor;
    zoomLevel = zoomLevel.clamp(0.01, 100.0);
    _recalculatePixelsPerUnit();
  }

  double _getMaxScroll() {
    final dateRange = _maxDate - _minDate;
    final totalHeight = dateRange * _pixelsPerUnit + bufferZone * 2;
    return (totalHeight - _viewportHeight).clamp(0.0, double.infinity);
  }

  double dateToY(int date, double viewportHeight) {
    final dateRange = _maxDate - _minDate;
    if (dateRange <= 0) return viewportHeight / 2;

    final normalized = (date - _minDate) / dateRange;
    return normalized * viewportHeight * zoomLevel - scrollOffset + bufferZone;
  }

  DateRange getVisibleDateRange() {
    final dateRange = _maxDate - _minDate;
    if (dateRange <= 0)
      return DateRange(start: _minDate.round(), end: _maxDate.round());

    final startNorm =
        (scrollOffset - bufferZone) / (viewportHeight * zoomLevel);
    final endNorm =
        (scrollOffset + viewportHeight + bufferZone) /
        (viewportHeight * zoomLevel);

    final startDate = _minDate + startNorm * dateRange;
    final endDate = _minDate + endNorm * dateRange;

    return DateRange(start: startDate.round(), end: endDate.round());
  }

  List<TimelineEntry> getVisibleEntries(List<TimelineEntry> entries) {
    final range = getVisibleDateRange();
    final buffer = (range.end - range.start) * 0.1; // 10% buffer

    return entries.where((entry) {
      return entry.date >= (range.start - buffer) &&
          entry.date <= (range.end + buffer);
    }).toList();
  }

  void invalidateLayout() {
    _recalculatePixelsPerUnit();
  }
}
