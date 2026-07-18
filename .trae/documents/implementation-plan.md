# Timelines 项目实施计划

## 项目概述

基于 Flutter 构建通用历史时间线框架，支持多 JSON 数据源、合并/对比视图、搜索、筛选和文章系统。

## 技术栈

- **框架**: Flutter (latest stable 3.x)
- **状态管理**: Riverpod
- **数据格式**: JSON
- **内容格式**: Markdown (简述) + HTML (详情)
- **国际化**: flutter_localizations + intl

---

## 阶段一：项目初始化与基础架构 ✅

### 1.1 项目创建
- [x] 使用 `flutter create` 创建新项目
- [x] 配置 pubspec.yaml 依赖
- [x] 设置基础目录结构

### 1.2 基础架构搭建
- [x] 配置 Riverpod ProviderScope
- [x] 实现应用初始化流程
- [x] 设置国际化（中文默认，英文支持）
- [x] 配置主题和颜色系统

### 1.3 数据模型定义
- [x] TimelineEntry 数据模型
- [x] TimelineSource 数据源模型
- [x] TimelineMetadata 元数据模型
- [x] 模型序列化/反序列化

---

## 阶段二：数据层实现 ✅

### 2.1 JSON 数据加载
- [x] JSON 解析器实现
- [x] 数据源自动发现服务（扫描固定文件夹）
- [x] 配置文件支持（指定数据源列表）
- [x] 异步加载机制

### 2.2 数据源管理
- [x] DataSourceProvider 实现
- [x] 数据源注册/注销机制
- [x] 数据源配置持久化
- [x] 错误处理与重试机制

### 2.3 数据验证
- [x] JSON 格式验证
- [x] 数据完整性检查
- [x] 格式错误处理

---

## 阶段三：时间线核心渲染 ✅

### 3.1 自定义渲染系统
- [x] TimelineRenderBox 实现
- [x] 视口裁剪逻辑
- [x] 可见项目计算
- [ ] 30fps 帧调度（待优化）

### 3.2 时间线布局
- [x] 垂直时间轴布局算法
- [x] 事件位置计算（基于时间）
- [x] 缩放级别管理
- [x] 平移/滚动处理

### 3.3 视觉元素渲染
- [x] 时间轴线渲染
- [x] 事件节点渲染
- [x] 标签文本渲染
- [x] 颜色编码（区分数据源）
- [x] 时代/事件视觉区分

### 3.4 交互处理
- [x] 手势识别（滚动、捏合缩放）
- [x] 点击事件处理
- [ ] 平滑动画（待优化）
- [ ] 滚动物理效果（待优化）

---

## 阶段四：视图模式 ✅

### 4.1 合并视图
- [x] 多数据源事件合并
- [x] 时间排序算法
- [x] 颜色编码显示
- [x] 数据源标签显示

### 4.2 对比视图
- [x] 多列布局实现
- [x] 同步滚动机制
- [ ] 时间对齐参考线（待实现）
- [x] 缩放级别同步

### 4.3 视图切换
- [x] ViewModeProvider 实现
- [ ] 视图切换动画（待优化）
- [x] 状态保持

---

## 阶段五：筛选系统 ✅

### 5.1 筛选 UI
- [x] 数据源列表界面
- [x] 勾选框组件
- [x] 全选/全不选按钮
- [x] 事件数量显示
- [x] 颜色标识显示

### 5.2 筛选逻辑
- [x] FilterProvider 实现
- [x] 筛选状态管理
- [x] 实时更新机制
- [x] 状态持久化存储

---

## 阶段六：搜索系统 ✅

### 6.1 搜索索引
- [x] 前缀树数据结构实现
- [x] 分词算法（空格、驼峰识别）
- [x] 索引构建（异步）
- [ ] 索引更新机制（待优化）

### 6.2 搜索功能
- [x] SearchManager 实现
- [x] 实时搜索（350ms 防抖）
- [x] 前缀匹配
- [x] 多词 AND 查询
- [x] 大小写无关匹配

### 6.3 搜索 UI
- [x] 搜索输入框
- [x] 自动补全建议
- [x] 搜索结果列表
- [x] 数据源标识显示

---

## 阶段七：简述气泡与详情页 ✅

### 7.1 简述气泡
- [x] 气泡 UI 组件
- [x] Markdown 渲染（flutter_markdown）
- [x] 点击标签弹出逻辑
- [ ] 气泡位置计算（待优化）
- [x] "详情"按钮

### 7.2 详情页
- [x] 详情页路由
- [x] HTML 内容渲染（flutter_widget_from_html）
- [x] 返回导航
- [ ] 数据源信息显示（待优化）

---

## 阶段八：性能优化 🔄

### 8.1 渲染优化
- [ ] PictureLayer 缓存
- [ ] RepaintBoundary 隔离
- [x] 屏幕外项目剔除
- [ ] 稳态检测与渲染频率降低

### 8.2 内存优化
- [ ] 资源缓存管理
- [ ] 未使用资源清理
- [ ] 内存使用监控

### 8.3 加载优化
- [x] 异步数据加载
- [x] 进度指示器
- [ ] 懒加载支持

---

## 阶段九：测试 🔄

### 9.1 单元测试
- [x] 数据模型测试（46个测试全部通过）
- [x] 搜索算法测试（前缀树和搜索管理器测试通过）
- [ ] 筛选逻辑测试
- [ ] Provider 测试

### 9.2 Widget 测试
- [ ] 时间线组件测试
- [ ] 搜索界面测试
- [ ] 筛选界面测试
- [ ] 详情页测试

### 9.3 集成测试
- [ ] 完整用户流程测试
- [ ] 多数据源场景测试
- [ ] 性能测试

---

## 阶段十：发布准备 ⏳

### 10.1 代码质量
- [x] flutter analyze 通过（仅剩 deprecated API 警告）
- [ ] dart format 格式化
- [ ] 代码审查
- [x] 文档完善

### 10.2 构建配置
- [x] Android 构建配置
- [x] iOS 构建配置
- [x] Web 构建配置
- [x] Windows 构建配置

### 10.3 发布
- [ ] 版本号设置
- [ ] 构建发布包
- [ ] 测试发布包

---

## 目录结构

```
lib/
├── main.dart                    # 应用入口
├── app.dart                     # 应用配置
├── providers/                   # Riverpod Providers
│   ├── app_providers.dart
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
│   ├── timeline_viewport.dart
│   └── timeline_constants.dart
├── views/                       # 视图模式
│   ├── merged_view.dart
│   └── compare_view.dart
├── filter/                      # 筛选系统
│   ├── filter_widget.dart
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

## 依赖清单

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  intl: ^0.20.2
  shared_preferences: ^2.5.5
  flutter_markdown: ^0.7.0
  flutter_widget_from_html: ^0.15.0
  path_provider: ^2.1.0
  path: ^1.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

---

## 里程碑

| 阶段 | 里程碑 | 关键交付物 | 状态 |
|------|--------|-----------|------|
| 1 | 项目初始化 | 可运行的空应用 | ✅ 完成 |
| 2 | 数据层 | JSON 加载功能 | ✅ 完成 |
| 3 | 时间线渲染 | 基础时间线显示 | ✅ 完成 |
| 4 | 视图模式 | 合并/对比视图 | ✅ 完成 |
| 5 | 筛选系统 | 数据源筛选 | ✅ 完成 |
| 6 | 搜索系统 | 全文搜索 | ✅ 完成 |
| 7 | 内容展示 | 简述气泡+详情页 | ✅ 完成 |
| 8 | 性能优化 | 30fps 稳定运行 | 🔄 进行中 |
| 9 | 测试 | 85%+ 覆盖率 | 🔄 进行中（46个单元测试通过） |
| 10 | 发布 | 各平台发布包 | ⏳ 待开始 |

---

*计划版本：1.1*  
*创建日期：2026年7月*  
*最后更新：2026年7月18日*
