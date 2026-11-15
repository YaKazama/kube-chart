---
updated_at: "2026-11-15T13:16:22Z"
---

# resources 支持从文件读取配置规格

## Purpose

让 `resources` 可以从 Chart 内文件按给定字段路径读取，减少在 values 中重复维护资源声明。

## ADDED Requirements

### Requirement: resourcesFileRefs 的输入形态与生效优先级

系统 MUST 接受 `resourcesFileRefs` 的 array 与 map 两种形态；两种形态 MUST 产生等价的读取结果；`resourcesFileRefs` 的优先级 MUST 高于 `resources`。

#### Scenario: array 形态

- **WHEN** `resourcesFileRefs` 为数组，每个元素包含 `filePath` 与可选 `fieldPaths`
- **THEN** 逐个元素独立读取，并按元素顺序合并结果

#### Scenario: map 形态

- **WHEN** `resourcesFileRefs` 为 map，包含 `filePath` 与可选 `fieldPaths`
- **THEN** 按单个元素读取，结果与等价 array 形态一致

#### Scenario: 与 resources 同时存在

- **WHEN** `resourcesFileRefs` 解析出有效内容，且同时设置了 `resources`
- **THEN** 只使用文件内容渲染 `resources`，内联 `resources` 不生效

### Requirement: 未生效时回退到 inline resources

系统 MUST 在 `resourcesFileRefs` 键不存在、为 `null` 或解析后无有效项时回退到 `resources`；回退时 MUST 保持 `resources` 现有 map 与字符串简写形态的解析行为不变。

#### Scenario: 未设置 resourcesFileRefs

- **WHEN** values 中没有 `resourcesFileRefs` 且设置了 `resources`
- **THEN** 按现有规则渲染 `resources`

#### Scenario: resourcesFileRefs 为 null

- **WHEN** `resourcesFileRefs` 显式为 `null`
- **THEN** 回退到 `resources`

#### Scenario: 解析后无有效项

- **WHEN** `resourcesFileRefs` 已设置但未产生任何有效内容
- **THEN** 回退到 `resources`

#### Scenario: 两者都未设置

- **WHEN** `resourcesFileRefs` 与 `resources` 均未设置
- **THEN** 不输出 `resources` 字段

### Requirement: 按字段路径从文件读取内容

系统 MUST 使用 `filePath` 定位 Chart 内文件，并按 `fieldPaths` 中每个路径依次读取内容；路径 MUST 仅以 `.` 分隔，键名中的其他字符（如 `-`）MUST NOT 被当作分隔符；`fieldPaths` 为空时 MUST 使用 `filePath` 的文件名去掉最后一个扩展名作为唯一路径；文件名不含扩展名时 MUST 使用完整文件名。

#### Scenario: 指定单个字段路径

- **WHEN** `filePath` 指向存在且合法的 YAML 文件，`fieldPaths` 含一个能命中的路径
- **THEN** 读取该路径对应的内容

#### Scenario: 省略 fieldPaths

- **WHEN** `filePath` 为 `_configs/resources.yaml` 且未设置 `fieldPaths`
- **THEN** 以 `resources` 为字段路径读取

#### Scenario: 多个字段路径

- **WHEN** `fieldPaths` 含多个路径
- **THEN** 按列表顺序逐个读取，并按该顺序参与合并

#### Scenario: 文件名无扩展名

- **WHEN** `filePath` 指向的文件名不含扩展名且未设置 `fieldPaths`
- **THEN** 以完整文件名作为字段路径读取

#### Scenario: 键名含连字符

- **WHEN** 字段路径为 `resources.ephemeral-storage` 且文件含该键
- **THEN** 取到该键的值，不按 `-` 拆分为多段

#### Scenario: 字段路径未命中

- **WHEN** 某个 `fieldPaths` 路径在文件内容中不存在
- **THEN** 渲染中断

### Requirement: 合并规则

系统 MUST 按读取顺序累加各路径结果：首条结果直接采用；此后两侧均为 map 时 MUST 递归合并，同一键冲突 MUST 以后命中为准；任一侧不是 map 时 MUST 用后命中结果整体覆盖前值；`resources` 的最终结果 MUST 可恢复为 map。

#### Scenario: map 递归合并

- **WHEN** 两项结果都是 map，同名键下均为 map 且内部键不同
- **THEN** 输出保留两者的内部键，同名键以后命中为准

#### Scenario: 同键冲突

- **WHEN** 两项结果都是 map 且含同名标量键
- **THEN** 输出采用后命中项的值

#### Scenario: 非 map 结果整体覆盖

- **WHEN** 前一项结果为 map，后一项为 slice 或标量
- **THEN** 输出整体为后一项结果

#### Scenario: 类型不一致

- **WHEN** 同名键在前一项为 map、后一项为字符串
- **THEN** 输出采用后命中项的值，不中断

#### Scenario: 内容含 array 值

- **WHEN** 读取到的 map 含 array 类型的值
- **THEN** 该值正常参与合并与渲染，不中断

#### Scenario: resources 最终结果不是 map

- **WHEN** `resourcesFileRefs` 的累加结果无法恢复为 map
- **THEN** 渲染中断

### Requirement: 读取失败边界

系统 MUST 在 `filePath` 缺失或为空白、文件不存在、文件为空、文件不是合法 YAML、文件顶层不是 mapping、路径逃逸 Chart 根目录时中断渲染。

#### Scenario: filePath 缺失或为空白

- **WHEN** 任一 fileRefs 元素缺少 `filePath` 或其仅为空白
- **THEN** 渲染中断

#### Scenario: 文件不存在或为空

- **WHEN** `filePath` 指向的文件在 Chart 内不存在或内容为空
- **THEN** 渲染中断

#### Scenario: 文件不是合法 YAML

- **WHEN** 文件内容无法解析为 YAML，或顶层不是 mapping
- **THEN** 渲染中断

#### Scenario: 路径逃逸 Chart 根目录

- **WHEN** `filePath` 为绝对路径，或规范化后为 `..` 或位于 Chart 根目录之外
- **THEN** 渲染中断

## 非目标

- 不改变 `resources` 现有 map 与字符串简写形态的解析行为。
- 不改变 `resources.claims` 现有的解析与渲染边界。
- 不新增 Chart 外的远程或绝对路径读取。
- 不处理 `resources` 以外字段的文件读取能力。
- 不更新 values Schema、README、`docs/` 或样例。
