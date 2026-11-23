---
updated_at: "2026-11-23T16:21:32Z"
---

# definitions.configMapVolumeSource 规格

## Purpose

为 `definitions.volume` 的 configMap source 提供按 Kubernetes ConfigMapVolumeSource 字段顺序渲染的共享结构能力，并把文件模式统一归一化为十进制整数。

## ADDED Requirements

### Requirement: ConfigMapVolumeSource 输入与字段顺序

本能力 MUST 以 `definitions.configMapVolumeSource` 命名模板提供。系统 MUST 接受 map 上下文，其他类型 MUST 中断。

系统 MUST 按 `defaultMode`、`items`、`name`、`optional` 的顺序输出已生效字段。`name` 必填，`defaultMode`、`items`、`optional` 可选；可选字段缺失、`null` 或空白时 MUST NOT 输出，显式 `false` MUST 输出；非法值 MUST 中断。

#### Scenario: 最小有效输入

- **WHEN** 输入只含 `name`
- **THEN** 只输出 `name`

#### Scenario: 完整输入

- **WHEN** 输入含 `name`、`defaultMode`、`items` 与 `optional`
- **THEN** 按 `defaultMode`、`items`、`name`、`optional` 顺序输出四个字段

#### Scenario: 非 map 输入

- **WHEN** 上下文不是 map
- **THEN** 渲染中断

### Requirement: name 校验

`name` MUST 是 DNS Subdomain，即 RFC1123 Subdomain 且不超过 253 字符。校验前 MUST 只 trim，MUST NOT 做小写或其他归一化。缺失、空或不符合规则时 MUST 中断。

#### Scenario: 合法名称

- **WHEN** `name` 为 `app.config`
- **THEN** 输出带引号的 `name: "app.config"`

#### Scenario: 大写名称

- **WHEN** `name` 含大写字母
- **THEN** 渲染中断

#### Scenario: 缺失、空或超长

- **WHEN** `name` 缺失、trim 后为空或超过 253 字符
- **THEN** 渲染中断

### Requirement: defaultMode 归一化

`defaultMode` MUST 接受八进制 `0000`-`0777` 字符串，或十进制 `0`-`511` 的数值与字符串，并 MUST 输出十进制 int。`defaultMode` 为空时 MUST NOT 输出；越界或非法值 MUST 中断。

#### Scenario: 八进制字符串

- **WHEN** `defaultMode` 为 `"0755"`
- **THEN** 输出 `defaultMode: 493`

#### Scenario: 十进制边界值

- **WHEN** `defaultMode` 为数值 `0` 或 `511`
- **THEN** 分别输出 `defaultMode: 0` 与 `defaultMode: 511`

#### Scenario: 越界或非法

- **WHEN** `defaultMode` 为 `"0778"`、`"9999"` 或非模式字符串
- **THEN** 渲染中断

### Requirement: items 归一化与 keyToPath 委托

`items` MUST 接受 map 数组、string 数组或两者混合，并 MUST 按输入顺序处理元素。string 元素 MUST 按 `<key> <path> [mode]` 解析并用捕获值构造 `{key, path, mode}` map；`mode` 缺失时 MUST NOT 包含该键，捕获值 MUST 原样下传。map 元素 MUST 原样下传。

每个元素 MUST 以该 map 调用 `definitions.keyToPath`，并按返回的 map 渲染 `items` 数组。`items` 为空数组或元素全部为空白时 MUST NOT 输出；`items` 不是数组、元素不是 map 或 string、string 元素不匹配格式，或 `definitions.keyToPath` 输出为空、非 map 或非法 YAML 时 MUST 中断。

#### Scenario: string 数组

- **WHEN** `items` 为 `["key path", "key1 path1 0400"]`
- **THEN** 构造两个 item，第二个包含原样下传的 `mode: "0400"`，并按顺序渲染

#### Scenario: map 与 string 混合

- **WHEN** `items` 同时包含 `{key: k, path: p}` 与 `k2 p2`
- **THEN** 两个 item 按输入顺序渲染

#### Scenario: 空或全空白

- **WHEN** `items` 为空数组或元素全部为空白字符串
- **THEN** 不输出 `items`

#### Scenario: 子模板输出为空

- **WHEN** `definitions.keyToPath` 返回空内容
- **THEN** 渲染中断

#### Scenario: 元素或数组非法

- **WHEN** `items` 不是数组，或元素不是 map/string，或 string 元素段数不在 2-3
- **THEN** 渲染中断

### Requirement: 文件模式归一化

本 change 的文件模式归一化 MUST 接受数值或字符串输入。字符串 MUST 接受八进制 `0000`-`0777` 或十进制 `0`-`511`，包含单字符十进制 `"9"`；以 `0` 开头的四位字符串 MUST 按八进制解释；MUST 归一化为十进制 int 返回。数值 MUST 位于 `0`-`511`。越界或非法值 MUST 中断。

#### Scenario: 八进制字符串转十进制

- **WHEN** 输入字符串 `"0755"`
- **THEN** 返回 int `493`

#### Scenario: 前导零八进制字符串

- **WHEN** 输入字符串 `"0512"`
- **THEN** 返回 int `330`

#### Scenario: 单字符十进制字符串

- **WHEN** 输入字符串 `"9"`
- **THEN** 返回 int `9`

#### Scenario: 非法文件模式

- **WHEN** 输入 `"9999"`、`"0778"` 或数值 `512`
- **THEN** 渲染中断

## 非目标

- 不创建 `definitions.keyToPath` 子模板。
- 不实现本 change 之外的 VolumeSource 子模板。
- 不改变 `definitions.volume` 的字段顺序或字符串简写。
- 不改变其他公共模板的行为，仅修正文件模式归一化。
