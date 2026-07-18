# Timelines 项目设计文档

---

## 1. 架构概览

### 1.1 分层架构

```
┌─────────────────────────────────────────────┐
│              表示层 (Views)                  │
│  TimelineWidget / SearchWidget / FilterPanel │
├─────────────────────────────────────────────┤
│              业务层 (Providers/Services)      │
│  Riverpod Providers / SearchManager / Loader │
├─────────────────────────────────────────────┤
│              数据层 (Models/Repository)       │
│  TimelineEntry / TimelineSource / JSON 解析   │
└─────────────────────────────────────────────┘
```

### 1.2 数据流

```
JSON 文件 → DataLoaderService → DataSourceProvider
                                      ↓
                              TimelineProvider ← FilterProvider
                                      ↓
                              合并/过滤后的事件列表
                                      ↓
                          TimelineRenderBox (渲染)
```

### 1.3 核心设计原则

- **数据驱动**：JSON 文件是唯一数据来源，代码不包含硬编码内容
- **单向数据流**：数据从加载→状态→渲染，用户操作通过 Provider 修改状态触发重渲染
- **视口裁剪**：仅渲染可见区域事件，支持数千条数据流畅显示
- **关注点分离**：渲染逻辑、业务逻辑、数据加载各自独立

---

## 2. 数据模型设计

### 2.1 TimelineEntry（事件条目）

```dart
class TimelineEntry {
  final int date;           // 时间戳，负数表示公元前
  final String label;       // 事件标题（纯文本，显示在时间轴上）
  final String? summary;    // Markdown 简述，气泡中显示
  final String? description;// HTML 文件名，详情页展示
  final EntryType type;     // era 或 incident
  final Color? background;  // 背景色
  final Color? accent;      // 强调色
  final String sourceId;    // 所属数据源 ID
}
```

### 2.2 TimelineSource（数据源）

```dart
class TimelineSource {
  final String id;
  final TimelineMetadata metadata;
  final List<TimelineEntry> events;
}
```

### 2.3 TimelineMetadata（元数据）

```dart
class TimelineMetadata {
  final String name;
  final String version;
  final String description;
  final ColorScheme colorScheme;
}
```

### 2.4 JSON 数据格式

```json
{
  "metadata": {
    "name": "数据源名称",
    "version": "1.0",
    "description": "数据源描述",
    "colorScheme": { "primary": "#FF5722", "secondary": "#FFC107" }
  },
  "events": [
    {
      "date": -13800000000,
      "label": "事件标题",
      "summary": "Markdown 格式简述",
      "description": "description_file.html",
      "type": "incident",
      "background": [0, 38, 75],
      "accent": [246, 76, 130, 255]
    }
  ]
}
```

**设计要点：**

- 模型类提供 `fromJson` / `toJson` 工厂方法
- 使用 Dart 3 的 record 或 immutable class + `copyWith`
- 时间值使用 `int`（支持负数表示公元前）
- 颜色使用 `List<int>` 存储，渲染时转换为 `Color`

---

## 3. 库选型对比

### 3.1 状态管理

| 方案 | 优点 | 缺点 | 适用性 |
|------|------|------|--------|
| **Riverpod** | 编译时安全、无需 `BuildContext`、支持代码生成、官方推荐 | 学习曲线略高 | **选择** — 需求明确要求，且适合复杂状态 |
| BLoC | 分层清晰、测试友好 | 模板代码多、依赖 `stream` | 备选，但需求已定 Riverpod |
| Provider | 简单易用 | 依赖 `BuildContext`、运行时错误 | 不满足大型项目需求 |
| GetX | 开发速度快 | 非官方、魔法多、社区争议 | 不推荐 |

**选择依据：** 需求规格 REQ-ARCH-STATE-001 明确要求使用 Riverpod，且 Riverpod 是 Provider 的升级版，具备编译时安全和更好的可测试性。

### 3.2 Markdown 渲染

| 方案 | 优点 | 缺点 | 适用性 |
|------|------|------|--------|
| **flutter_markdown** | 官方维护、功能完整、支持自定义样式 | 包体积较大 | **选择** — 官方支持，稳定可靠 |
| markdown_widget | 轻量、自定义灵活 | 社区维护 | 备选 |
| 自行解析 | 完全控制 | 开发成本高、易出错 | 不推荐 |

**选择依据：** `flutter_markdown` 由 Flutter 官方团队维护，支持标准 Markdown 语法和自定义样式构建器，适合简述气泡的渲染需求。

### 3.3 HTML 渲染

| 方案 | 优点 | 缺点 | 适用性 |
|------|------|------|--------|
| **flutter_widget_from_html** | 功能全面、支持 CSS、活跃维护 | 包体积较大 | **选择** — 功能最完整 |
| flutter_html | 简单易用 | 功能有限、维护频率低 | 备选 |
| webview_flutter | 完整浏览器能力 | 性能开销大、交互复杂 | 过重，不推荐 |

**选择依据：** 详情页需要渲染完整的 HTML 内容，`flutter_widget_from_html` 支持大部分 HTML 标签和 CSS 样式，且将 HTML 转换为 Flutter Widget，性能优于 WebView。

### 3.4 本地持久化存储

| 方案 | 优点 | 缺点 | 适用性 |
|------|------|------|--------|
| **shared_preferences** | 简单易用、官方支持、跨平台 | 仅适合小数据、不支持复杂查询 | **选择** — 筛选状态等简单配置 |
| sqflite | 功能完整、支持复杂查询 | 依赖原生代码、包体积大 | 过重 |
| hive | 纯 Dart、高性能 | 社区维护 | 备选 |
| isar | 现代 NoSQL、类型安全 | 较新、生态不成熟 | 不推荐 |

**选择依据：** 需要持久化的数据仅为筛选状态（数据源可见性 Map），数据量小，`shared_preferences` 足够满足需求且无额外依赖。

### 3.5 路径与文件操作

| 方案 | 优点 | 缺点 | 适用性 |
|------|------|------|--------|
| **path_provider** | 官方支持、跨平台路径 | 仅获取路径 | **选择** — 获取数据目录 |
| **path** | 官方支持、路径操作工具 | 无 | **选择** — 路径拼接 |

**选择依据：** 两者均为 Dart 官方维护的生态库，跨平台兼容性好，是文件操作的标准组合。

### 3.6 国际化

| 方案 | 优点 | 缺点 | 适用性 |
|------|------|------|--------|
| **flutter_localizations + intl** | 官方支持、标准方案 | 配置略繁琐 | **选择** — 需求明确要求 |
| easy_localization | 开发效率高 | 非官方 | 备选 |

**选择依据：** 需求 REQ-I18N-001 要求支持中文默认和英文本地化，官方方案最稳定且长期维护有保障。

---

## 4. 核心模块详细设计

### 4.1 数据层

#### 4.1.1 数据源自动发现

**服务类：** `DataLoaderService`

**职责：**
1. 扫描固定目录 `data/` 下的所有 `.json` 文件
2. 读取配置文件 `data_sources.json`（可选）
3. 解析 JSON 为 `TimelineSource` 对象
4. 异步加载，不阻塞 UI

**流程：**
```
应用启动
  → DataLoaderService.discoverSources()
  → 扫描 data/ 目录 → 获取 .json 文件列表
  → 读取 data_sources.json（如存在）→ 过滤/排序
  → 逐个解析 JSON → 构建 TimelineSource 列表
  → 通知 DataSourceProvider 更新状态
```

**错误处理：**
- 单个文件解析失败不影响其他文件加载
- 记录错误日志，UI 显示加载失败的数据源数量
- 支持重试机制

#### 4.1.2 DataSourceProvider

**状态定义：**
```dart
@riverpod
class DataSourceNotifier extends _$DataSourceNotifier {
  @override
  DataSourceState build() => DataSourceState.initial();
  
  Future<void> loadSources() async { ... }
}

class DataSourceState {
  final List<TimelineSource> sources;
  final LoadingStatus status; // loading, success, error
  final String? errorMessage;
}
```

**职责：**
- 管理所有数据源的加载状态
- 提供数据源列表给其他 Provider
- 响应数据源变更事件

### 4.2 时间线渲染系统

#### 4.2.1 架构

```
TimelineWidget (StatefulWidget)
  └─ CustomPaint
      └─ TimelineRenderBox (RenderBox)
          ├─ 视口裁剪计算
          ├─ 时间→位置映射
          ├─ 绘制时间轴线
          ├─ 绘制事件节点
          └─ 绘制标签文本
```

#### 4.2.2 TimelineRenderBox

**核心方法：**

- `performLayout()`: 计算尺寸
- `paint(Canvas, Offset)`: 执行绘制
- `hitTestSelf/hitTestChildren()`: 处理点击
- `computeVisualRect()`: 计算可视区域

**绘制流程：**
```
1. 根据视口偏移和缩放级别计算可见时间范围
2. 过滤出可见时间范围内的事件
3. 对每个可见事件：
   a. 计算 Y 坐标（时间→位置映射）
   b. 绘制时间轴连接线和节点
   c. 绘制标签文本
   d. 应用数据源颜色编码
4. 使用 PictureLayer 缓存静态元素
```

**性能优化：**
- 视口裁剪：仅绘制可见区域 + 缓冲区的事件
- 静态缓存：时间轴线、刻度等静态元素缓存为 `ui.Picture`
- RepaintBoundary：隔离动画区域，减少重绘范围
- 30fps 限制：使用 `SchedulerBinding.scheduleFrameCallback` 控制帧率

#### 4.2.3 手势与交互

**手势识别：**
- 垂直滚动：`GestureDetector.onVerticalDragUpdate`
- 捏合缩放：`GestureDetector.onScaleUpdate`
- 点击事件：`TapGestureRecognizer`（通过 `hitTest` 定位）

**滚动物理：**
- 使用 `ScrollPhysics` 或自定义物理模拟
- 边界反弹效果
- 惯性滚动

### 4.3 搜索系统

#### 4.3.1 前缀树（Trie）

**数据结构：**
```dart
class PrefixTreeNode {
  Map<String, PrefixTreeNode> children = {};
  List<TimelineEntry> entries = [];
}

class PrefixTree {
  PrefixTreeNode root = PrefixTreeNode();
  
  void insert(String word, TimelineEntry entry) { ... }
  List<TimelineEntry> search(String prefix) { ... }
}
```

**分词算法：**
1. 按空格分割
2. 识别驼峰命名（`camelCase` → `camel`, `Case`）
3. 识别连字符/下划线分割
4. 统一转小写

**索引构建：**
- 异步构建，不阻塞 UI
- 对每个事件的 `label` 和 `summary` 进行分词
- 每个词插入前缀树，关联到对应事件

#### 4.3.2 SearchManager

**职责：**
- 管理搜索状态（查询词、结果、建议）
- 实现 350ms 防抖
- 多词 AND 查询
- 大小写无关匹配

**流程：**
```
用户输入
  → 350ms 防抖等待
  → 分词处理
  → 对每个词查询前缀树
  → 取交集（AND）
  → 按时间排序
  → 更新搜索结果状态
```

### 4.4 筛选系统

#### 4.4.1 FilterProvider

**状态定义：**
```dart
@riverpod
class FilterNotifier extends _$FilterNotifier {
  @override
  FilterState build() => FilterState.initial();
  
  void toggleSource(String sourceId) { ... }
  void selectAll() { ... }
  void deselectAll() { ... }
  Future<void> loadPersistedState() async { ... }
  Future<void> persistState() async { ... }
}

class FilterState {
  final Map<String, bool> sourceVisibility; // sourceId -> isVisible
}
```

**持久化：**
- 使用 `shared_preferences` 存储 `Map<String, bool>`
- 状态变更时自动持久化
- 应用启动时加载已保存的筛选状态

### 4.5 视图模式

#### 4.5.1 合并视图

**实现：**
- 将所有启用的数据源事件合并为一个列表
- 按时间排序
- 使用数据源颜色编码区分事件
- 单个 `TimelineWidget` 渲染

#### 4.5.2 对比视图

**实现：**
- 水平排列多个 `TimelineWidget`
- 每个数据源一个独立时间轴
- 使用 `ScrollController` 同步滚动
- 缩放级别同步变更

**同步机制：**
```dart
// 监听任一时间轴的滚动/缩放事件
// 同步更新其他时间轴的视口参数
```

### 4.6 文章系统

#### 4.6.1 简述气泡

**组件：** `SummaryBubble`

**实现：**
- 使用 `flutter_markdown` 渲染 Markdown 内容
- 气泡位置根据事件标签位置计算
- 点击标签时显示，点击外部时隐藏
- 底部"详情"按钮跳转到详情页

#### 4.6.2 详情页

**页面：** `DetailPage`

**实现：**
- 使用 `flutter_widget_from_html` 渲染 HTML 内容
- 从 `assets/` 或 `data/` 目录加载 HTML 文件
- 显示事件元信息（标签、数据源、时间）
- 提供返回导航

---

## 5. 性能设计

### 5.1 渲染性能

| 优化策略 | 实现方式 | 目标 |
|---------|---------|------|
| 视口裁剪 | 仅绘制可见区域 + 缓冲区的事件 | 减少绘制开销 |
| 静态缓存 | 时间轴线等静态元素缓存为 `ui.Picture` | 减少重绘 |
| RepaintBoundary | 隔离动画区域 | 限制重绘范围 |
| 30fps 限制 | 帧调度控制 | 降低功耗 |
| 稳态检测 | 用户停止交互后减少渲染频率 | 节省资源 |

### 5.2 内存优化

- 大数据集懒加载
- 图片/资源缓存管理
- 未使用的 `TimelineSource` 及时释放

### 5.3 加载优化

- 数据源并行加载
- 异步索引构建
- 进度指示器反馈

---

## 6. 测试策略

| 测试类型 | 覆盖范围 | 工具 |
|---------|---------|------|
| 单元测试 | 数据模型、搜索算法、筛选逻辑、Provider | `flutter_test` |
| Widget 测试 | UI 组件功能 | `flutter_test` |
| 集成测试 | 完整用户流程 | `integration_test` |
| 性能测试 | 帧率、内存使用 | `flutter_driver` |

**覆盖率目标：** 85%+

---

## 7. 目录结构

```
lib/
├── main.dart                    # 应用入口
├── app.dart                     # 应用配置
├── providers/                   # Riverpod Providers
│   ├── data_source_provider.dart
│   ├── timeline_provider.dart
│   ├── search_provider.dart
│   ├── filter_provider.dart
│   └── view_mode_provider.dart
├── models/                      # 数据模型
│   ├── timeline_entry.dart
│   ├── timeline_source.dart
│   └── timeline_metadata.dart
├── services/                    # 业务服务
│   ├── data_loader.dart
│   ├── search_manager.dart
│   └── prefix_tree.dart
├── timeline/                    # 时间线核心
│   ├── timeline_widget.dart
│   ├── timeline_render_box.dart
│   ├── timeline_layout.dart
│   └── timeline_viewport.dart
├── views/                       # 视图模式
│   ├── merged_view.dart
│   └── compare_view.dart
├── filter/                      # 筛选系统
│   └── filter_panel.dart
├── search/                      # 搜索系统
│   ├── search_widget.dart
│   └── search_results.dart
├── article/                     # 文章/详情
│   ├── summary_bubble.dart
│   └── detail_page.dart
├── l10n/                        # 国际化
│   ├── app_zh.arb
│   └── app_en.arb
└── utils/                       # 工具类
    ├── color_utils.dart
    └── time_utils.dart
```

---

## 8. 依赖清单

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  flutter_riverpod: ^2.6.1       # 状态管理
  intl: ^0.20.2                  # 国际化
  shared_preferences: ^2.5.5     # 本地持久化
  flutter_markdown: ^0.7.0       # Markdown 渲染
  flutter_widget_from_html: ^0.15.0  # HTML 渲染
  path_provider: ^2.1.0          # 路径获取
  path: ^1.9.0                   # 路径操作

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0          # 代码规范
```

---

## 9. 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|---------|
| 自定义 RenderBox 复杂度高 | 开发周期长 | 参考 Flutter 官方示例，分阶段实现 |
| 大数据集性能 | 卡顿 | 严格视口裁剪，懒加载 |
| HTML 渲染兼容性 | 内容显示异常 | 限制 HTML 标签范围，提供降级方案 |
| 跨平台差异 | 行为不一致 | 充分测试各平台，使用平台判断 |

---

*文档版本：1.0*  
*创建日期：2026年7月*
