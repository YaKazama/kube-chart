---
updated_at: "2026-11-08T07:39:55Z"
---

# PreferredSchedulingTerm 共享结构规格

## Purpose

为 Kubernetes `PreferredSchedulingTerm` 对象提供共享结构渲染入口，把父级传入的单项 `weight` 与可选的 `preference` 渲染为可嵌入 `preferredDuringSchedulingIgnoredDuringExecution` 单个元素的字段片段。

## ADDED Requirements

### Requirement: 渲染 PreferredSchedulingTerm 字段片段

系统 MUST 从入参 map 读取 `weight` 与可选的 `preference`，并按 Kubernetes API 字段顺序输出 `weight` 先于 `preference`。

系统 MUST 输出可作为 `preferredDuringSchedulingIgnoredDuringExecution` 单个元素的 YAML 字段片段。

系统 MUST 识别 `weight`、`preference` 的同级 `<键名>Alias`；非空别名 MUST 优先于同名规范键，别名缺失或为空时 MUST 回退同名规范键。

入参中除 `weight`、`preference` 及其同级别名以外的字段 MUST 被忽略，MUST NOT 参与输出。

系统 MUST NOT 输出 `status` 或规格未定义的其他字段。

#### Scenario: weight 与 preference 同时提供

- **WHEN** 入参同时提供合法的 `weight` 与非空的 `preference`
- **THEN** 输出同时包含 `weight` 与 `preference` 两个字段，`weight` 在前

#### Scenario: 只提供 weight

- **WHEN** 入参只提供合法的 `weight`
- **THEN** 输出只包含 `weight`，不输出 `preference`

#### Scenario: preference 为空

- **WHEN** `preference` 缺失、为空 map，或子模板未返回有效内容
- **THEN** 输出只包含 `weight`，不输出 `preference`

#### Scenario: 别名优先

- **WHEN** 入参同时提供 `weight` 与取值不同的 `weightAlias`
- **THEN** 输出使用 `weightAlias` 的取值

#### Scenario: 空别名回退

- **WHEN** 入参提供空的 `preferenceAlias` 与非空的 `preference`
- **THEN** 输出使用 `preference` 的取值

#### Scenario: 未定义字段被忽略

- **WHEN** 入参除 `weight` 与 `preference` 外还包含其他键
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

#### Scenario: weight 取值合法

- **WHEN** `weight` 为 `1` 到 `100` 之间的整数，含边界值
- **THEN** 输出 `weight: <该整数>`

### Requirement: 委托 preference 到 NodeSelectorTerm

系统 MUST 把 `preference` 原样作为上下文委托 `definitions.nodeSelectorTerm`，并以该模板返回的 map 作为 `preference` 字段内容。

系统 MUST NOT 自行解析 `preference` 内部的 `matchExpressions`、`matchFields` 或其中的字符串简写。

`preference` 取值不是 map 时 MUST 中断渲染。

子模板返回内容无法恢复为 map 时 MUST 中断渲染。

#### Scenario: 原样委托

- **WHEN** `preference` 含 `matchExpressions` 与 `matchFields`
- **THEN** 两者内容原样传入 `definitions.nodeSelectorTerm`，输出 `preference` 取自该模板返回值

#### Scenario: preference 不是 map

- **WHEN** `preference` 为字符串、布尔值或 list
- **THEN** 渲染中断并返回错误

#### Scenario: 子模板返回非 map

- **WHEN** `definitions.nodeSelectorTerm` 的返回值无法恢复为 map
- **THEN** 渲染中断并返回错误

## 非目标

- 不创建或修改 `definitions.nodeSelectorTerm`。
- 不解析 `preference` 内部的 `matchExpressions`、`matchFields` 简写或 `NodeSelectorRequirement` 结构。
- 不负责 `preferredDuringSchedulingIgnoredDuringExecution` 数组的取值、项数、顺序与去重。
- 不输出 `status` 或其他规格未定义字段。
