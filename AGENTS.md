# AGENTS.md - Timelines

## Project Overview

- **Purpose**: 通用历史时间线框架，通过加载 JSON 数据文件展示任意主题的历史时间线
- **Tech Stack**: Flutter (latest stable), Dart, Riverpod
- **Status**: 新项目，从零构建

## Architecture

### Entry Point

- `lib/main.dart` - 主入口，Riverpod ProviderScope
- 初始化流程：Riverpod providers → 数据源自动发现 → 时间线加载

### State Management

- **Riverpod** 作为唯一状态管理方案
- Providers 目录：`lib/providers/`
- 关键 providers：
  - `dataSourceProvider` - 数据源管理（自动发现、加载）
  - `timelineProvider` - 时间线实例
  - `searchManagerProvider` - 搜索管理
  - `filterProvider` - 筛选状态（数据源显示/隐藏）
  - `viewModeProvider` - 视图模式（合并/对比）

### Timeline System

- 自定义 RenderBox 实现高性能渲染
- 视口裁剪，仅渲染可见项目
- 30fps 渲染目标

### Data Flow

- 从固定文件夹自动扫描 JSON 文件
- 支持配置文件指定数据源列表
- 每个 JSON 文件包含 metadata 和 events
- 事件数据：label（标签）、summary（Markdown简述）、description（HTML描述）

## Key Directories

- `lib/` - 主源码
  - `lib/providers/` - Riverpod 状态管理
  - `lib/models/` - 数据模型（TimelineEntry, TimelineSource, TimelineMetadata）
  - `lib/services/` - 业务服务（数据加载、搜索管理、前缀树）
  - `lib/timeline/` - 时间线核心逻辑（渲染、布局、视口）
  - `lib/views/` - 视图模式（合并视图、对比视图）
  - `lib/filter/` - 筛选系统
  - `lib/search/` - 搜索系统
  - `lib/article/` - 简述气泡和详情页
  - `lib/l10n/` - 国际化文件
  - `lib/utils/` - 工具类（颜色、时间处理）
- `assets/` - 静态资源
- `data/` - JSON 数据文件（数据源目录）
- `test/` - 测试文件

## JSON Data Format

```json
{
  "metadata": {
    "name": "数据源名称",
    "version": "1.0",
    "description": "数据源描述",
    "colorScheme": {
      "primary": "#FF5722",
      "secondary": "#FFC107"
    }
  },
  "events": [
    {
      "date": -13800000000,
      "label": "事件标题",
      "summary": "Markdown格式简述",
      "description": "description_file.html",
      "type": "incident",
      "background": [0, 38, 75],
      "accent": [246, 76, 130, 255]
    }
  ]
}
```

## Development Commands

### Setup

```bash
flutter pub get
flutter gen-l10n
```

### Testing

```bash
flutter test
flutter test --coverage
flutter test test/unit/
```

### Building

```bash
flutter build apk --release        # Android
flutter build ios --release        # iOS (macOS only)
flutter build web --release        # Web
flutter build windows --release    # Windows
```

### Analysis

```bash
flutter analyze
dart format lib/
```

## Important Notes

- 默认语言为中文，支持英文
- 渲染目标 30fps
- 无收藏功能，无多媒体/动画资源
- 筛选系统控制数据源显示/隐藏，状态持久化
- 简述气泡：点击标签弹出，Markdown 渲染，底部图标按钮跳转详情页
- 气泡使用 Stack + Positioned 渲染在所有时间轴之上
- 气泡跟随时间轴滚动和缩放，自动计算位置
- 气泡超出窗口右侧时自动翻转到标签左侧，圆角方向同步调整
- 详情页：HTML 格式内容展示
- 对比视图切换时自动加载当前筛选可见的所有数据源
- 多时间轴支持共享视口（sharedViewport）实现同步滚动/缩放

## Environment Configuration

- **Flutter SDK**: latest stable (3.x)
- **Dart SDK**: 3.x (null safety)
- **Android**: minSdk 21, targetSdk 35
- **iOS**: Deployment target 12.0

## Recommended Workflow

1. 使用 Riverpod 进行所有状态管理
2. 优先编写单元测试
3. 保持自定义 RenderBox 优化以确保时间线性能
4. 中文为默认语言，同时支持英文
5. 遵循 Flutter 样式指南和最佳实践

---

*Last Updated: July 2026*
