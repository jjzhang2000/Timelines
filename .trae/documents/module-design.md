# Timelines 模块详细设计文档

---

## 1. 数据模型层（Models）

### 1.1 TimelineEntry（时间线条目）

**文件路径**: `lib/models/timeline_entry.dart`

#### 1.1.1 类定义

```dart
enum EntryType { era, incident }

class TimelineEntry {
  final int date;           // 时间戳，负数表示公元前
  final String label;       // 事件标题（纯文本）
  final String? summary;    // Markdown 简述
  final String? description;// HTML 文件名
  final EntryType type;     // 类型：时代或事件
  final Color? background;  // 背景色
  final Color? accent;      // 强调色
  final String sourceId;    // 所属数据源 ID
  
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
  
  // 工厂方法
  factory TimelineEntry.fromJson(Map<String, dynamic> json, String sourceId);
  Map<String, dynamic> toJson();
  
  // 复制方法
  TimelineEntry copyWith({
    int? date,
    String? label,
    String? summary,
    String? description,
    EntryType? type,
    Color? background,
    Color? accent,
    String? sourceId,
  });
}
```

#### 1.1.2 关键实现细节

**fromJson 实现**:
```dart
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
      ? _colorFromList(json['background'] as List<int>)
      : null,
    accent: json['accent'] != null 
      ? _colorFromList(json['accent'] as List<int>)
      : null,
    sourceId: sourceId,
  );
}

static Color _colorFromList(List<int> list) {
  if (list.length == 3) {
    return Color.fromARGB(255, list[0], list[1], list[2]);
  } else if (list.length == 4) {
    return Color.fromARGB(list[3], list[0], list[1], list[2]);
  }
  throw ArgumentError('Invalid color list length: ${list.length}');
}
```

**toJson 实现**:
```dart
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

List<int> _colorToList(Color color) {
  return [color.red, color.green, color.blue, color.alpha];
}
```

#### 1.1.3 设计要点

- **不可变性**: 所有字段为 `final`，确保线程安全
- **可选字段**: `summary` 和 `description` 为可选，允许部分事件不包含详细内容
- **颜色解析**: 支持 RGB（3元素）和 RGBA（4元素）两种格式
- **类型安全**: 使用枚举 `EntryType` 而非字符串，避免拼写错误

---

### 1.2 TimelineSource（数据源）

**文件路径**: `lib/models/timeline_source.dart`

#### 1.2.1 类定义

```dart
class TimelineSource {
  final String id;
  final TimelineMetadata metadata;
  final List<TimelineEntry> events;
  
  const TimelineSource({
    required this.id,
    required this.metadata,
    required this.events,
  });
  
  factory TimelineSource.fromJson(String id, Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

#### 1.2.2 关键实现细节

**fromJson 实现**:
```dart
factory TimelineSource.fromJson(String id, Map<String, dynamic> json) {
  final metadata = TimelineMetadata.fromJson(json['metadata'] as Map<String, dynamic>);
  final eventsJson = json['events'] as List<dynamic>;
  final events = eventsJson
    .map((e) => TimelineEntry.fromJson(e as Map<String, dynamic>, id))
    .toList();
  
  return TimelineSource(
    id: id,
    metadata: metadata,
    events: events,
  );
}
```

#### 1.2.3 设计要点

- **ID 生成**: 使用文件名（不含扩展名）作为唯一标识
- **事件关联**: 每个事件通过 `sourceId` 关联到数据源
- **批量解析**: 一次性解析所有事件，避免多次 IO 操作

---

### 1.3 TimelineMetadata（元数据）

**文件路径**: `lib/models/timeline_metadata.dart`

#### 1.3.1 类定义

```dart
class TimelineMetadata {
  final String name;
  final String version;
  final String description;
  final TimelineColorScheme colorScheme;
  
  const TimelineMetadata({
    required this.name,
    required this.version,
    required this.description,
    required this.colorScheme,
  });
  
  factory TimelineMetadata.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}

class TimelineColorScheme {
  final Color primary;
  final Color secondary;
  
  const TimelineColorScheme({
    required this.primary,
    required this.secondary,
  });
  
  factory TimelineColorScheme.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

#### 1.3.2 关键实现细节

**颜色解析**:
```dart
factory TimelineColorScheme.fromJson(Map<String, dynamic> json) {
  return TimelineColorScheme(
    primary: _hexToColor(json['primary'] as String),
    secondary: _hexToColor(json['secondary'] as String),
  );
}

static Color _hexToColor(String hex) {
  hex = hex.replaceFirst('#', '');
  if (hex.length == 6) {
    hex = 'FF$hex'; // 添加不透明度
  }
  return Color(int.parse(hex, radix: 16));
}
```

---

## 2. 数据加载服务（DataLoader）

### 2.1 DataLoaderService

**文件路径**: `lib/services/data_loader.dart`

#### 2.1.1 类定义

```dart
class DataLoaderService {
  final String dataDirectory;
  final String? configFile;
  
  DataLoaderService({
    required this.dataDirectory,
    this.configFile,
  });
  
  /// 发现并加载所有数据源
  Future<List<TimelineSource>> discoverSources();
  
  /// 从配置文件加载数据源列表
  Future<List<String>> _loadConfigFile();
  
  /// 扫描目录获取 JSON 文件
  Future<List<File>> _scanDirectory();
  
  /// 解析单个 JSON 文件
  Future<TimelineSource> _parseFile(File file);
}
```

#### 2.1.2 关键实现细节

**discoverSources 实现**:
```dart
Future<List<TimelineSource>> discoverSources() async {
  List<File> files;
  
  // 优先使用配置文件
  if (configFile != null) {
    final configFiles = await _loadConfigFile();
    files = configFiles.map((path) => File(path)).toList();
  } else {
    files = await _scanDirectory();
  }
  
  // 并行解析所有文件
  final sources = await Future.wait(
    files.map((file) => _parseFile(file)).toList(),
  );
  
  return sources;
}
```

**_scanDirectory 实现**:
```dart
Future<List<File>> _scanDirectory() async {
  final dir = Directory(dataDirectory);
  if (!await dir.exists()) {
    throw DirectoryNotFoundException('Data directory not found: $dataDirectory');
  }
  
  final files = await dir
    .list(recursive: false)
    .where((entity) => entity is File && entity.path.endsWith('.json'))
    .cast<File>()
    .toList();
  
  return files;
}
```

**_parseFile 实现**:
```dart
Future<TimelineSource> _parseFile(File file) async {
  final content = await file.readAsString();
  final json = jsonDecode(content) as Map<String, dynamic>;
  final id = p.basenameWithoutExtension(file.path);
  
  return TimelineSource.fromJson(id, json);
}
```

#### 2.1.3 错误处理

```dart
class DataLoaderException implements Exception {
  final String message;
  final File? file;
  final Exception? cause;
  
  DataLoaderException(this.message, {this.file, this.cause});
  
  @override
  String toString() => 'DataLoaderException: $message';
}

class DirectoryNotFoundException extends DataLoaderException {
  DirectoryNotFoundException(String message) : super(message);
}

class JsonParseException extends DataLoaderException {
  JsonParseException(String message, {File? file, Exception? cause})
    : super(message, file: file, cause: cause);
}
```

**错误处理策略**:
- 单个文件解析失败不影响其他文件
- 记录错误日志，返回成功加载的数据源
- 提供详细的错误信息（文件名、行号、错误类型）

#### 2.1.4 设计要点

- **异步加载**: 所有 IO 操作使用 `async/await`，不阻塞 UI
- **并行解析**: 使用 `Future.wait` 并行解析多个文件
- **配置优先**: 支持配置文件指定数据源列表
- **错误隔离**: 单个文件失败不影响整体加载

---

## 3. 状态管理层（Providers）

### 3.1 DataSourceProvider

**文件路径**: `lib/providers/data_source_provider.dart`

#### 3.1.1 状态定义

```dart
enum LoadingStatus { initial, loading, success, error }

class DataSourceState {
  final List<TimelineSource> sources;
  final LoadingStatus status;
  final String? errorMessage;
  final List<String> failedFiles; // 加载失败的文件列表
  
  const DataSourceState({
    this.sources = const [],
    this.status = LoadingStatus.initial,
    this.errorMessage,
    this.failedFiles = const [],
  });
  
  DataSourceState copyWith({
    List<TimelineSource>? sources,
    LoadingStatus? status,
    String? errorMessage,
    List<String>? failedFiles,
  });
  
  factory DataSourceState.initial() => const DataSourceState();
  factory DataSourceState.loading() => const DataSourceState(status: LoadingStatus.loading);
  factory DataSourceState.success(List<TimelineSource> sources, {List<String>? failedFiles}) 
    => DataSourceState(
        sources: sources,
        status: LoadingStatus.success,
        failedFiles: failedFiles ?? [],
      );
  factory DataSourceState.error(String message, {List<String>? failedFiles})
    => DataSourceState(
        errorMessage: message,
        status: LoadingStatus.error,
        failedFiles: failedFiles ?? [],
      );
}
```

#### 3.1.2 Provider 定义

```dart
@riverpod
class DataSourceNotifier extends _$DataSourceNotifier {
  @override
  DataSourceState build() => DataSourceState.initial();
  
  Future<void> loadSources() async {
    state = DataSourceState.loading();
    
    try {
      final service = DataLoaderService(
        dataDirectory: 'data',
        configFile: 'data/data_sources.json',
      );
      
      final sources = await service.discoverSources();
      state = DataSourceState.success(sources);
    } catch (e) {
      state = DataSourceState.error(e.toString());
    }
  }
  
  void addSource(TimelineSource source) {
    state = state.copyWith(
      sources: [...state.sources, source],
    );
  }
  
  void removeSource(String sourceId) {
    state = state.copyWith(
      sources: state.sources.where((s) => s.id != sourceId).toList(),
    );
  }
}
```

#### 3.1.3 设计要点

- **状态不可变**: 使用 `copyWith` 创建新状态
- **工厂方法**: 提供便捷的状态构造方法
- **错误恢复**: 支持重试机制（重新调用 `loadSources`）
- **失败记录**: 记录加载失败的文件，便于调试

---

### 3.2 FilterProvider

**文件路径**: `lib/providers/filter_provider.dart`

#### 3.2.1 状态定义

```dart
class FilterState {
  final Map<String, bool> sourceVisibility; // sourceId -> isVisible
  
  const FilterState({
    this.sourceVisibility = const {},
  });
  
  FilterState copyWith({
    Map<String, bool>? sourceVisibility,
  });
  
  bool isVisible(String sourceId) => sourceVisibility[sourceId] ?? true;
}
```

#### 3.2.2 Provider 定义

```dart
@riverpod
class FilterNotifier extends _$FilterNotifier {
  late final SharedPreferences _prefs;
  
  @override
  FilterState build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    _loadPersistedState();
    return const FilterState();
  }
  
  void _loadPersistedState() {
    final json = _prefs.getString('filter_state');
    if (json != null) {
      final map = Map<String, bool>.from(jsonDecode(json));
      state = FilterState(sourceVisibility: map);
    }
  }
  
  Future<void> _persistState() async {
    final json = jsonEncode(state.sourceVisibility);
    await _prefs.setString('filter_state', json);
  }
  
  void toggleSource(String sourceId) {
    final current = state.isVisible(sourceId);
    state = state.copyWith(
      sourceVisibility: {
        ...state.sourceVisibility,
        sourceId: !current,
      },
    );
    _persistState();
  }
  
  void selectAll() {
    final map = Map<String, bool>.from(state.sourceVisibility);
    for (final key in map.keys) {
      map[key] = true;
    }
    state = FilterState(sourceVisibility: map);
    _persistState();
  }
  
  void deselectAll() {
    final map = Map<String, bool>.from(state.sourceVisibility);
    for (final key in map.keys) {
      map[key] = false;
    }
    state = FilterState(sourceVisibility: map);
    _persistState();
  }
  
  void initializeSources(List<String> sourceIds) {
    final map = Map<String, bool>.from(state.sourceVisibility);
    for (final id in sourceIds) {
      map.putIfAbsent(id, () => true); // 默认显示
    }
    state = FilterState(sourceVisibility: map);
  }
}
```

#### 3.2.3 设计要点

- **自动持久化**: 状态变更时自动保存到 `SharedPreferences`
- **默认显示**: 新数据源默认显示
- **批量操作**: 支持全选/全不选
- **初始化**: 根据数据源列表初始化可见性状态

---

### 3.3 TimelineProvider

**文件路径**: `lib/providers/timeline_provider.dart`

#### 3.3.1 状态定义

```dart
class TimelineState {
  final List<TimelineEntry> entries;
  final int? selectedEntryIndex;
  
  const TimelineState({
    this.entries = const [],
    this.selectedEntryIndex,
  });
  
  TimelineState copyWith({
    List<TimelineEntry>? entries,
    int? selectedEntryIndex,
  });
}
```

#### 3.3.2 Provider 定义

```dart
@riverpod
class TimelineNotifier extends _$TimelineNotifier {
  @override
  TimelineState build() {
    final dataSourceState = ref.watch(dataSourceNotifierProvider);
    final filterState = ref.watch(filterNotifierProvider);
    
    if (dataSourceState.status != LoadingStatus.success) {
      return const TimelineState();
    }
    
    // 合并所有启用的数据源事件
    final entries = <TimelineEntry>[];
    for (final source in dataSourceState.sources) {
      if (filterState.isVisible(source.id)) {
        entries.addAll(source.events);
      }
    }
    
    // 按时间排序
    entries.sort((a, b) => a.date.compareTo(b.date));
    
    return TimelineState(entries: entries);
  }
  
  void selectEntry(int index) {
    state = state.copyWith(selectedEntryIndex: index);
  }
  
  void clearSelection() {
    state = state.copyWith(selectedEntryIndex: null);
  }
}
```

#### 3.3.3 设计要点

- **响应式更新**: 监听数据源和筛选状态变化，自动重新计算
- **合并排序**: 将多个数据源的事件合并并按时间排序
- **过滤集成**: 根据筛选状态过滤事件
- **选择管理**: 支持选中/取消选中事件

---

### 3.4 SearchProvider

**文件路径**: `lib/providers/search_provider.dart`

#### 3.4.1 状态定义

```dart
class SearchState {
  final String query;
  final List<TimelineEntry> results;
  final List<String> suggestions;
  final bool isSearching;
  
  const SearchState({
    this.query = '',
    this.results = const [],
    this.suggestions = const [],
    this.isSearching = false,
  });
  
  SearchState copyWith({
    String? query,
    List<TimelineEntry>? results,
    List<String>? suggestions,
    bool? isSearching,
  });
}
```

#### 3.4.2 Provider 定义

```dart
@riverpod
class SearchNotifier extends _$SearchNotifier {
  late final SearchManager _searchManager;
  Timer? _debounceTimer;
  
  @override
  SearchState build() {
    _searchManager = ref.watch(searchManagerProvider);
    ref.onDispose(() => _debounceTimer?.cancel());
    return const SearchState();
  }
  
  void updateQuery(String query) {
    state = state.copyWith(query: query, isSearching: true);
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _performSearch(query);
    });
  }
  
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      state = const SearchState();
      return;
    }
    
    final results = await _searchManager.search(query);
    final suggestions = await _searchManager.getSuggestions(query);
    
    state = SearchState(
      query: query,
      results: results,
      suggestions: suggestions,
      isSearching: false,
    );
  }
  
  void clearSearch() {
    _debounceTimer?.cancel();
    state = const SearchState();
  }
}
```

#### 3.4.3 设计要点

- **防抖机制**: 350ms 防抖，避免频繁搜索
- **异步搜索**: 搜索操作在后台执行，不阻塞 UI
- **自动补全**: 提供搜索建议
- **资源清理**: 组件销毁时取消定时器和异步操作

---

### 3.5 ViewModeProvider

**文件路径**: `lib/providers/view_mode_provider.dart`

#### 3.5.1 状态定义

```dart
enum ViewMode { merged, compare }

class ViewModeState {
  final ViewMode mode;
  final List<String> compareSourceIds; // 对比视图选中的数据源
  
  const ViewModeState({
    this.mode = ViewMode.merged,
    this.compareSourceIds = const [],
  });
  
  ViewModeState copyWith({
    ViewMode? mode,
    List<String>? compareSourceIds,
  });
}
```

#### 3.5.2 Provider 定义

```dart
@riverpod
class ViewModeNotifier extends _$ViewModeNotifier {
  late final SharedPreferences _prefs;
  
  @override
  ViewModeState build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    return _loadPersistedState();
  }
  
  ViewModeState _loadPersistedState() {
    final modeStr = _prefs.getString('view_mode') ?? 'merged';
    final compareIds = _prefs.getStringList('compare_sources') ?? [];
    
    return ViewModeState(
      mode: ViewMode.values.firstWhere((e) => e.name == modeStr),
      compareSourceIds: compareIds,
    );
  }
  
  Future<void> setMode(ViewMode mode) async {
    state = state.copyWith(mode: mode);
    await _prefs.setString('view_mode', mode.name);
  }
  
  Future<void> setCompareSources(List<String> sourceIds) async {
    state = state.copyWith(compareSourceIds: sourceIds);
    await _prefs.setStringList('compare_sources', sourceIds);
  }
}
```

#### 3.5.3 设计要点

- **模式切换**: 支持合并视图和对比视图切换
- **对比选择**: 对比视图支持选择 2-4 个数据源
- **状态持久化**: 视图模式和对比选择保存到本地

---

## 4. 搜索系统（Search）

### 4.1 PrefixTree（前缀树）

**文件路径**: `lib/services/prefix_tree.dart`

#### 4.1.1 类定义

```dart
class PrefixTreeNode {
  final Map<String, PrefixTreeNode> children = {};
  final Set<TimelineEntry> entries = {};
  
  void insert(String word, TimelineEntry entry);
  Set<TimelineEntry> search(String prefix);
  List<String> getSuggestions(String prefix, {int limit = 5});
}

class PrefixTree {
  final PrefixTreeNode root = PrefixTreeNode();
  
  void insert(String word, TimelineEntry entry);
  Set<TimelineEntry> search(String prefix);
  List<String> getSuggestions(String prefix, {int limit = 5});
  void clear();
}
```

#### 4.1.2 关键实现细节

**insert 实现**:
```dart
void insert(String word, TimelineEntry entry) {
  var node = root;
  for (final char in word.toLowerCase().split('')) {
    node = node.children.putIfAbsent(char, () => PrefixTreeNode());
  }
  node.entries.add(entry);
}
```

**search 实现**:
```dart
Set<TimelineEntry> search(String prefix) {
  var node = root;
  for (final char in prefix.toLowerCase().split('')) {
    node = node.children[char] ?? return {};
  }
  
  // 收集所有子节点中的条目
  final results = <TimelineEntry>{};
  _collectEntries(node, results);
  return results;
}

void _collectEntries(PrefixTreeNode node, Set<TimelineEntry> results) {
  results.addAll(node.entries);
  for (final child in node.children.values) {
    _collectEntries(child, results);
  }
}
```

**getSuggestions 实现**:
```dart
List<String> getSuggestions(String prefix, {int limit = 5}) {
  final suggestions = <String>[];
  _collectSuggestions(root, prefix.toLowerCase(), '', suggestions, limit);
  return suggestions;
}

void _collectSuggestions(
  PrefixTreeNode node,
  String target,
  String current,
  List<String> suggestions,
  int limit,
) {
  if (suggestions.length >= limit) return;
  
  if (target.isEmpty && node.entries.isNotEmpty) {
    suggestions.add(current);
  }
  
  for (final entry in node.children.entries) {
    if (target.isEmpty || entry.key == target[0]) {
      _collectSuggestions(
        entry.value,
        target.isEmpty ? '' : target.substring(1),
        current + entry.key,
        suggestions,
        limit,
      );
    }
  }
}
```

#### 4.1.3 设计要点

- **O(k) 查找**: k 为前缀长度，性能稳定
- **大小写无关**: 统一转小写存储和查询
- **建议生成**: 支持自动补全建议
- **内存优化**: 使用 `Set` 避免重复条目

---

### 4.2 SearchManager

**文件路径**: `lib/services/search_manager.dart`

#### 4.2.1 类定义

```dart
class SearchManager {
  final PrefixTree _prefixTree = PrefixTree();
  bool _isIndexBuilt = false;
  
  Future<void> buildIndex(List<TimelineSource> sources);
  Future<List<TimelineEntry>> search(String query);
  Future<List<String>> getSuggestions(String query, {int limit = 5});
  void clearIndex();
}
```

#### 4.2.2 关键实现细节

**buildIndex 实现**:
```dart
Future<void> buildIndex(List<TimelineSource> sources) async {
  if (_isIndexBuilt) return;
  
  await compute((sources) {
    final tree = PrefixTree();
    for (final source in sources) {
      for (final entry in source.events) {
        // 分词处理
        final words = _tokenize(entry.label);
        if (entry.summary != null) {
          words.addAll(_tokenize(entry.summary!));
        }
        
        for (final word in words) {
          tree.insert(word, entry);
        }
      }
    }
    return tree;
  }, sources).then((tree) {
    _prefixTree = tree;
    _isIndexBuilt = true;
  });
}

List<String> _tokenize(String text) {
  final words = <String>[];
  
  // 按空格分割
  final parts = text.split(RegExp(r'\s+'));
  
  for (final part in parts) {
    // 识别驼峰命名
    final camelParts = part.split(RegExp(r'(?=[A-Z])'));
    
    for (final camelPart in camelParts) {
      // 识别连字符/下划线
      final subParts = camelPart.split(RegExp(r'[-_]'));
      words.addAll(subParts.where((s) => s.isNotEmpty));
    }
  }
  
  return words.map((w) => w.toLowerCase()).toList();
}
```

**search 实现**:
```dart
Future<List<TimelineEntry>> search(String query) async {
  if (!_isIndexBuilt) {
    throw StateError('Search index not built');
  }
  
  final queryWords = _tokenize(query);
  if (queryWords.isEmpty) return [];
  
  // 多词 AND 查询
  Set<TimelineEntry>? results;
  for (final word in queryWords) {
    final wordResults = _prefixTree.search(word);
    if (results == null) {
      results = wordResults;
    } else {
      results = results.intersection(wordResults);
    }
  }
  
  final resultList = results?.toList() ?? [];
  resultList.sort((a, b) => a.date.compareTo(b.date));
  
  return resultList;
}
```

#### 4.2.3 设计要点

- **异步构建**: 使用 `compute` 在后台线程构建索引
- **分词算法**: 支持空格、驼峰、连字符、下划线分割
- **多词查询**: 多个词之间使用 AND 逻辑
- **结果排序**: 按时间顺序返回结果

---

## 5. 时间线渲染系统（Timeline）

### 5.1 TimelineRenderBox

**文件路径**: `lib/timeline/timeline_render_box.dart`

#### 5.1.1 类定义

```dart
class TimelineRenderBox extends RenderBox {
  List<TimelineEntry> entries;
  TimelineViewport viewport;
  Map<String, Color> sourceColors;
  
  TimelineRenderBox({
    required this.entries,
    required this.viewport,
    required this.sourceColors,
  });
  
  @override
  void performLayout();
  
  @override
  void paint(PaintingContext context, Offset offset);
  
  @override
  bool hitTestSelf(Offset position);
  
  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position});
}
```

#### 5.1.2 关键实现细节

**performLayout 实现**:
```dart
@override
void performLayout() {
  // 根据内容计算尺寸
  final height = _calculateTotalHeight();
  size = constraints.constrain(Size(double.infinity, height));
}

double _calculateTotalHeight() {
  if (entries.isEmpty) return 0;
  
  final minDate = entries.first.date;
  final maxDate = entries.last.date;
  final dateRange = maxDate - minDate;
  
  // 根据缩放级别计算高度
  return dateRange * viewport.pixelsPerUnit + viewport.bufferZone * 2;
}
```

**paint 实现**:
```dart
@override
void paint(PaintingContext context, Offset offset) {
  final canvas = context.canvas;
  
  // 应用视口变换
  canvas.save();
  canvas.translate(offset.dx, offset.dy - viewport.scrollOffset);
  
  // 绘制时间轴线
  _drawTimelineAxis(canvas);
  
  // 绘制可见事件
  final visibleEntries = _getVisibleEntries();
  for (final entry in visibleEntries) {
    _drawEntry(canvas, entry);
  }
  
  canvas.restore();
}

List<TimelineEntry> _getVisibleEntries() {
  final visibleRange = viewport.getVisibleRange();
  return entries.where((entry) {
    return entry.date >= visibleRange.start && entry.date <= visibleRange.end;
  }).toList();
}

void _drawEntry(Canvas canvas, TimelineEntry entry) {
  final y = _dateToY(entry.date);
  final color = sourceColors[entry.sourceId] ?? Colors.grey;
  
  // 绘制节点
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.fill;
  canvas.drawCircle(Offset(100, y), 8, paint);
  
  // 绘制标签
  final textPainter = TextPainter(
    text: TextSpan(
      text: entry.label,
      style: TextStyle(color: Colors.black, fontSize: 14),
    ),
  )..layout(maxWidth: 200);
  
  textPainter.paint(canvas, Offset(120, y - textPainter.height / 2));
}

double _dateToY(int date) {
  final minDate = entries.first.date;
  return (date - minDate) * viewport.pixelsPerUnit + viewport.bufferZone;
}
```

**hitTest 实现**:
```dart
@override
bool hitTestSelf(Offset position) => true;

@override
bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
  final adjustedY = position.dy + viewport.scrollOffset;
  
  for (final entry in entries) {
    final y = _dateToY(entry.date);
    final distance = (adjustedY - y).abs();
    
    if (distance < 20) { // 点击容差
      result.add(HitTestEntry(_TimelineHitTarget(entry)));
      return true;
    }
  }
  
  return false;
}
```

#### 5.1.3 性能优化

```dart
// 静态元素缓存
ui.Picture? _cachedAxisPicture;

void _drawTimelineAxis(Canvas canvas) {
  _cachedAxisPicture ??= _buildAxisPicture();
  canvas.drawPicture(_cachedAxisPicture!);
}

ui.Picture _buildAxisPicture() {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  // 绘制时间轴线和刻度
  // ...
  
  return recorder.endRecording();
}

// 视口变化时清除缓存
void invalidateCache() {
  _cachedAxisPicture = null;
}
```

#### 5.1.4 设计要点

- **视口裁剪**: 仅绘制可见区域 + 缓冲区的事件
- **静态缓存**: 时间轴线等静态元素缓存为 `Picture`
- **坐标映射**: 时间→Y 坐标的线性映射
- **点击检测**: 基于距离的容差检测

---

### 5.2 TimelineViewport

**文件路径**: `lib/timeline/timeline_viewport.dart`

#### 5.2.1 类定义

```dart
class TimelineViewport {
  double scrollOffset;      // 滚动偏移
  double zoomLevel;         // 缩放级别
  double pixelsPerUnit;     // 每单位时间的像素数
  double bufferZone;        // 缓冲区大小
  
  TimelineViewport({
    this.scrollOffset = 0,
    this.zoomLevel = 1.0,
    this.pixelsPerUnit = 1.0,
    this.bufferZone = 100,
  });
  
  TimelineViewport copyWith({
    double? scrollOffset,
    double? zoomLevel,
    double? pixelsPerUnit,
    double? bufferZone,
  });
  
  DateRange getVisibleRange();
  void scrollBy(double delta);
  void zoomBy(double factor);
}

class DateRange {
  final int start;
  final int end;
  
  const DateRange({required this.start, required this.end});
}
```

#### 5.2.2 关键实现细节

**getVisibleRange 实现**:
```dart
DateRange getVisibleRange() {
  // 根据滚动偏移和缩放级别计算可见的时间范围
  final startY = scrollOffset - bufferZone;
  final endY = scrollOffset + viewportHeight + bufferZone;
  
  final startDate = _yToDate(startY);
  final endDate = _yToDate(endY);
  
  return DateRange(start: startDate, end: endDate);
}

int _yToDate(double y) {
  return ((y - bufferZone) / pixelsPerUnit).round();
}
```

**scrollBy 实现**:
```dart
void scrollBy(double delta) {
  scrollOffset += delta;
  // 限制边界
  scrollOffset = scrollOffset.clamp(0.0, maxScrollOffset);
}
```

**zoomBy 实现**:
```dart
void zoomBy(double factor) {
  zoomLevel *= factor;
  zoomLevel = zoomLevel.clamp(0.1, 10.0); // 限制缩放范围
  pixelsPerUnit = basePixelsPerUnit * zoomLevel;
}
```

#### 5.2.3 设计要点

- **视口管理**: 管理滚动偏移和缩放级别
- **范围计算**: 计算当前可见的时间范围
- **边界限制**: 防止滚动超出内容范围
- **缩放控制**: 限制缩放级别范围

---

## 6. 筛选系统（Filter）

### 6.1 FilterPanel

**文件路径**: `lib/filter/filter_panel.dart`

#### 6.1.1 Widget 定义

```dart
class FilterPanel extends ConsumerWidget {
  const FilterPanel({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataSourceState = ref.watch(dataSourceNotifierProvider);
    final filterState = ref.watch(filterNotifierProvider);
    
    return Column(
      children: [
        // 全选/全不选按钮
        _buildActionButtons(ref),
        
        // 数据源列表
        Expanded(
          child: ListView.builder(
            itemCount: dataSourceState.sources.length,
            itemBuilder: (context, index) {
              final source = dataSourceState.sources[index];
              return _buildSourceItem(ref, source, filterState);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButtons(WidgetRef ref) {
    return Row(
      children: [
        TextButton(
          onPressed: () => ref.read(filterNotifierProvider.notifier).selectAll(),
          child: const Text('全选'),
        ),
        TextButton(
          onPressed: () => ref.read(filterNotifierProvider.notifier).deselectAll(),
          child: const Text('全不选'),
        ),
      ],
    );
  }
  
  Widget _buildSourceItem(WidgetRef ref, TimelineSource source, FilterState filterState) {
    final isVisible = filterState.isVisible(source.id);
    
    return CheckboxListTile(
      value: isVisible,
      onChanged: (value) {
        ref.read(filterNotifierProvider.notifier).toggleSource(source.id);
      },
      title: Text(source.metadata.name),
      subtitle: Text('${source.events.length} 个事件'),
      secondary: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: source.metadata.colorScheme.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
```

#### 6.1.2 设计要点

- **响应式 UI**: 使用 `ref.watch` 监听状态变化
- **颜色标识**: 显示数据源的主色调
- **事件统计**: 显示每个数据源的事件数量
- **快捷操作**: 提供全选/全不选按钮

---

## 7. 视图模式（Views）

### 7.1 MergedView（合并视图）

**文件路径**: `lib/views/merged_view.dart`

#### 7.1.1 Widget 定义

```dart
class MergedView extends ConsumerWidget {
  const MergedView({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineState = ref.watch(timelineNotifierProvider);
    
    return TimelineWidget(
      entries: timelineState.entries,
      onEntryTap: (entry) {
        ref.read(timelineNotifierProvider.notifier).selectEntry(
          timelineState.entries.indexOf(entry),
        );
      },
    );
  }
}
```

#### 7.1.2 设计要点

- **单时间轴**: 所有事件在同一个时间轴上显示
- **颜色编码**: 使用数据源颜色区分事件
- **排序显示**: 事件按时间顺序排列

---

### 7.2 CompareView（对比视图）

**文件路径**: `lib/views/compare_view.dart`

#### 7.2.1 Widget 定义

```dart
class CompareView extends ConsumerStatefulWidget {
  const CompareView({super.key});
  
  @override
  ConsumerState<CompareView> createState() => _CompareViewState();
}

class _CompareViewState extends ConsumerState<CompareView> {
  final List<ScrollController> _controllers = [];
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }
  
  void _initializeControllers() {
    final viewModeState = ref.read(viewModeNotifierProvider);
    final dataSourceState = ref.read(dataSourceNotifierProvider);
    
    final sources = dataSourceState.sources
      .where((s) => viewModeState.compareSourceIds.contains(s.id))
      .toList();
    
    for (var i = 0; i < sources.length; i++) {
      final controller = ScrollController();
      controller.addListener(() => _syncScroll(i, controller.offset));
      _controllers.add(controller);
    }
  }
  
  void _syncScroll(int sourceIndex, double offset) {
    for (var i = 0; i < _controllers.length; i++) {
      if (i != sourceIndex) {
        _controllers[i].jumpTo(offset);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final viewModeState = ref.watch(viewModeNotifierProvider);
    final dataSourceState = ref.watch(dataSourceNotifierProvider);
    
    final sources = dataSourceState.sources
      .where((s) => viewModeState.compareSourceIds.contains(s.id))
      .toList();
    
    return Row(
      children: List.generate(sources.length, (index) {
        final source = sources[index];
        return Expanded(
          child: Column(
            children: [
              // 数据源标题
              Text(source.metadata.name),
              
              // 时间轴
              Expanded(
                child: TimelineWidget(
                  entries: source.events,
                  scrollController: _controllers[index],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
  
  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
```

#### 7.2.2 设计要点

- **多列布局**: 每个数据源一个独立的时间轴
- **同步滚动**: 监听任一滚动事件，同步其他时间轴
- **动态数量**: 支持 2-4 个数据源对比

---

## 8. 文章系统（Article）

### 8.1 SummaryBubble（简述气泡）

**文件路径**: `lib/article/summary_bubble.dart`

#### 8.1.1 Widget 定义

```dart
class SummaryBubble extends StatelessWidget {
  final TimelineEntry entry;
  final VoidCallback onDetailTap;
  
  const SummaryBubble({
    super.key,
    required this.entry,
    required this.onDetailTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Markdown 简述
          if (entry.summary != null)
            MarkdownBody(data: entry.summary!),
          
          const SizedBox(height: 8),
          
          // 详情按钮
          TextButton(
            onPressed: onDetailTap,
            child: const Text('详情'),
          ),
        ],
      ),
    );
  }
}
```

#### 8.1.2 设计要点

- **Markdown 渲染**: 使用 `flutter_markdown` 渲染简述内容
- **气泡样式**: 白色背景 + 阴影效果
- **详情入口**: 提供跳转到详情页的按钮

---

### 8.2 DetailPage（详情页）

**文件路径**: `lib/article/detail_page.dart`

#### 8.2.1 Widget 定义

```dart
class DetailPage extends StatelessWidget {
  final TimelineEntry entry;
  
  const DetailPage({
    super.key,
    required this.entry,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(entry.label),
      ),
      body: FutureBuilder<String>(
        future: _loadHtmlContent(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('加载失败: ${snapshot.error}'));
          }
          
          final htmlContent = snapshot.data ?? '';
          
          return SingleChildScrollView(
            child: HtmlWidget(
              htmlContent,
              textStyle: const TextStyle(fontSize: 16),
            ),
          );
        },
      ),
    );
  }
  
  Future<String> _loadHtmlContent() async {
    if (entry.description == null) return '';
    
    final file = File('data/${entry.description}');
    if (!await file.exists()) {
      throw Exception('HTML 文件不存在: ${entry.description}');
    }
    
    return await file.readAsString();
  }
}
```

#### 8.2.2 设计要点

- **HTML 渲染**: 使用 `flutter_widget_from_html` 渲染 HTML 内容
- **异步加载**: 从文件加载 HTML 内容
- **加载状态**: 显示加载进度和错误信息
- **返回导航**: 提供返回时间轴的功能

---

## 9. 工具类（Utils）

### 9.1 ColorUtils

**文件路径**: `lib/utils/color_utils.dart`

```dart
class ColorUtils {
  static Color hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
  
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }
  
  static Color interpolateColor(Color start, Color end, double t) {
    return Color.lerp(start, end, t)!;
  }
}
```

### 9.2 TimeUtils

**文件路径**: `lib/utils/time_utils.dart`

```dart
class TimeUtils {
  static String formatDate(int date) {
    if (date < 0) {
      return '公元前 ${-date} 年';
    }
    return '$date 年';
  }
  
  static String formatDuration(int start, int end) {
    final duration = end - start;
    if (duration < 100) {
      return '$duration 年';
    } else if (duration < 1000) {
      return '${(duration / 100).round()} 世纪';
    } else {
      return '${(duration / 1000).round()} 千年';
    }
  }
}
```

---

*文档版本：1.0*  
*创建日期：2026年7月*
