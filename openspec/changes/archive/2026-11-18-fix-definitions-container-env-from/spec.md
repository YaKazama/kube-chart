---
updated_at: "2026-11-18T04:44:36Z"
---

# definitions.container envFrom 输入规格

## MODIFIED Requirements

### Requirement: envFrom 数组元素归一化

系统 MUST 只接受 array 形态的 `envFrom` 数据，并把数组中的每个元素归一化为 map 后再交给 `definitions.envFromSource` 渲染。

`envFromFileRefs` 有有效结果时系统 MUST 继续使用该结果，并按与内联 `envFrom` 相同的规则归一化。

`envFrom` 缺失或为 `null` 时系统 MUST 视为未提供，不输出该字段且不失败。其他非 array 输入（单个 string、map 或其他标量）MUST 中断渲染并报错，错误信息 MUST 包含 `envFrom`。

元素为 map 时系统 MUST 原样向下传递；元素为 string 时系统 MUST 按字符串简写规则解析；元素既不是 map 也不是 string 时系统 MUST 中断渲染并报错。

同一数组 MUST 允许 string 与 map 元素混用，每个元素最终 MUST 以 map 形态向下传递。

#### Scenario: 原生 EnvFromSource 数组

- **WHEN** `envFrom` 为元素均为 map 的数组，例如 `[{configMapRef: "app-config"}]`
- **THEN** 每个 map 元素原样传给 `definitions.envFromSource`，`envFrom` 数组项内容与输入一致

#### Scenario: 字符串数组

- **WHEN** `envFrom` 为元素均为 string 的数组，例如 `["cm app-config /app", "secret db-secret"]`
- **THEN** 每个 string 元素被解析为 map 后传给 `definitions.envFromSource`

#### Scenario: 混合数组

- **WHEN** `envFrom` 同时包含 map 元素与 string 元素
- **THEN** map 元素原样传递、string 元素解析为 map，两者按输入顺序输出

#### Scenario: 非数组输入

- **WHEN** `envFrom` 为单个 string、map 或其他标量
- **THEN** 渲染中断，错误信息包含 `envFrom`

#### Scenario: 元素类型非法

- **WHEN** 数组元素既不是 map 也不是 string，例如数字或布尔
- **THEN** 渲染中断

#### Scenario: 未提供 envFrom

- **WHEN** `envFrom` 缺失或为 `null`
- **THEN** 不输出 `envFrom`，不失败

#### Scenario: envFromFileRefs 覆盖 envFrom

- **WHEN** 同时提供 `envFromFileRefs` 与 `envFrom`，且 `envFromFileRefs` 可读取到有效内容
- **THEN** 使用文件内容并按相同规则归一化，忽略 `envFrom`

### Requirement: envFrom 字符串简写解析

系统 MUST 把 string 元素解析为 `definitions.envFromSource` 所需的 map。

元素 MUST 先去除首尾空白，再按 `<configMap | cm | secret> <name> [prefix] [optional]` 格式匹配；分隔符 MUST 为一段或多段连续的空白或逗号，且 MUST NOT 作为段内容的一部分。

段数 MUST 为 2 至 4：少于 2 段或多于 4 段时系统 MUST 中断渲染并报错。不符合该格式的其他形态（例如尾随分隔符）MUST 中断渲染并报错。

第 1 段 MUST 为关键字，比较 MUST 不区分大小写：`configMap` 与 `cm` 映射为 `configMapRef`，`secret` 映射为 `secretRef`；关键字不在该映射表时系统 MUST 中断渲染并报错。

第 2 段 MUST 作为 `name`，第 3 段 MUST 作为 `prefix`，第 4 段 MUST 作为 `optional`；3 段输入的第三段 MUST 只作为 `prefix`，MUST NOT 参与 `optional` 判定。`optional` MUST 只在 4 段输入时出现；3 段输入的第三段取值为 `true` 或 `false` 时 MUST 仍按 `prefix` 输出。

解析结果 MUST 为 map，且 MUST 只包含一个 `configMapRef` 或 `secretRef` 键，二者 MUST 互斥。该键的值 MUST 为 string：提供 `optional` 时为 `<name> <optional>`，否则为 `<name>`。`prefix` MUST 可选，未提供时 MUST NOT 输出该键。

系统 MUST NOT 在本层校验 `name`、`prefix`、`optional` 的字符集、长度或布尔语义，MUST NOT 把 `optional` 归一化为布尔值；`optional` MUST 按原文 token 作为 string 向下传递。`name`、`prefix`、`optional` 中除分隔符外的字符 MUST 原样保留，且大小写敏感。

#### Scenario: configMap 关键字

- **WHEN** 元素为 `configMap app-config`
- **THEN** 解析结果为 `{configMapRef: "app-config"}`，不含 `prefix`

#### Scenario: cm 简写

- **WHEN** 元素为 `cm app-config`
- **THEN** 解析结果为 `{configMapRef: "app-config"}`

#### Scenario: secret 关键字

- **WHEN** 元素为 `secret db-secret`
- **THEN** 解析结果为 `{secretRef: "db-secret"}`

#### Scenario: 关键字大小写不敏感

- **WHEN** 元素为 `CM app-config`、`ConfigMap app-config` 或 `SECRET db-secret`
- **THEN** 分别解析为 `{configMapRef: ...}`、`{configMapRef: ...}`、`{secretRef: ...}`

#### Scenario: 引用键互斥

- **WHEN** 任一元素解析成功
- **THEN** 结果 map 只包含 `configMapRef` 或 `secretRef` 中的一个键

#### Scenario: 三段输入按 prefix 解析

- **WHEN** 元素为 `cm app-config /app`
- **THEN** 解析结果为 `{configMapRef: "app-config", prefix: "/app"}`，不产生 `optional` 键

#### Scenario: 三段的布尔词仍按 prefix 解析

- **WHEN** 元素为 `cm app-config true` 或 `cm app-config false`
- **THEN** 解析结果分别为 `{configMapRef: "app-config", prefix: "true"}` 与 `{configMapRef: "app-config", prefix: "false"}`，不产生 `optional` 键

#### Scenario: 四段输入

- **WHEN** 元素为 `secret db-secret /db true`
- **THEN** 解析结果为 `{secretRef: "db-secret true", prefix: "/db"}`

#### Scenario: optional 原样传递

- **WHEN** 元素为 `cm app-config /app notabool`
- **THEN** 本层不中断渲染，引用值为 `app-config notabool`

#### Scenario: name 大小写与字符集保留

- **WHEN** 元素为 `cm App_Config`
- **THEN** 本层不中断渲染，引用值为 `App_Config`

#### Scenario: 分隔符混用

- **WHEN** 元素为 `cm,app-config,/app` 或 `cm   app-config ,  /app`
- **THEN** 均解析为 `{configMapRef: "app-config", prefix: "/app"}`

#### Scenario: 首尾空白

- **WHEN** 元素为 `  cm app-config  `
- **THEN** 解析结果为 `{configMapRef: "app-config"}`

#### Scenario: 段数不足

- **WHEN** 元素为 `cm`、`app-config` 或空字符串
- **THEN** 渲染中断并报错

#### Scenario: 段数超限

- **WHEN** 元素为 `cm app-config /app true extra`
- **THEN** 渲染中断并报错

#### Scenario: 未知关键字

- **WHEN** 元素为 `env app-config`、`config app-config` 或 `secretKey db-secret`
- **THEN** 渲染中断并报错

## 非目标

- 不改变 `env` 或容器其他字段的解析行为。
- 不实现也不修改 `definitions.envFromSource` 及其子模板，其字段拆分与 `optional` 布尔校验不在本 change 范围。
- 不校验 `name`、`prefix`、`optional` 的字符集、长度或布尔语义，该职责由下游子模板承担。
- 不为 `envFrom` 增加 array 之外的简写形态，也不支持容器级单个 string。
- 不变更 `*FileRefs` 的路径校验、读取语义与优先级顺序。
- 不校验 map 元素内部字段的形态与合法性。
