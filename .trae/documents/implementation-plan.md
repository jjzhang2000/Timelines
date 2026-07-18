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

## 阶段一：项目初始化与基础架构

### 1.1 项目创建
- [ ] 使用 `flutter create` 创建新项目
- [ ] 配置 pubspec.yaml 依赖
- [ ] 设置基础目录结构

### 1.2 基础架构搭建
- [ ] 配置 Riverpod ProviderScope
- [ ] 实现应用初始化流程
- [ ] 设置国际化（中文默认，英文支持）
- [ ] 配置主题和颜色系统

### 1.3 数据模型定义
- [ ] TimelineEntry 数据模型
- [ ] TimelineSource 数据源模型
- [ ] TimelineMetadata 元数据模型
- [ ] 模型序列化/反序列化

---

## 阶段二：数据层实现

### 2.1 JSON 数据加载
- [ ] JSON 解析器实现
- [ ] 数据源自动发现服务（扫描固定文件夹）
- [ ] 配置文件支持（指定数据源列表）
- [ ] 异步加载机制

### 2.2 数据源管理
- [ ] DataSourceProvider 实现
- [ ] 数据源注册/注销机制
- [ ] 数据源配置持久化
- [ ] 错误处理与重试机制

### 2.3 数据验证
- [ ] JSON 格式验证
- [ ] 数据完整性检查
- [ ] 格式错误处理

---

## 阶段三：时间线核心渲染

### 3.1 自定义渲染系统
- [ ] TimelineRenderBox 实现
- [ ] 视口裁剪逻辑
- [ ] 可见项目计算
- [ ] 30fps 帧调度

### 3.2 时间线布局
- [ ] 垂直时间轴布局算法
- [ ] 事件位置计算（基于时间）
- [ ] 缩放级别管理
- [ ] 平移/滚动处理

### 3.3 视觉元素渲染
- [ ] 时间轴线渲染
- [ ] 事件节点渲染
- [ ] 标签文本渲染
- [ ] 颜色编码（区分数据源）
- [ ] 时代/事件视觉区分

### 3.4 交互处理
- [ ] 手势识别（滚动、捏合缩放）
- [ ] 点击事件处理
- [ ] 平滑动画
- [ ] 滚动物理效果

---

## 阶段四：视图模式

### 4.1 合并视图
- [ ] 多数据源事件合并
- [ ] 时间排序算法
- [ ] 颜色编码显示
- [ ] 数据源标签显示

### 4.2 对比视图
- [ ] 多列布局实现
- [ ] 同步滚动机制
- [ ] 时间对齐参考线
- [ ] 缩放级别同步

### 4.3 视图切换
- [ ] ViewModeProvider 实现
- [ ] 视图切换动画
- [ ] 状态保持

---

## 阶段五：筛选系统

### 5.1 筛选 UI
- [ ] 数据源列表界面
- [ ] 勾选框组件
- [ ] 全选/全不选按钮
- [ ] 事件数量显示
- [ ] 颜色标识显示

### 5.2 筛选逻辑
- [ ] FilterProvider 实现
- [ ] 筛选状态管理
- [ ] 实时更新机制
- [ ] 状态持久化存储

---

## 阶段六：搜索系统

### 6.1 搜索索引
- [ ] 前缀树数据结构实现
- [ ] 分词算法（空格、驼峰识别）
- [ ] 索引构建（异步）
- [ ] 索引更新机制

### 6.2 搜索功能
- [ ] SearchManager 实现
- [ ] 实时搜索（350ms 防抖）
- [ ] 前缀匹配
- [ ] 多词 AND 查询
- [ ] 大小写无关匹配

### 6.3 搜索 UI
- [ ] 搜索输入框
- [ ] 自动补全建议
- [ ] 搜索结果列表
- [ ] 数据源标识显示

---

## 阶段七：简述气泡与详情页

### 7.1 简述气泡
- [ ] 气泡 UI 组件
- [ ] Markdown 渲染（flutter_markdown）
- [ ] 点击标签弹出逻辑
- [ ] 气泡位置计算
- [ ] "详情"按钮

### 7.2 详情页
- [ ] 详情页路由
- [ ] HTML 内容渲染（flutter_widget_from_html）
- [ ] 返回导航
- [ ] 数据源信息显示

---

## 阶段八：性能优化

### 8.1 渲染优化
- [ ] PictureLayer 缓存
- [ ] RepaintBoundary 隔离
- [ ] 屏幕外项目剔除
- [ ] 稳态检测与渲染频率降低

### 8.2 内存优化
- [ ] 资源缓存管理
- [ ] 未使用资源清理
- [ ] 内存使用监控

### 8.3 加载优化
- [ ] 异步数据加载
- [ ] 进度指示器
- [ ] 懒加载支持

---

## 阶段九：测试

### 9.1 单元测试
- [ ] 数据模型测试
- [ ] 搜索算法测试
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

## 阶段十：发布准备

### 10.1 代码质量
- [ ] flutter analyze 通过
- [ ] dart format 格式化
- [ ] 代码审查
- [ ] 文档完善

### 10.2 构建配置
- [ ] Android 构建配置
- [ ] iOS 构建配置
- [ ] Web 构建配置
- [ ] Windows 构建配置

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

| 阶段 | 里程碑 | 关键交付物 |
|------|--------|-----------|
| 1 | 项目初始化 | 可运行的空应用 |
| 2 | 数据层 | JSON 加载功能 |
| 3 | 时间线渲染 | 基础时间线显示 |
| 4 | 视图模式 | 合并/对比视图 |
| 5 | 筛选系统 | 数据源筛选 |
| 6 | 搜索系统 | 全文搜索 |
| 7 | 内容展示 | 简述气泡+详情页 |
| 8 | 性能优化 | 30fps 稳定运行 |
| 9 | 测试 | 85%+ 覆盖率 |
| 10 | 发布 | 各平台发布包 |

---

*计划版本：1.0*  
*创建日期：2026年7月*
