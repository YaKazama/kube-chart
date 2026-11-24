---
updated_at: "2026-11-24T10:55:56Z"
---

# definitions.volume downwardAPI items 格式调整规格

## MODIFIED Requirements

### Requirement: downwardAPI 卷字符串

`downwardAPI` 的字符串简写 MUST 保持 `[defaultMode] [items (<item>, ...)]`；`items` 为显式关键字，括号内 MUST 至少包含一个非空白元素，元素之间以逗号分隔，空白元素 MUST 忽略。

`items` 元素 MUST 支持两种形态，段位固定：

- field：`<path> [mode] field <fieldPath> [apiVersion]`
- resource：`<path> [mode] resource <resource> [containerName] [divisor]`

第 1 段 MUST 为 `<path>`；第 2 段 MUST 为可选 `mode`；随后 MUST 出现不区分大小写的字面量 `field` 或 `resource`。field 形态在关键字后 MUST 有 `<fieldPath>`，第 5 段 MUST 为可选 `apiVersion`。resource 形态在关键字后 MUST 有 `<resource>`，其后两段 MUST 依次为可选 `containerName` 与 `divisor`。`mode` 与 `apiVersion` MUST 接受任意非空且不含空白或逗号的字符串，MUST NOT 在 `definitions.volume` 层校验数值或版本格式；可选段缺失时 MUST NOT 改变其他段的归属。

符合形态的 item MUST 以原始字符串按输入顺序下传为 `items` 元素；`definitions.volume` MUST NOT 在本层构造 item map、`fieldRef` 或 `resourceFieldRef`，段位到字段的映射由 `definitions.downwardAPIVolumeSource` 负责。`mode` 与 `apiVersion` 缺失 MUST 视为未提供，下游映射 MUST NOT 为缺失段产生对应字段。

格式 MUST NOT 兼容旧段位：field 关键字后的末尾段 MUST 解释为 `apiVersion`，因此 `<path> field <fieldPath> <token>` MUST 视为带 `apiVersion` 的合法 field 形态；resource 形态末尾出现多于 `containerName` 与 `divisor` 的段时 MUST 不匹配。

无法匹配任一形态的 item MUST 中断渲染，错误消息 MUST 使用 `<path> [mode] field <fieldPath> [apiVersion]` 与 `<path> [mode] resource <resource> [containerName] [divisor]` 说明新段位。`items` 关键字存在但不含任何非空白元素时 MUST 中断渲染。`downwardAPI` 顶层简写无法匹配时 MUST 中断渲染。

#### Scenario: 带 mode 的 field item

- **WHEN** 输入 `{name: "dw", downwardAPI: "0644 items (meta 0400 field metadata.name)"}`
- **THEN** 输出 `downwardAPI` 上下文含 `defaultMode: "0644"`，`items` 含原始字符串 `meta 0400 field metadata.name`

#### Scenario: 省略 mode 的 field item

- **WHEN** 输入 `{name: "dw", downwardAPI: "items (meta field metadata.name)"}`
- **THEN** 输出 `items` 含原始字符串 `meta field metadata.name`

#### Scenario: 带 apiVersion 的 field item

- **WHEN** 输入 `{name: "dw", downwardAPI: "items (meta 0400 field metadata.name v1)"}`
- **THEN** 输出 `items` 含原始字符串，其段位依次为 path、mode、`field`、fieldPath、apiVersion

#### Scenario: field 末尾 token 解释为 apiVersion

- **WHEN** 输入 `{name: "dw", downwardAPI: "items (meta field metadata.name 0400)"}`
- **THEN** 渲染成功，末尾 `0400` 按 apiVersion 解释，MUST NOT 视为 mode 或导致中断

#### Scenario: 带 mode 的 resource item

- **WHEN** 输入 `{name: "dw", downwardAPI: "items (cpu 0644 resource limits.cpu app 1m)"}`
- **THEN** 输出 `items` 含原始字符串，其段位依次为 path、mode、`resource`、resource、containerName、divisor

#### Scenario: 省略 mode 与可选 resource 段

- **WHEN** 输入 `{name: "dw", downwardAPI: "items (cpu resource limits.cpu)"}`
- **THEN** 输出 `items` 含原始字符串 `cpu resource limits.cpu`

#### Scenario: 关键字不区分大小写

- **WHEN** 输入 `{name: "dw", downwardAPI: "items (meta 0400 FIELD metadata.name)"}`
- **THEN** 渲染成功，item 按 field 形态以原始字符串下传

#### Scenario: 旧 resource 末尾 mode 不再匹配

- **WHEN** 输入 `{name: "dw", downwardAPI: "items (cpu resource limits.cpu app 1m 0644)"}`
- **THEN** 渲染中断，错误消息使用新段位说明

#### Scenario: item 缺少必填段

- **WHEN** 输入 `{name: "dw", downwardAPI: "items (meta 0400 field)"}` 或 `{name: "dw", downwardAPI: "items (cpu 0644 resource)"}`
- **THEN** 渲染中断

#### Scenario: item 含多余段

- **WHEN** 输入 `{name: "dw", downwardAPI: "items (meta field metadata.name v1 extra)"}`
- **THEN** 渲染中断

#### Scenario: items 为空

- **WHEN** 输入 `{name: "dw", downwardAPI: "items ()"}`
- **THEN** 渲染中断

#### Scenario: 顶层简写不匹配

- **WHEN** 输入 `{name: "dw", downwardAPI: "meta 0400 field metadata.name"}`
- **THEN** 渲染中断

## 非目标

- 不修改 `[defaultMode] [items (<item>, ...)]` 顶层结构或 `defaultMode` 的既有处理。
- 不修改原生 map 形式的 `downwardAPI`，也不修改其他 volume source 的字符串简写。
- 不创建 `definitions.downwardAPIVolumeSource` 或 `definitions.downwardAPIVolumeFile`，不实现 item 到 `fieldRef`、`resourceFieldRef` 的映射。
- 不与 `definitions-downward-api-volume-source` 同步。
