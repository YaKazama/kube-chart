---
updated_at: "2026-11-21T16:45:46Z"
---

# definitions.volumeMount 规格

## Purpose

`definitions.volumeMount` 把 VolumeMount 字段 map 或字符串简写渲染为 Kubernetes `volumeMount` 字段片段，并供 `definitions.container` 的 `volumeMounts` 数组逐项委托。

## ADDED Requirements

### Requirement: VolumeMount map 渲染

系统 MUST 接受 VolumeMount 字段 map，并按 `mountPath`、`mountPropagation`、`name`、`readOnly`、`recursiveReadOnly`、`subPath`、`subPathExpr` 的顺序输出已提供字段；未提供或为空的字段 MUST 省略。输入既不是 map 也不是字符串时 MUST 中断渲染并报错。

#### Scenario: 最小 map

- **WHEN** 输入仅包含 `name: data` 与 `mountPath: /data`
- **THEN** 输出仅包含 `mountPath: "/data"` 与 `name: "data"`，且顺序与字段表一致

#### Scenario: 大写 name 规范化

- **WHEN** 输入 `name: Data` 与 `mountPath: /data`
- **THEN** 输出 `name: "data"`，并通过 RFC1123 校验

#### Scenario: 完整 map

- **WHEN** 输入包含 `name`、`mountPath`、`mountPropagation`、`readOnly`、`recursiveReadOnly` 与 `subPath`/`subPathExpr` 之一，且满足本规格约束
- **THEN** 输出按字段表顺序包含全部已提供字段

#### Scenario: 显式 readOnly false

- **WHEN** 输入提供 `readOnly: false` 且未提供 `recursiveReadOnly`
- **THEN** 输出包含 `readOnly: false`

#### Scenario: 未提供 readOnly

- **WHEN** 输入未提供 `readOnly`
- **THEN** 输出省略 `readOnly`

### Requirement: VolumeMount 字符串简写解析

系统 MUST 接受 `<name> <mountPath> [subPath|subPathExpr] [readOnly] [recursiveReadOnly] [mountPropagation]` 形式的字符串。字段之间 MUST 由一个或多个空白或逗号分隔，整个字符串 MUST 匹配该格式，且匹配 MUST 不区分大小写。第 3 段 MUST 按 `$(VAR_NAME)` 变量形式整段匹配：命中时作为 `subPathExpr`，否则作为 `subPath`。未提供的尾部可选段 MUST 按空值处理并在输出中省略；可选段 MUST 按位置解析，不能跳过前面的可选段直接提供后续段。捕获后的 `readOnly`、`recursiveReadOnly` 与 `mountPropagation` MUST 继续执行区分大小写的值校验，非规范拼写 MUST 中断渲染。

#### Scenario: 仅必填段

- **WHEN** 输入为 `data /data`
- **THEN** 输出仅包含 `mountPath: "/data"` 与 `name: "data"`

#### Scenario: 格式匹配不区分大小写

- **WHEN** 输入为 `DATA /data`
- **THEN** 匹配成功，`name` 规范化为 `data`，输出 `name: "data"`

#### Scenario: 枚举大小写变体被值校验拒绝

- **WHEN** 输入为 `data, /data, cache-v1, TRUE, Enabled, None`
- **THEN** 格式匹配成功，但 `readOnly` 值校验失败并中断渲染

#### Scenario: 完整六段

- **WHEN** 输入为 `data, /data, cache-v1, true, IfPossible, None`
- **THEN** 第 3 段作为 `subPath`，并输出 `readOnly: true`、`recursiveReadOnly: "IfPossible"`、`mountPropagation: "None"`

#### Scenario: 第 3 段为变量

- **WHEN** 第 3 段为 `$(POD_NAME)`
- **THEN** 输出 `subPathExpr: "$(POD_NAME)"` 且不输出 `subPath`

#### Scenario: 第 3 段不是整段变量

- **WHEN** 第 3 段为 `prefix-$(POD_NAME)`
- **THEN** 输出 `subPath: "prefix-$(POD_NAME)"` 且不输出 `subPathExpr`

#### Scenario: 格式不匹配

- **WHEN** 字符串缺少必填段、超过六个非空段或含格式外字符
- **THEN** 中断渲染并报错

### Requirement: VolumeMount 字段约束

系统 MUST 在 map 与字符串简写归一化后执行以下校验；任一失败 MUST 中断渲染并报错：

- `name` 与 `mountPath` 必填且非空。
- `name` MUST 在 RFC1123 校验与输出前规范化为小写，并匹配 Kubernetes Volume 名称允许的 RFC1123 Label。
- `mountPath` MUST NOT 包含 `:`。
- `subPath` 与 `subPathExpr` MUST NOT 同时非空。
- `readOnly` 仅接受 `true` 或 `false`。
- `recursiveReadOnly` 仅接受 `Disabled`、`IfPossible` 或 `Enabled`。
- `mountPropagation` 仅接受 `Bidirectional`、`HostToContainer` 或 `None`。
- `readOnly`、`recursiveReadOnly` 与 `mountPropagation` 的值校验 MUST 区分大小写，仅接受规范拼写。
- `recursiveReadOnly` 非空时，`readOnly` MUST 为 `true`。
- `recursiveReadOnly` 为 `IfPossible` 或 `Enabled` 时，`mountPropagation` MUST 为 `None` 或未提供。

#### Scenario: 必填字段缺失

- **WHEN** `name` 或 `mountPath` 缺失、为空或仅含空白
- **THEN** 中断渲染并报错

#### Scenario: 名称或挂载路径非法

- **WHEN** `name` 规范化为小写后仍不满足 RFC1123 Label，或 `mountPath` 包含 `:`
- **THEN** 中断渲染并报错

#### Scenario: 路径互斥

- **WHEN** `subPath` 与 `subPathExpr` 同时非空
- **THEN** 中断渲染并报错

#### Scenario: 布尔或枚举非法

- **WHEN** `readOnly` 不是 `true`/`false`（含大小写变体），或 `recursiveReadOnly`、`mountPropagation` 不在允许集合中（含大小写变体）
- **THEN** 中断渲染并报错

#### Scenario: recursiveReadOnly 前提不满足

- **WHEN** `recursiveReadOnly` 非空，而 `readOnly` 未提供或为 `false`
- **THEN** 中断渲染并报错

#### Scenario: 递归只读与传播模式冲突

- **WHEN** `recursiveReadOnly` 为 `IfPossible` 或 `Enabled`，且 `mountPropagation` 为 `Bidirectional` 或 `HostToContainer`
- **THEN** 中断渲染并报错

### Requirement: Container volumeMounts 混合数组

`definitions.container` MUST 接受 `volumeMounts` 数组；数组元素 MUST 为 VolumeMount map 或字符串简写。混合元素 MUST 按数组原顺序逐项渲染，每个元素独立执行本规格的校验与字段输出。

#### Scenario: 混合元素保持顺序

- **WHEN** `volumeMounts` 依次包含 map、字符串简写和 map
- **THEN** 输出顺序与输入顺序一致，且每个元素按其自身输入形态渲染

#### Scenario: volumeMounts 不是数组

- **WHEN** `volumeMounts` 不是数组
- **THEN** 中断渲染并报错

#### Scenario: 元素类型非法

- **WHEN** `volumeMounts` 元素既不是 map 也不是 string
- **THEN** 中断渲染并报错

## 非目标

- 不覆盖 `volumeMount` 以外的 Kubernetes 字段或资源类型。
- 不改变 `definitions.container` 其他字段的渲染与顺序。
- 不处理 Volume 源定义、`volumeDevices` 或 Pod 级卷配置。
