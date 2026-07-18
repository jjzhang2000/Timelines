# Timelines 测试计划文档

---

## 1. 测试策略概述

### 1.1 测试目标

- **功能正确性**: 确保所有功能按需求规格正常工作
- **性能指标**: 维持 30fps 渲染性能，内存使用低于 200MB
- **代码覆盖率**: 单元测试覆盖率达到 85% 以上
- **用户体验**: 验证 UI 交互和响应性

### 1.2 测试层次

```
┌─────────────────────────────────────┐
│         集成测试 (Integration)       │  ← 完整用户流程
├─────────────────────────────────────┤
│         Widget 测试 (Widget)         │  ← UI 组件功能
├─────────────────────────────────────┤
│         单元测试 (Unit)              │  ← 业务逻辑
└─────────────────────────────────────┘
```

### 1.3 测试工具

- **flutter_test**: 单元测试和 Widget 测试
- **integration_test**: 集成测试
- **flutter_driver**: 性能测试
- **mockito**: Mock 对象
- **riverpod_test**: Provider 测试辅助

---

## 2. 单元测试计划

### 2.1 数据模型测试

**测试文件**: `test/unit/models/timeline_entry_test.dart`

#### 2.1.1 TimelineEntry 测试

| 测试用例 | 测试内容 | 预期结果 | 优先级 |
|---------|---------|---------|--------|
| TC-ENTRY-001 | 从 JSON 创建 TimelineEntry（完整数据） | 正确解析所有字段 | P0 |
| TC-ENTRY-002 | 从 JSON 创建 TimelineEntry（可选字段缺失） | summary 和 description 为 null | P0 |
| TC-ENTRY-003 | 颜色解析：RGB 格式（3 元素） | 正确转换为 Color 对象 | P0 |
| TC-ENTRY-004 | 颜色解析：RGBA 格式（4 元素） | 正确解析透明度 | P0 |
| TC-ENTRY-005 | 颜色解析：无效长度 | 抛出 ArgumentError | P1 |
| TC-ENTRY-006 | 类型解析：era | EntryType.era | P0 |
| TC-ENTRY-007 | 类型解析：incident | EntryType.incident | P0 |
| TC-ENTRY-008 | 类型解析：未知类型 | 默认为 EntryType.incident | P1 |
| TC-ENTRY-009 | toJson 序列化 | 正确转换为 JSON 格式 | P0 |
| TC-ENTRY-010 | copyWith 方法 | 正确复制并修改指定字段 | P1 |
| TC-ENTRY-011 | 负数时间戳（公元前） | 正确处理负数日期 | P0 |

#### 2.1.2 TimelineSource 测试

**测试文件**: `test/unit/models/timeline_source_test.dart`

| 测试用例 | 测试内容 | 预期结果 | 优先级 |
|---------|---------|---------|--------|
| TC-SRC-001 | 从 JSON 创建 TimelineSource | 正确解析 metadata 和 events | P0 |
| TC-SRC-002 | 事件关联 sourceId | 所有事件的 sourceId 正确设置 | P0 |
| TC-SRC-003 | 空事件列表 | 正常处理，events 为空列表 | P1 |
| TC-SRC-004 | toJson 序列化 | 正确转换为 JSON 格式 | P1 |

#### 2.1.3 TimelineMetadata 测试

**测试文件**: `test/unit/models/timeline_metadata_test.dart`

| 测试用例 | 测试内容 | 预期结果 | 优先级 |
|---------|---------|---------|--------|
| TC-META-001 | 从 JSON 创建 TimelineMetadata | 正确解析所有字段 | P0 |
| TC-META-002 | 颜色方案解析：6 位十六进制 | 正确转换为 Color | P0 |
| TC-META-003 | 颜色方案解析：8 位十六进制（带透明度） | 正确解析透明度 | P0 |
| TC-META-004 | 颜色方案解析：无效格式 | 抛出异常 | P1 |

---

### 2.2 数据加载服务测试

**测试文件**: `test/unit/services/data_loader_test.dart`

#### 2.2.1 DataLoaderService 测试

| 测试用例 | 测试内容 | 预期结果 | 优先级 |
|---------|---------|---------|--------|
| TC-LOAD-001 | 扫描目录获取 JSON 文件 | 返回所有 .json 文件 | P0 |
| TC-LOAD-002 | 目录不存在 | 抛出 DirectoryNotFoundException | P0 |
| TC-LOAD-003 | 目录为空 | 返回空列表 | P1 |
| TC-LOAD-004 | 解析有效 JSON 文件 | 正确创建 TimelineSource | P0 |
| TC-LOAD-005 | 解析无效 JSON 文件 | 抛出 JsonParseException | P0 |
| TC-LOAD-006 | 解析格式错误的 JSON | 抛出 JsonParseException，包含错误信息 | P1 |
| TC-LOAD-007 | 从配置文件加载数据源列表 | 按配置加载指定文件 | P1 |
| TC-LOAD-008 | 配置文件不存在 | 回退到目录扫描 | P1 |
| TC-LOAD-009 | 并行解析多个文件 | 所有文件正确加载 | P0 |
| TC-LOAD-010 | 单个文件解析失败不影响其他 | 其他文件正常加载，记录失败文件 | P0 |

#### 2.2.2 Mock 策略

```dart
// 使用 mockito 模拟文件系统操作
class MockFileSystem extends Mock implements FileSystem {}

// 测试示例
test('TC-LOAD-001: 扫描目录获取 JSON 文件', () async {
  final mockDir = MockDirectory();
  when(mockDir.exists()).thenAnswer((_) async => true);
  when(mockDir.list(recursive: false)).thenAnswer((_) async* {
    yield MockFile('data1.json');
    yield MockFile('data2.json');
  });
  
  final service = DataLoaderService(dataDirectory: 'data');
  final sources = await service.discoverSources();
  
  expect(sources.length, 2);
});
```

---

### 2.3 搜索系统测试

**测试文件**: `test/unit/services/prefix_tree_test.dart`

#### 2.3.1 PrefixTree 测试

| 测试用例 | 测试内容 | 预期结果 | 优先级 |
|---------|---------|---------|--------|
| TC-TRIE-001 | 插入单词并搜索 | 返回关联的 TimelineEntry | P0 |
| TC-TRIE-002 | 前缀搜索 | 返回所有匹配前缀的条目 | P0 |
| TC-TRIE-003 | 大小写无关搜索 | "Hello" 和 "hello" 返回相同结果 | P0 |
| TC-TRIE-004 | 搜索不存在的前缀 | 返回空集合 | P1 |
| TC-TRIE-005 | 获取自动补全建议 | 返回最多 5 个建议 | P1 |
| TC-TRIE-006 | 重复插入相同单词 | 使用 Set 去重 | P1 |
| TC-TRIE-007 | 清空索引 | 搜索返回空结果 | P1 |

**测试文件**: `test/unit/services/search_manager_test.dart`

#### 2.3.2 SearchManager 测试

| 测试用例 | 测试内容 | 预期结果 | 优先级 |
|---------|---------|---------|--------|
| TC-SEARCH-001 | 构建索引 | 索引正确构建 | P0 |
| TC-SEARCH-002 | 分词：空格分割 | "hello world" → ["hello", "world"] | P0 |
| TC-SEARCH-003 | 分词：驼峰识别 | "camelCase" → ["camel", "Case"] | P0 |
| TC-SEARCH-004 | 分词：连字符分割 | "hello-world" → ["hello", "world"] | P1 |
| TC-SEARCH-005 | 分词：下划线分割 | "hello_world" → ["hello", "world"] | P1 |
| TC-SEARCH-006 | 多词 AND 查询 | "hello world" 返回同时包含两个词的结果 | P0 |
| TC-SEARCH-007 | 搜索结果按时间排序 | 结果按 date 字段升序排列 | P0 |
| TC-SEARCH-008 | 索引未构建时搜索 | 抛出 StateError | P1 |
| TC-SEARCH-009 | 空查询 | 返回空列表 | P1 |

---

### 2.4 Provider 测试

**测试文件**: `test/unit/providers/data_source_provider_test.dart`

#### 2.4.1 DataSourceProvider 测试

| 测试用例 | 测试内容 | 预期结果 | 优先级 |
|---------|---------|---------|--------|
| TC-DS-001 | 初始状态 | status 为 initial，sources 为空 | P0 |
| TC-DS-002 | 加载数据源成功 | status 为 success，sources 包含数据 | P0 |
| TC-DS-003 | 加载数据源失败 | status 为 error，errorMessage 不为空 | P0 |
| TC-DS-004 | 添加数据源 | sources 列表增加 | P1 |
| TC-DS-005 | 移除数据源 | sources 列表减少 | P1 |
| TC-DS-006 | 加载状态转换 | initial → loading → success/error | P0 |

**测试文件**: `test/unit/providers/filter_provider_test.dart`

#### 2.4.2 FilterProvider 测试

| 测试用例 | 测试内容 | 预期结果 | 优先级 |
|---------|---------|---------|--------|
| TC-FILTER-001 | 初始状态 | sourceVisibility 为空 | P0 |
| TC-FILTER-002 | 切换数据源可见性 | isVisible 状态翻转 | P0 |
| TC-FILTER-003 | 全选 | 所有数据源可见 | P0 |
| TC-FILTER-004 | 全不选 | 所有数据源不可见 | P0 |
| TC-FILTER-005 | 初始化数据源 | 新数据源默认显示 | P1 |
| TC-FILTER-006 | 状态持久化 | 保存到 SharedPreferences | P0 |
| TC-FILTER-007 | 加载持久化状态 | 从 SharedPreferences 恢复 | P0 |

**测试文件**: `test/unit/providers/timeline_provider_test.dart`

#### 2.4.3 TimelineProvider 测试

| 测试用例 | 测试内容 | 预期结果 | 优先级 |
|---------|---------|---------|--------|
| TC-TL-001 | 数据源未加载 | entries 为空 | P0 |
| TC-TL-002 | 合并多个数据源事件 | 所有启用的事件合并 | P0 |
| TC-TL-003 | 按时间排序 | entries 按 date 升序排列 | P0 |
| TC-TL-004 | 过滤隐藏的数据源 | 仅包含可见数据源的事件 | P0 |
| TC-TL-005 | 选中事件 | selectedEntryIndex 正确设置 | P1 |
| TC-TL-006 | 清除选择 | selectedEntryIndex 为 null | P1 |
| TC-TL-007 | 响应数据源变化 | 自动重新计算 entries | P0 |
| TC-TL-008 | 响应筛选变化 | 自动重新计算 entries | P0 |

**测试文件**: `test/unit/providers/search_provider_test.dart`

#### 2.4.4 SearchProvider 测试

| 测试用例 | 测试内容 | 预期结果 | 优先级 |
|---------|---------|---------|--------|
| TC-SP-001 | 初始状态 | query 为空，results 为空 | P0 |
| TC-SP-002 | 更新查询（防抖） | 350ms 后执行搜索 | P0 |
| TC-SP-003 | 快速连续输入 | 仅最后一次触发搜索 | P0 |
| TC-SP-004 | 空查询 | 清空结果 | P1 |
| TC-SP-005 | 清除搜索 | 状态重置 | P1 |
| TC-SP-006 | 搜索中状态 | isSearching 为 true | P1 |
| TC-SP-007 | 搜索完成 | isSearching 为 false，results 更新 | P0 |

**测试文件**: `test/unit/providers/view_mode_provider_test.dart`

#### 2.4.5 ViewModeProvider 测试

| 测试用例 | 测试内容 | 预期结果 | 优先级 |
|---------|---------|---------|--------|
| TC-VM-001 | 初始状态 | mode 为 merged | P0 |
| TC-VM-002 | 切换到对比视图 | mode 为 compare | P0 |
| TC-VM-003 | 设置对比数据源 | compareSourceIds 更新 | P0 |
| TC-VM-004 | 状态持久化 | 保存到 SharedPreferences | P1 |
| TC-VM-005 | 加载持久化状态 | 从 SharedPreferences 恢复 | P1 |

---

### 2.5 工具类测试

**测试文件**: `test/unit/utils/color_utils_test.dart`

#### 2.5.1 ColorUtils 测试

| 测试用例 | 测试内容 | 预期结果 | 优先级 |
|---------|---------|---------|--------|
| TC-COLOR-001 | hexToColor：6 位十六进制 | 正确转换为 Color | P0 |
| TC-COLOR-002 | hexToColor：8 位十六进制 | 正确解析透明度 | P0 |
| TC-COLOR-003 | hexToColor：带 # 前缀 | 正确解析 | P0 |
| TC-COLOR-004 | colorToHex | 正确转换为十六进制字符串 | P1 |
| TC-COLOR-005 | interpolateColor：t=0 | 返回起始颜色 | P1 |
| TC-COLOR-006 | interpolateColor：t=1 | 返回结束颜色 | P1 |
| TC-COLOR-007 | interpolateColor：t=0.5 | 返回中间颜色 | P1 |

**测试文件**: `test/unit/utils/time_utils_test.dart`

#### 2.5.2 TimeUtils 测试

| 测试用例 | 测试内容 | 预期结果 | 优先级 |
|---------|---------|---------|--------|
| TC-TIME-001 | formatDate：正数年份 | 返回 "YYYY 年" | P0 |
| TC-TIME-002 | formatDate：负数年份 | 返回 "公元前 YYYY 年" | P0 |
| TC-TIME-003 | formatDuration：小于 100 年 | 返回 "N 年" | P1 |
| TC-TIME-004 | formatDuration：100-1000 年 | 返回 "N 世纪" | P1 |
| TC-TIME-005 | formatDuration：大于 1000 年 | 返回 "N 千年" | P1 |

---

## 3. Widget 测试计划

### 3.1 筛选面板测试

**测试文件**: `test/widget/filter_panel_test.dart`

| 测试用例 | 测试内容 | 预期结果 | 优先级 |
|---------|---------|---------|--------|
| TC-W-FILTER-001 | 显示数据源列表 | 所有数据源显示 | P0 |
| TC-W-FILTER-002 | 勾选框状态 | 正确反映可见性状态 | P0 |
| TC-W-FILTER-003 | 点击勾选框 | 切换可见性状态 | P0 |
| TC-W-FILTER-004 | 全选按钮 | 所有勾选框选中 | P0 |
| TC-W-FILTER-005 | 全不选按钮 | 所有勾选框取消选中 | P0 |
| TC-W-FILTER-006 | 显示事件数量 | 每个数据源显示正确的事件数 | P1 |
| TC-W-FILTER-007 | 显示颜色标识 | 圆形颜色标记正确显示 | P1 |

### 3.2 搜索界面测试

**测试文件**: `test/widget/search_widget_test.dart`

| 测试用例 | 测试内容 | 预期结果 | 优先级 |
|---------|---------|---------|--------|
| TC-W-SEARCH-001 | 搜索输入框 | 正确显示和接收输入 | P0 |
| TC-W-SEARCH-002 | 输入触发搜索 | 350ms 后显示结果 | P0 |
| TC-W-SEARCH-003 | 显示搜索结果 | 结果列表正确渲染 | P0 |
| TC-W-SEARCH-004 | 显示自动补全建议 | 建议列表正确显示 | P1 |
| TC-W-SEARCH-005 | 点击搜索结果 | 导航到对应事件 | P1 |
| TC-W-SEARCH-006 | 清除搜索 | 输入框清空，结果消失 | P1 |
| TC-W-SEARCH-007 | 显示数据源标识 | 结果项显示来源数据源 | P1 |

### 3.3 简述气泡测试

**测试文件**: `test/widget/summary_bubble_test.dart`

| 测试用例 | 测试内容 | 预期结果 | 优先级 |
|---------|---------|---------|--------|
| TC-W-BUBBLE-001 | 显示 Markdown 简述 | 正确渲染 Markdown 内容 | P0 |
| TC-W-BUBBLE-002 | 无简述内容 | 不显示 Markdown 区域 | P1 |
| TC-W-BUBBLE-003 | 详情按钮 | 按钮可点击 | P0 |
| TC-W-BUBBLE-004 | 点击详情按钮 | 触发 onDetailTap 回调 | P0 |
| TC-W-BUBBLE-005 | 气泡样式 | 白色背景、圆角、阴影 | P1 |

### 3.4 详情页测试

**测试文件**: `test/widget/detail_page_test.dart`

| 测试用例 | 测试内容 | 预期结果 | 优先级 |
|---------|---------|---------|--------|
| TC-W-DETAIL-001 | 显示标题 | AppBar 显示事件标签 | P0 |
| TC-W-DETAIL-002 | 加载 HTML 内容 | 正确渲染 HTML | P0 |
| TC-W-DETAIL-003 | 加载中状态 | 显示 CircularProgressIndicator | P1 |
| TC-W-DETAIL-004 | 加载失败 | 显示错误信息 | P0 |
| TC-W-DETAIL-005 | HTML 文件不存在 | 显示错误信息 | P0 |
| TC-W-DETAIL-006 | 返回导航 | 返回时间轴 | P0 |

### 3.5 合并视图测试

**测试文件**: `test/widget/merged_view_test.dart`

| 测试用例 | 测试内容 | 预期结果 | 优先级 |
|---------|---------|---------|--------|
| TC-W-MERGED-001 | 显示时间轴 | TimelineWidget 正确渲染 | P0 |
| TC-W-MERGED-002 | 显示所有启用事件 | 事件数量正确 | P0 |
| TC-W-MERGED-003 | 点击事件 | 触发选中逻辑 | P1 |
| TC-W-MERGED-004 | 颜色编码 | 不同数据源事件颜色不同 | P1 |

### 3.6 对比视图测试

**测试文件**: `test/widget/compare_view_test.dart`

| 测试用例 | 测试内容 | 预期结果 | 优先级 |
|---------|---------|---------|--------|
| TC-W-COMPARE-001 | 显示多个时间轴 | 2-4 个时间轴并排显示 | P0 |
| TC-W-COMPARE-002 | 显示数据源标题 | 每个时间轴上方显示名称 | P1 |
| TC-W-COMPARE-003 | 同步滚动 | 滚动一个时间轴，其他同步 | P0 |
| TC-W-COMPARE-004 | 动态数量 | 根据选择的数据源数量调整 | P1 |

---

## 4. 集成测试计划

**测试文件**: `test/integration/`

### 4.1 完整用户流程测试

| 测试用例 | 测试内容 | 预期结果 | 优先级 |
|---------|---------|---------|--------|
| TC-INT-001 | 应用启动流程 | 加载数据源 → 显示时间轴 | P0 |
| TC-INT-002 | 搜索并查看详情 | 搜索 → 点击结果 → 查看详情页 → 返回 | P0 |
| TC-INT-003 | 筛选数据源 | 打开筛选 → 取消勾选 → 时间轴更新 | P0 |
| TC-INT-004 | 切换视图模式 | 合并视图 → 对比视图 → 返回合并视图 | P0 |
| TC-INT-005 | 简述气泡交互 | 点击标签 → 显示气泡 → 点击详情 → 跳转 | P0 |
| TC-INT-006 | 数据源加载失败 | 显示错误信息 → 重试 → 成功加载 | P1 |

### 4.2 多数据源场景测试

| 测试用例 | 测试内容 | 预期结果 | 优先级 |
|---------|---------|---------|--------|
| TC-INT-007 | 加载多个数据源 | 所有数据源正确加载 | P0 |
| TC-INT-008 | 合并视图显示多数据源 | 事件按时间排序，颜色区分 | P0 |
| TC-INT-009 | 对比视图选择数据源 | 选择 2-4 个数据源对比 | P0 |
| TC-INT-010 | 部分数据源加载失败 | 成功的正常显示，失败的记录错误 | P1 |

---

## 5. 性能测试计划

**测试文件**: `test/performance/`

### 5.1 渲染性能测试

| 测试用例 | 测试内容 | 预期指标 | 工具 |
|---------|---------|---------|------|
| TC-PERF-001 | 滚动帧率 | ≥ 30fps | flutter_driver |
| TC-PERF-002 | 缩放帧率 | ≥ 30fps | flutter_driver |
| TC-PERF-003 | 大数据集渲染（1000 条） | 帧率稳定 | flutter_driver |
| TC-PERF-004 | 超大数据集渲染（10000 条） | 不卡顿 | flutter_driver |

### 5.2 内存测试

| 测试用例 | 测试内容 | 预期指标 | 工具 |
|---------|---------|---------|------|
| TC-MEM-001 | 初始内存使用 | < 100MB | devtools |
| TC-MEM-002 | 加载 10 个数据源后 | < 150MB | devtools |
| TC-MEM-003 | 长时间运行后 | 无内存泄漏 | devtools |
| TC-MEM-004 | 搜索索引构建后 | < 200MB | devtools |

### 5.3 加载性能测试

| 测试用例 | 测试内容 | 预期指标 | 工具 |
|---------|---------|---------|------|
| TC-LOAD-PERF-001 | 应用启动时间 | < 5 秒 | flutter_driver |
| TC-LOAD-PERF-002 | 数据源加载时间 | < 3 秒 | flutter_driver |
| TC-LOAD-PERF-003 | 搜索索引构建时间 | < 2 秒 | flutter_driver |
| TC-LOAD-PERF-004 | 搜索结果返回时间 | < 500ms | flutter_test |

---

## 6. 测试覆盖率目标

### 6.1 覆盖率要求

| 模块 | 目标覆盖率 | 说明 |
|------|-----------|------|
| 数据模型 | 95% | 核心数据结构，必须高覆盖 |
| 数据加载服务 | 90% | 包含错误处理路径 |
| 搜索系统 | 90% | 核心算法，必须高覆盖 |
| Provider | 85% | 业务逻辑核心 |
| 工具类 | 95% | 纯函数，易于测试 |
| Widget | 70% | 关键交互路径 |
| **总体** | **≥ 85%** | **需求要求** |

### 6.2 覆盖率报告

```bash
# 生成覆盖率报告
flutter test --coverage

# 查看报告
open coverage/lcov.info
```

---

## 7. 测试执行策略

### 7.1 测试执行顺序

1. **单元测试**: 每次代码提交前执行
2. **Widget 测试**: 每次 UI 变更后执行
3. **集成测试**: 每次功能完成后执行
4. **性能测试**: 每次发布前执行

### 7.2 CI/CD 集成

```yaml
# .github/workflows/test.yml
name: Test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
      - run: flutter test integration_test/
```

### 7.3 测试数据准备

**测试数据文件**: `test/fixtures/`

- `valid_source.json`: 有效的数据源 JSON
- `invalid_json.json`: 格式错误的 JSON
- `missing_fields.json`: 缺少必填字段的 JSON
- `large_dataset.json`: 大数据集（1000+ 事件）

---

## 8. 缺陷管理

### 8.1 缺陷优先级

| 优先级 | 说明 | 修复时限 |
|--------|------|---------|
| P0 | 阻塞性缺陷，核心功能无法使用 | 24 小时内 |
| P1 | 严重缺陷，影响主要功能 | 3 天内 |
| P2 | 一般缺陷，有替代方案 | 7 天内 |
| P3 | 轻微缺陷，不影响使用 | 下个版本 |

### 8.2 回归测试

- 每个修复的缺陷必须添加对应的回归测试用例
- 每次发布前执行完整的回归测试套件

---

## 9. 测试环境

### 9.1 开发环境

- Flutter SDK: latest stable (3.x)
- Dart SDK: 3.x
- 操作系统: Windows/macOS/Linux

### 9.2 测试设备

| 平台 | 设备 | 用途 |
|------|------|------|
| Android | Pixel 4 (模拟器) | 功能测试 |
| iOS | iPhone 12 (模拟器) | 功能测试 |
| Web | Chrome | 兼容性测试 |
| Windows | Windows 11 | 桌面测试 |

---

*文档版本：1.0*  
*创建日期：2026年7月*
