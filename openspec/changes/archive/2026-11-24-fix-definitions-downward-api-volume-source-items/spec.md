---
updated_at: "2026-11-24T14:19:51Z"
---

# definitions.downwardAPIVolumeSource items 过滤规格

## MODIFIED Requirements

### Requirement: downwardAPI 卷源 defaultMode 与 items 输入

`definitions.downwardAPIVolumeSource` MUST 接受 map 上下文，兼容原生 `DownwardAPIVolumeSource` map 与父模板清洗后的 map。

`defaultMode` MUST 接受八进制 `0xxx` 或十进制 0-511 的数值或字符串，并归一化为十进制 int 输出；未提供或空值 MUST 省略，显式 0 MUST 输出。

`items` MUST 接受 array，元素 MUST 为 map 或 string，允许两者混合。空白 string item MUST 跳过；`items` 缺失、空数组或元素均为空白 string 时 MUST 省略。`items` 不是 array，或元素既不是 map 也不是 string 时 MUST 中断渲染。

string item MUST 全量匹配以下两种形态之一：`<path> [mode] field <fieldPath> [apiVersion]` 或 `<path> [mode] resource <resource> [containerName] [divisor]`。同时匹配两种形态时 MUST 按 field 形态处理；两种形态都不匹配时 MUST 中断渲染。

匹配 field 形态时 MUST 向 `definitions.downwardAPIVolumeFile` 传 `{path, [mode], fieldRef}`，匹配 resource 形态时 MUST 传 `{path, [mode], resourceFieldRef}`。`path`、`mode` 与 `*Ref` 串 MUST 直接取自匹配文本，MUST NOT 归一化路径、解码 YAML 标量、剥离引号或改写取值；`mode` 缺失时 MUST NOT 写入该键。

`fieldRef` 串 MUST 为 `<fieldPath>` 或 `<fieldPath> <apiVersion>`；`resourceFieldRef` 串 MUST 为 `<resource>`、`<resource> <containerName>` 或 `<resource> <containerName> <divisor>`。两个 `*Ref` 串 MUST 保持 string 类型，MUST NOT 在 `definitions.downwardAPIVolumeSource` 内被构造为 map。

原生 map item MUST 原样传递，MUST NOT 清洗、改写或补全字段。

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

#### Scenario: field string item 过滤

- **WHEN** 输入 `{items: ["  meta 0400 field metadata.name  "]}`
- **THEN** `definitions.downwardAPIVolumeFile` 收到 `{path: "meta", mode: "0400", fieldRef: "metadata.name"}`

#### Scenario: field 可选段缺失

- **WHEN** 输入 `{items: ["meta2 field metadata.name v1"]}`
- **THEN** `definitions.downwardAPIVolumeFile` 收到 `{path: "meta2", fieldRef: "metadata.name v1"}`，不含 `mode`

#### Scenario: resource string item 过滤

- **WHEN** 输入 `{items: ["cpu 0644 resource limits.cpu app 1m"]}`
- **THEN** `definitions.downwardAPIVolumeFile` 收到 `{path: "cpu", mode: "0644", resourceFieldRef: "limits.cpu app 1m"}`

#### Scenario: string item 形态不匹配

- **WHEN** 输入 `{items: ["meta"]}` 或两种形态都不匹配的 string
- **THEN** 渲染中断

#### Scenario: map item 原样传递

- **WHEN** 输入 `{items: [{path: labels, fieldRef: {fieldPath: metadata.labels}}]}`
- **THEN** `definitions.downwardAPIVolumeFile` 收到该 map 原值，字段不被改写或补全

#### Scenario: map 与 string item 混合

- **WHEN** 输入 `{items: [{path: labels, fieldRef: {fieldPath: metadata.labels}}, "cpu 0644 resource limits.cpu app 1m"]}`
- **THEN** 两个元素按输入顺序分别以原 map 与过滤后的上下文传给子模板

### Requirement: downwardAPI item 委托与输出

每个 item MUST 委托 `definitions.downwardAPIVolumeFile` 渲染；输出为空时 MUST 跳过该元素；输出非法 YAML 或非 map 时 MUST 中断渲染。`items` 输出 MUST 保持输入顺序。

`fieldRef`/`resourceFieldRef` 的字段拆分、内部字段校验与互斥判定，以及通过 `definitions.objectFieldSelector`/`definitions.resourceFieldSelector` 渲染这两个字段 MUST 由 `definitions.downwardAPIVolumeFile` 负责；`definitions.downwardAPIVolumeSource` MUST NOT 构造这两个字段的 map。

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

- 不实现 `definitions.downwardAPIVolumeFile`。
- 不在本模板构造、校验或清洗 `fieldRef`/`resourceFieldRef` 内部字段，也不处理两者互斥。
- 不归一化 `path`，不清洗原生 map item。
- 不保留 `{item: <原始字符串>}` 包装形态。
- 不扩展其他卷源类型。
- 不把原生 map 接受 string item 的意外兼容固化为推荐输入格式。
