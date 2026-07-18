# Timelines - 通用历史时间线框架

一个基于 Flutter 构建的通用历史时间线应用，通过加载 JSON 数据文件展示任意主题的历史时间线。

## ✨ 功能特性

### 核心功能
- 📅 **时间线渲染** - 高性能自定义渲染引擎，支持视口裁剪和 30fps 流畅显示
- 🔍 **全文搜索** - 基于前缀树的快速搜索，支持自动补全和多词查询
- 🎯 **多视图模式** - 合并视图和对比视图，支持同步滚动
- 🎨 **数据源筛选** - 灵活的数据源可见性控制，状态自动持久化
- 📖 **内容展示** - Markdown 简述气泡 + HTML 详情页
- 🌍 **国际化支持** - 中文（默认）和英文

### 技术特点
- 自定义 RenderBox 实现高性能渲染
- 视口裁剪，仅渲染可见项目
- 前缀树（Trie）数据结构实现快速搜索
- Riverpod 状态管理
- 异步数据加载和索引构建

## 🛠️ 技术栈

- **框架**: Flutter 3.41.8 (Dart 3.11.5)
- **状态管理**: Riverpod 2.6.1
- **数据格式**: JSON
- **内容格式**: Markdown (简述) + HTML (详情)
- **国际化**: flutter_localizations + intl
- **存储**: SharedPreferences (状态持久化)

## 📦 安装与运行

### 环境要求
- Flutter SDK (latest stable)
- Dart SDK 3.x

### 安装依赖

```bash
flutter pub get
```

### 生成国际化文件

```bash
flutter gen-l10n
```

### 运行应用

```bash
# 运行在默认设备
flutter run

# 运行在 Chrome
flutter run -d chrome

# 运行在 Windows
flutter run -d windows

# 运行在 Android 设备
flutter run -d android
```

## 📊 数据源格式

时间线数据使用 JSON 文件，放置在 `data/` 目录下。应用会自动扫描该目录下的所有 `.json` 文件。

### JSON 数据结构

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
      "summary": "Markdown 格式简述",
      "description": "description_file.html",
      "type": "incident",
      "background": [0, 38, 75],
      "accent": [246, 76, 130, 255]
    }
  ]
}
```

### 字段说明

#### metadata
- `name`: 数据源名称（显示在界面中）
- `version`: 版本号
- `description`: 数据源描述
- `colorScheme`: 颜色方案
  - `primary`: 主色调（十六进制颜色值）
  - `secondary`: 辅助色

#### events
- `date`: 时间戳（整数，支持负数表示公元前）
- `label`: 事件标题（必填）
- `summary`: Markdown 格式简述（可选，点击标签时显示）
- `description`: HTML 文件名（可选，详情页内容）
- `type`: 事件类型
  - `incident`: 事件（普通节点）
  - `era`: 时代（粗体显示）
- `background`: 背景色 [R, G, B] 或 [R, G, B, A]（可选）
- `accent`: 强调色 [R, G, B] 或 [R, G, B, A]（可选）

### 示例数据

项目包含两个示例数据文件：
- `data/sample_universe.json` - 宇宙历史
- `data/sample_earth.json` - 地球历史

## 🏗️ 项目结构

```
lib/
├── main.dart                    # 应用入口
├── app.dart                     # 应用配置
├── providers/                   # Riverpod 状态管理
│   ├── data_source_provider.dart  # 数据源管理
│   ├── timeline_provider.dart     # 时间线状态
│   ├── search_provider.dart       # 搜索状态
│   ├── filter_provider.dart       # 筛选状态
│   └── view_mode_provider.dart    # 视图模式
├── models/                      # 数据模型
│   ├── timeline_entry.dart        # 时间线条目
│   ├── timeline_source.dart       # 数据源
│   └── timeline_metadata.dart     # 元数据
├── services/                    # 业务服务
│   ├── data_loader.dart           # 数据加载
│   ├── search_manager.dart        # 搜索管理
│   └── prefix_tree.dart           # 前缀树
├── timeline/                    # 时间线核心
│   ├── timeline_widget.dart       # 时间线组件
│   └── timeline_viewport.dart     # 视口管理
├── views/                       # 视图模式
│   ├── home_view.dart             # 主视图
│   ├── merged_view.dart           # 合并视图
│   └── compare_view.dart          # 对比视图
├── filter/                      # 筛选系统
│   └── filter_panel.dart          # 筛选面板
├── search/                      # 搜索系统
│   └── search_widget.dart         # 搜索组件
├── article/                     # 内容展示
│   ├── summary_bubble.dart        # 简述气泡
│   └── detail_page.dart           # 详情页
├── l10n/                        # 国际化
│   ├── app_zh.arb                 # 中文
│   ├── app_en.arb                 # 英文
│   └── l10n.dart                  # 本地化配置
└── utils/                       # 工具类
    ├── color_utils.dart           # 颜色工具
    └── time_utils.dart            # 时间工具
```

## 🧪 测试

### 运行所有测试

```bash
flutter test
```

### 运行单元测试

```bash
flutter test test/unit/
```

### 生成测试覆盖率报告

```bash
flutter test --coverage
```

当前测试状态：**46 个单元测试全部通过** ✅

## 📱 构建发布包

### Android

```bash
flutter build apk --release
```

### iOS (仅 macOS)

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

### Windows

```bash
flutter build windows --release
```

## 🔍 代码质量

### 静态分析

```bash
flutter analyze
```

### 代码格式化

```bash
dart format lib/ test/
```

## 📋 开发进度

- ✅ 阶段 1-7：核心功能已完成
  - 项目初始化与基础架构
  - 数据层实现
  - 时间线核心渲染
  - 视图模式（合并/对比）
  - 筛选系统
  - 搜索系统
  - 简述气泡与详情页
- 🔄 阶段 8-10：待实现
  - 性能优化
  - 测试完善
  - 发布准备

## 🤝 贡献

欢迎贡献代码！请遵循以下步骤：

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 📄 许可证

本项目仅供学习和研究使用。

## 📞 联系方式

如有问题或建议，请通过 GitHub Issues 反馈。

---

**最后更新**: 2026年7月18日
