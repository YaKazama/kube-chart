---
updated_at: "2026-11-08T15:33:08Z"
---

# WeightedPodAffinityTerm 共享结构规格

## Purpose

为 Kubernetes `WeightedPodAffinityTerm` 对象提供共享结构渲染入口，把父级传入的 `weight` 与必填的 `podAffinityTerm` 渲染为可嵌入 `preferredDuringSchedulingIgnoredDuringExecution` 单个元素的字段片段。

## ADDED Requirements

### Requirement: 渲染 WeightedPodAffinityTerm 字段片段

系统 MUST 从入参 map 读取 `weight` 与 `podAffinityTerm`，并按 Kubernetes API 文档字段顺序输出 `podAffinityTerm` 先于 `weight`。

系统 MUST 输出可作为 `preferredDuringSchedulingIgnoredDuringExecution` 单个元素的 YAML 字段片段。

系统 MUST 识别 `weight`、`podAffinityTerm` 的同级 `<键名>Alias`；非空别名 MUST 优先于同名规范键，别名缺失或为空时 MUST 回退同名规范键。

入参中除 `weight`、`podAffinityTerm` 及其同级别名以外的字段 MUST 被忽略，MUST NOT 参与输出。

系统 MUST NOT 输出 `status` 或规格未定义的其他字段。

#### Scenario: weight 与 podAffinityTerm 同时提供

- **WHEN** 入参同时提供合法的 `weight` 与非空的 `podAffinityTerm`
- **THEN** 输出同时包含 `weight` 与 `podAffinityTerm` 两个字段，`podAffinityTerm` 在前

#### Scenario: 别名优先

- **WHEN** 入参同时提供 `weight` 与取值不同的 `weightAlias`
- **THEN** 输出使用 `weightAlias` 的取值

#### Scenario: 空别名回退

- **WHEN** 入参提供空的 `podAffinityTermAlias` 与非空的 `podAffinityTerm`
- **THEN** 输出使用 `podAffinityTerm` 的取值

#### Scenario: 未定义字段被忽略

- **WHEN** 入参除 `weight` 与 `podAffinityTerm` 外还包含其他键
- **THEN** 输出不包含这些键

### Requirement: 校验 weight

系统 MUST 要求 `weight` 存在且为 1 - 100 闭区间内的整数。

`weight` 缺失、为 `null` 或为空字符串时 MUST 中断渲染。

`weight` 取值无法作为整数识别时 MUST 中断渲染，包括非数字字符串、布尔值、map、list 以及带小数的浮点数。

`weight` 为小于 1 或大于 100 的整数时 MUST 中断渲染。

#### Scenario: weight 缺失

- **WHEN** 入参不含 `weight`
- **THEN** 渲染中断并返回错误

#### Scenario: weight 为空

- **WHEN** `weight` 为 `null` 或空字符串
- **THEN** 渲染中断并返回错误

#### Scenario: weight 非整数

- **WHEN** `weight` 为 `abc`、`true`、map、list 或 `1.5`
- **THEN** 渲染中断并返回错误

#### Scenario: weight 低于下限

- **WHEN** `weight` 为 `0` 或负数
- **THEN** 渲染中断并返回错误

#### Scenario: weight 高于上限

- **WHEN** `weight` 为 `101` 或更大的整数
- **THEN** 渲染中断并返回错误

#### Scenario: weight 为带引号的数字

- **WHEN** `weight` 为 `"11"`
- **THEN** 剥离引号后按整数接受，输出 `weight: 11`

#### Scenario: weight 取值合法

- **WHEN** `weight` 为 `1` 到 `100` 之间的整数，含边界值
- **THEN** 输出 `weight: <该整数>`

### Requirement: 校验 podAffinityTerm

系统 MUST 要求 `podAffinityTerm` 存在且为非空 map。

`podAffinityTerm` 缺失、为 `null` 或为空 map 时 MUST 中断渲染。

#### Scenario: podAffinityTerm 缺失

- **WHEN** 入参不含 `podAffinityTerm`
- **THEN** 渲染中断并返回错误

#### Scenario: podAffinityTerm 为空

- **WHEN** `podAffinityTerm` 为 `null` 或空 map
- **THEN** 渲染中断并返回错误

#### Scenario: podAffinityTerm 取值合法

- **WHEN** `podAffinityTerm` 为非空 map
- **THEN** 该 map 作为 `podAffinityTerm` 字段内容参与渲染

### Requirement: 委托 podAffinityTerm 到 PodAffinityTerm

系统 MUST 把 `podAffinityTerm` 的 map 原样作为上下文委托 `PodAffinityTerm` 结构渲染，并以该渲染结果作为输出的 `podAffinityTerm` 字段内容。

系统 MUST NOT 自行解析或改写 `podAffinityTerm` 内部的 `topologyKey`、`labelSelector`、`namespaceSelector`、`matchLabelKeys`、`namespaces` 等字段。

`podAffinityTerm` 取值不是 map 时 MUST 中断渲染。

委托结果无法恢复为 map 时 MUST 中断渲染。

#### Scenario: 原样委托

- **WHEN** `podAffinityTerm` 含 `topologyKey`、`labelSelector`、`namespaceSelector`、`matchLabelKeys`、`namespaces`
- **THEN** 这些字段原样传入 `PodAffinityTerm` 结构渲染，输出 `podAffinityTerm` 取自该渲染结果

#### Scenario: podAffinityTerm 不是 map

- **WHEN** `podAffinityTerm` 为字符串、数值或 list
- **THEN** 渲染中断并返回错误

#### Scenario: 委托结果非法

- **WHEN** `PodAffinityTerm` 结构渲染返回无法恢复为 map 的内容
- **THEN** 渲染中断并返回错误

## 非目标

- 不创建 `PodAffinityTerm` 结构渲染能力。
- 不处理 `podAffinityTerm` 内部字段的取值校验、解析与归一化。
- 不把扁平形态（术语字段与 `weight` 同级、不嵌套 `podAffinityTerm`）归一化为嵌套形态；该归一化不属于本能力。
- 不实现去重、去空。
