---
updated_at: "2026-11-24T13:41:11Z"
---

# definitions.downwardAPIVolumeSource 规格

## Purpose

归一化 downwardAPI 卷源的 `defaultMode` 与 `items` 容器结构，并把每个 item 原样委托给 `definitions.downwardAPIVolumeFile`。

## ADDED Requirements

### Requirement: downwardAPI 卷源 defaultMode 与 items 输入

`definitions.downwardAPIVolumeSource` MUST 接受 map 上下文，兼容原生 `DownwardAPIVolumeSource` map 与父模板清洗后的 map。

`defaultMode` MUST 接受八进制 `0xxx` 或十进制 0-511 的数值或字符串，并归一化为十进制 int 输出；未提供或空值 MUST 省略，显式 0 MUST 输出。

`items` MUST 接受 array，元素 MUST 为 map 或 string，允许两者混合。string item MUST 以 `{item: <原始字符串>}` 的形式传给 `definitions.downwardAPIVolumeFile`，MUST NOT 被本模板改写；map item MUST 原样传递。空白 string MUST 跳过；`items` 缺失、空数组或元素均为空白 string 时 MUST 省略。`items` 不是 array，或元素既不是 map 也不是 string 时 MUST 中断渲染。

#### Scenario: 八进制 defaultMode

- **WHEN** 输入 `{defaultMode: "0644", items: ["meta field metadata.name"]}`
- **THEN** 输出字段片段含 `defaultMode: 420`

#### Scenario: defaultMode 显式 0

- **WHEN** 输入 `{defaultMode: 0}`
- **THEN** 输出字段片段含 `defaultMode: 0`

#### Scenario: defaultMode 非法

- **WHEN** 输入 `{defaultMode: "0999"}` 或 `{defaultMode: "abc"}`
- **THEN** 渲染中断

#### Scenario: items 为空

- **WHEN** 输入 `{items: []}`、缺少 `items` 或 `items` 仅含空白 string
- **THEN** 输出字段片段省略 `items`

#### Scenario: items 类型非法

- **WHEN** 输入 `{items: "meta field metadata.name"}`
- **THEN** 渲染中断

#### Scenario: items 元素类型非法

- **WHEN** `items` 含 number、bool 或 null 元素
- **THEN** 渲染中断

#### Scenario: string item 原样传递

- **WHEN** 输入 `{items: ["meta 0400 field metadata.name"]}`
- **THEN** `definitions.downwardAPIVolumeFile` 收到 `{item: "meta 0400 field metadata.name"}`，本模板不构造 `path`、`fieldRef` 或 `mode`

#### Scenario: map item 原样传递

- **WHEN** 输入 `{items: [{path: labels, fieldRef: {fieldPath: metadata.labels}}]}`
- **THEN** `definitions.downwardAPIVolumeFile` 收到该 map 原值

#### Scenario: map 与 string item 混合

- **WHEN** 输入 `{items: [{path: labels, fieldRef: {fieldPath: metadata.labels}}, "cpu 0644 resource limits.cpu app 1m"]}`
- **THEN** 两个元素均按原值传给子模板，状态与顺序不变

### Requirement: downwardAPI item 委托与输出

每个 item MUST 委托 `definitions.downwardAPIVolumeFile` 渲染；输出为空时 MUST 跳过该元素；输出非法 YAML 或非 map 时 MUST 中断。`items` 输出 MUST 保持输入顺序。

string item 的段位解析、`fieldRef`/`resourceFieldRef` 构造、`mode` 提取与 `path` 归一化 MUST 由 `definitions.downwardAPIVolumeFile` 负责；本模板 MUST NOT 重复实现。

#### Scenario: 子模板收到 string item 包装

- **WHEN** 输入 `{items: ["cpu 0644 resource limits.cpu app 1m"]}`
- **THEN** 子模板收到 `{item: "cpu 0644 resource limits.cpu app 1m"}`，由子模板解析段位

#### Scenario: 子模板输出为空

- **WHEN** `definitions.downwardAPIVolumeFile` 对某个 item 返回空内容
- **THEN** 该元素不进入 `items` 输出

#### Scenario: 子模板输出非法 YAML 或非 map

- **WHEN** `definitions.downwardAPIVolumeFile` 返回非法 YAML 或 YAML array/scalar
- **THEN** 渲染中断

#### Scenario: 保持输入顺序

- **WHEN** `items` 含多个有效元素
- **THEN** 输出顺序与输入顺序一致

## 非目标

- 不实现 `definitions.downwardAPIVolumeFile` 的清洗与渲染。
- 不在本模板解析 string item 段位、构造 item map、校验 `fieldRef`/`resourceFieldRef` 内部字段或判定两者互斥。
- 不在本模板归一化 `path`。
- 不扩展其他卷源类型。
- 不把原生 map 接受 string item 的意外兼容固化为推荐输入格式。
