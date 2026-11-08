---
updated_at: "2026-11-08T16:00:22Z"
---

# PodAffinityTerm 共享结构规格

## Purpose

为 Kubernetes `PodAffinityTerm` 对象提供共享结构渲染入口，把父级传入的术语字段渲染为可嵌入 `requiredDuringSchedulingIgnoredDuringExecution` 单个元素或 `definitions.weightedPodAffinityTerm` 内 `podAffinityTerm` 的 YAML 字段片段。

## ADDED Requirements

### Requirement: 渲染 PodAffinityTerm 字段片段

系统 MUST 从入参 map 读取 `labelSelector`、`matchLabelKeys`、`mismatchLabelKeys`、`namespaceSelector`、`namespaces`、`topologyKey`，并按该顺序输出。

系统 MUST 输出可嵌入 `requiredDuringSchedulingIgnoredDuringExecution` 单个元素或 `podAffinityTerm` 字段的 YAML 字段片段。

系统 MUST 识别每个字段的同级 `<键名>Alias`；非空别名 MUST 优先于同名规范键，别名缺失或为空时 MUST 回退同名规范键。

入参中除上述六个字段及其同级别名以外的字段 MUST 被忽略，MUST NOT 参与输出。

系统 MUST NOT 输出 `status` 或规格未定义的其他字段。

#### Scenario: 全部可选字段与 topologyKey 提供

- **WHEN** 入参提供合法的 `topologyKey` 与全部可选字段
- **THEN** 输出按 `labelSelector`、`matchLabelKeys`、`mismatchLabelKeys`、`namespaceSelector`、`namespaces`、`topologyKey` 的顺序包含这些字段

#### Scenario: 只提供 topologyKey

- **WHEN** 入参只提供合法的 `topologyKey`
- **THEN** 输出只包含 `topologyKey`

#### Scenario: 别名优先

- **WHEN** 入参同时提供 `topologyKey` 与取值不同的 `topologyKeyAlias`
- **THEN** 输出使用 `topologyKeyAlias` 的取值

#### Scenario: 空别名回退

- **WHEN** 入参提供空的 `labelSelectorAlias` 与非空的 `labelSelector`
- **THEN** 输出使用 `labelSelector` 的取值

#### Scenario: 未定义字段被忽略

- **WHEN** 入参除六个字段外还包含其他键
- **THEN** 输出不包含这些键

### Requirement: 校验 topologyKey

系统 MUST 要求 `topologyKey` 存在且为非空 string。

`topologyKey` MUST 满足 Kubernetes 标签键语法：可选的前缀段加 `/` 分隔符，加名称段；名称段 MUST 为首尾字母数字、中间允许 `-`、`_`、`.` 且不超过 63 字符，前缀段 MUST 为点分隔的小写 DNS 标签且总长不超过 253 字符。

`topologyKey` 缺失、为 `null` 或为空字符串时 MUST 中断渲染。

`topologyKey` 不是 string 类型（布尔、数值、map、list）时 MUST 中断渲染。

`topologyKey` 不符合标签键语法时 MUST 中断渲染。

#### Scenario: topologyKey 缺失或为空

- **WHEN** 入参不含 `topologyKey`，或其值为 `null`、空字符串
- **THEN** 渲染中断并返回错误

#### Scenario: topologyKey 不是 string

- **WHEN** `topologyKey` 为布尔值、数值、map 或 list
- **THEN** 渲染中断并返回错误

#### Scenario: topologyKey 语法非法

- **WHEN** `topologyKey` 为 `-zone`、`zone-`、`Zone Key`、`a/b/c`，或名称段超过 63 字符
- **THEN** 渲染中断并返回错误

#### Scenario: topologyKey 语法合法

- **WHEN** `topologyKey` 为 `zone` 或 `topology.kubernetes.io/zone`
- **THEN** 输出 `topologyKey` 且取值为该字符串

### Requirement: 渲染 labelSelector 与 namespaceSelector

系统 MUST 把 `labelSelector` 与 `namespaceSelector` 的 map 原样作为上下文委托共享结构渲染，并以该渲染结果作为同名字段内容。

系统 MUST NOT 自行解析或改写其内部的 `matchExpressions`、`matchLabels`。

`labelSelector` 或 `namespaceSelector` 缺失、为 `null` 或为空 map 时 MUST NOT 输出对应字段。

取值不是 map 时 MUST 中断渲染。

委托结果无法恢复为 map 时 MUST 中断渲染；委托结果为空时 MUST NOT 输出对应字段。

#### Scenario: 原样委托

- **WHEN** `labelSelector` 含 `matchExpressions` 与 `matchLabels`
- **THEN** 两者原样传入共享结构渲染，输出 `labelSelector` 取自该渲染结果

#### Scenario: 选择器为空

- **WHEN** `labelSelector` 或 `namespaceSelector` 缺失、为 `null` 或为空 map
- **THEN** 输出不包含对应字段

#### Scenario: 选择器不是 map

- **WHEN** `labelSelector` 为字符串、数值或 list
- **THEN** 渲染中断并返回错误

### Requirement: 渲染 matchLabelKeys 与 mismatchLabelKeys

系统 MUST 把 `matchLabelKeys` 与 `mismatchLabelKeys` 输出为 string array。

两个字段的列表项 MUST 按与 `topologyKey` 相同的标签键语法校验。

两个字段 MUST 去重并剔除空字符串项。

字段缺失、为 `null`、为空 array 或去重后为空时 MUST NOT 输出对应字段。

取值不是 array 时 MUST 中断渲染。

列表项不符合标签键语法时 MUST 中断渲染。

#### Scenario: 合法的键列表

- **WHEN** `matchLabelKeys` 为 `["app", "app.kubernetes.io/name", "app"]`
- **THEN** 输出 `matchLabelKeys` 且去重后为 `["app", "app.kubernetes.io/name"]`

#### Scenario: 键列表为空

- **WHEN** `matchLabelKeys` 或 `mismatchLabelKeys` 为 `[]`、`null` 或只含空字符串
- **THEN** 输出不包含对应字段

#### Scenario: 键列表不是 array

- **WHEN** `matchLabelKeys` 为字符串或 map
- **THEN** 渲染中断并返回错误

#### Scenario: 键语法非法

- **WHEN** `matchLabelKeys` 含 `-app` 或 `a/b/c`
- **THEN** 渲染中断并返回错误

### Requirement: 渲染 namespaces

系统 MUST 把 `namespaces` 输出为 string array。

系统 MUST 按 `,` 或空白分隔拆分每项，例如 `aaa bbb` 拆分为 `aaa` 与 `bbb`。

拆分后每项 MUST 满足 Kubernetes 命名空间名语法（RFC1123）。

拆分结果 MUST 去重并剔除空项。

字段缺失、为 `null`、为空 array 或清洗后为空时 MUST NOT 输出该字段。

取值不是 array 时 MUST 中断渲染。

拆分后任一项不符合命名空间名语法时 MUST 中断渲染。

#### Scenario: 空格分隔的多值项

- **WHEN** `namespaces` 为 `["aaa bbb", "c"]`
- **THEN** 输出 `namespaces` 且内容为 `["aaa", "bbb", "c"]`

#### Scenario: 逗号分隔与重复项

- **WHEN** `namespaces` 为 `["a,b", "a", " b "]`
- **THEN** 输出 `namespaces` 且内容为 `["a", "b"]`

#### Scenario: 空列表被跳过

- **WHEN** `namespaces` 为 `[]`、`null` 或只含空白项
- **THEN** 输出不包含该字段

#### Scenario: 命名空间名非法

- **WHEN** `namespaces` 含 `Bad_Name` 或 `-bad`
- **THEN** 渲染中断并返回错误

## 非目标

- 不创建共享的标签选择器渲染能力。
- 不处理 `labelSelector`、`namespaceSelector` 内部的 `matchExpressions`、`matchLabels` 及其字符串简写。
- 不实现自建去重、去空算法。
- 不校验 `matchLabelKeys`、`mismatchLabelKeys` 与 `labelSelector` 之间的键冲突。
