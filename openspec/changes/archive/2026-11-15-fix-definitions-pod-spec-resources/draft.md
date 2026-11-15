---
change-id: fix-definitions-pod-spec-resources
updated_at: "2026-11-15T13:16:22Z"
---

# resources 支持从文件读取配置

## 目标

- 让 `resources` 配置可以从 Chart 内文件读取，避免在 values 中重复维护大段资源声明。

## 需求

- 新增 `resourcesFileRefs`，支持 array 与 map 两种输入形态。
- `resourcesFileRefs` 的优先级高于 `resources`。
- `resourcesFileRefs` 键不存在、为 `null`，或已指定但解析后无有效项时，回退到 `resources`。
- `fieldPaths` 是外部文件中的取值路径，格式为 `path.to.key`，可以为空。
- 每个 fileRefs 元素只包含一个 `fieldPaths`；array 形态下每个元素亦然。
- `fieldPaths` 为空时，使用 `filePath` 的文件名去掉最后一个扩展名作为单个字段路径；不限定扩展名类型。
- `fieldPaths` 是一个路径列表，按列表顺序读取并合并结果；`resourcesFileRefs` 为 array 时，多个元素仍独立处理，其内容同样按列表顺序合并。
- 合并时同一键冲突以后命中为准；两侧均为 map 时等价 Helm `mustMergeOverwrite` 递归合并，slice、string 与其他类型整体覆盖。
- `base.fileRefs` 不限定返回类型，可取到 map、slice、string 等；`resources` 的最终结果必须是 map，否则中断报错。
- 内容中的 array 值按合并语义保留或覆盖，不单独视为非法。
- 同一字段路径多次命中或 `fieldPaths` 的值之间类型不一致时，以后命中为准，不中断。
- 某个 fileRefs 元素的 `filePath` 缺失或为空白时中断报错。
- `filePath` 指向的文件不存在、为空或不是合法 YAML 时中断报错。
- `*FileRefs` 的处理模板作为公共模板，命名模板为 `base.fileRefs`，文件位于 `templates/base/_fileRefs.tpl`，职责为“从文件按给定的路径读取并返回序列化后的内容”。
- `filePath` 为 Chart 内相对路径。
- `base.fileRefs` 由 `core.podSpec` 直接调用，`core.podSpec` 自身的上下文已包含 `Files`；文件读取与合并在 `base.fileRefs` 层完成，只把累加结果传给 `definitions.resourceRequirements`，不向子模板透传 `Files`。
- `fieldPaths` 的取值复用 `base.map.dig`；该模板改为仅以 `.` 分隔路径，键名中的 `-` 等字符不再被拆分。
- 合并文件内容后仍交给既有资源字段处理模板渲染，不改其字段白名单与失败边界。
- 本 change 的作用范围仅限 `resources`；其他字段若需同类能力，由后续独立 change 处理。

## 期望输入格式

array 形态：

```yaml
resourcesFileRefs:
  - filePath: _configs/resources.yaml
    fieldPaths:
      - resources.resources1

```

map 形态：

```yaml
resourcesFileRefs:
  filePath: _configs/resources.yaml
  fieldPaths:
    - resources.resources1

```

## 约束

- `filePath` 与 `fieldPaths` 的语义由本 change 定义，不得由上游 values 结构决定。
- `values Schema` 需等开发完成并通过首次完整验收后再处理，本 change 不处理。

## 非目标

- 不改变 `resources` 现有 map 与字符串简写形态的解析行为。
- 不改变 `resources.claims` 现有的解析与渲染边界。
- 不新增 Chart 外的远程或绝对路径读取。
- 不处理 `resources` 以外字段的文件读取能力。
- 不在本 change 中更新 values Schema、README、`docs/` 或样例。

## 验收

- array 与 map 两种 `resourcesFileRefs` 形态都能渲染出与内联 `resources` 等价的资源字段。
- `resourcesFileRefs` 与 `resources` 同时存在时，以文件内容为准。
- `resourcesFileRefs` 缺失、为 `null` 或解析后无有效项时，使用 `resources`。
- `fieldPaths` 省略时按文件名推导字段路径并正确取值。
- `fieldPaths` 的多个值与 array 多元素的内容均按列表顺序合并，同键以后命中为准；两侧均为 map 时递归合并，其他类型整体覆盖。
- `resources` 的累加结果不是 map 时渲染中断；类型不一致与内容中的 array 值不中断。
- 含 `-` 的键名路径能正确取值。
- `filePath` 缺失、为空白、文件不存在、文件为空或文件不是合法 YAML 时渲染中断。

## 开放问题

- 无。
