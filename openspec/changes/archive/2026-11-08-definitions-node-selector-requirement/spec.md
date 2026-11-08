---
updated_at: "2026-11-08T14:00:26Z"
---

# definitions.nodeSelectorRequirement 模板规格

## Purpose

提供 Kubernetes `NodeSelectorRequirement` 字段片段的统一渲染入口，供 `NodeSelectorTerm` 的 `matchExpressions` 与 `matchFields` 条目复用。

## ADDED Requirements

### Requirement: NodeSelectorRequirement 字段片段渲染

系统 MUST 把父级清洗后的 map 渲染为 `NodeSelectorRequirement` 字段片段，按 API 字段顺序输出 `key`、`operator`、`values`；`operator` 为 `In`、`NotIn`、`Gt`、`Lt` 时 MUST 输出 `values`，为 `Exists`、`DoesNotExist` 时 MUST NOT 输出 `values`，该差异 MUST 由 `operator` 分支显式决定，不得依赖 `values` 为空时的省略行为；入参为空 map 时 MUST 返回空字符串且不报错；`keyAlias`、`operatorAlias`、`valuesAlias` 非空时 MUST 优先于对应规范键生效。

#### Scenario: 渲染集合型要求

- **WHEN** 以 `key` 为 `kubernetes.io/os`、`operator` 为 `In`、`values` 为 `["linux"]` 调用
- **THEN** 输出依次包含 `key`、`operator`、`values` 三个字段，且 `values` 为单元素数组

#### Scenario: 渲染存在型要求

- **WHEN** 以 `key` 为 `kubernetes.io/os`、`operator` 为 `Exists` 调用
- **THEN** 只输出 `key` 与 `operator`，且 `values` 的缺席由 `operator` 分支显式决定而不是空值省略

#### Scenario: 六种 operator 均可渲染

- **WHEN** `operator` 分别为 `DoesNotExist`、`Exists`、`Gt`、`In`、`Lt`、`NotIn`，且 `values` 与该 operator 一致
- **THEN** 每次调用都输出包含对应 `operator` 值的字段片段，且 `DoesNotExist`、`Exists` 的输出不含 `values`

#### Scenario: values 元素转为字符串

- **WHEN** `operator` 为 `Gt`、`values` 为 `[5]`
- **THEN** 输出的 `values` 元素为字符串 `5`

#### Scenario: values 保持原顺序且不去重

- **WHEN** `operator` 为 `In`、`values` 为 `["a", "a", "b"]`
- **THEN** 输出的 `values` 按 `a`、`a`、`b` 顺序包含三个元素

#### Scenario: 空 map 不渲染

- **WHEN** 入参为空 map
- **THEN** 返回空字符串，不产生字段输出，也不返回错误

#### Scenario: 别名优先于规范键

- **WHEN** 同时给出 `key`、`operator` 与值为空字符串的 `keyAlias`
- **THEN** 使用 `key`，输出不受空别名影响

#### Scenario: 非空别名覆盖规范键

- **WHEN** 同时给出 `key` 为 `a` 与 `keyAlias` 为 `b`，且 `operator` 为 `Exists`
- **THEN** 输出的 `key` 为 `b`

### Requirement: NodeSelectorRequirement 输入校验

系统 MUST 在 `key`、`operator` 或 `values` 不满足本能力契约时中断渲染并返回错误；本模板主动产生的失败消息 MUST 使用 `[definitions.nodeSelectorRequirement]` 前缀并携带字段名；委托其他能力完成的校验 MUST 保留其自身前缀：`key`、`operator` 的必填与别名取值保留 `[base.get]` 前缀并携带字段路径，`operator` 枚举校验保留 `[base.field]` 前缀并输出合法枚举范围；`operator` 枚举校验 MUST 大小写敏感。

#### Scenario: key 缺失或为空

- **WHEN** 入参非空但缺少 `key`，或 `key` 为空字符串
- **THEN** 渲染中断并返回错误，错误消息包含 `[base.get]` 前缀与 `key` 字段路径

#### Scenario: key 类型非法

- **WHEN** `key` 不是 string 类型
- **THEN** 渲染中断并返回错误，错误消息包含 `[definitions.nodeSelectorRequirement]` 前缀与 `key` 字段名

#### Scenario: operator 缺失

- **WHEN** 入参非空但缺少 `operator`，或 `operator` 为空字符串
- **THEN** 渲染中断并返回错误，错误消息包含 `[base.get]` 前缀与 `operator` 字段路径

#### Scenario: operator 不在枚举内

- **WHEN** `operator` 为 `Foo`，或以非规范大小写给出如 `in`
- **THEN** 渲染中断并返回错误，错误消息包含 `[base.field]` 前缀与六个合法枚举值

#### Scenario: key 或 operator 只含空白字符

- **WHEN** `key` 或 `operator` 只包含空白字符
- **THEN** 渲染中断并返回错误，错误消息包含 `[definitions.nodeSelectorRequirement]` 前缀与对应字段名

#### Scenario: In 或 NotIn 缺少 values

- **WHEN** `operator` 为 `In` 或 `NotIn`，且 `values` 缺失、为 `null` 或为空数组
- **THEN** 渲染中断并返回错误，错误消息包含 `[definitions.nodeSelectorRequirement]` 前缀与 `values` 字段名

#### Scenario: Exists 或 DoesNotExist 携带 values

- **WHEN** `operator` 为 `Exists` 或 `DoesNotExist`，且 `values` 非空
- **THEN** 渲染中断并返回错误，错误消息包含 `[definitions.nodeSelectorRequirement]` 前缀与 `values` 字段名

#### Scenario: Gt 或 Lt 的 values 数量非法

- **WHEN** `operator` 为 `Gt` 或 `Lt`，且 `values` 元素数量不是恰好一个
- **THEN** 渲染中断并返回错误，错误消息包含 `[definitions.nodeSelectorRequirement]` 前缀与 `values` 字段名

#### Scenario: Gt 或 Lt 的 values 不是整数

- **WHEN** `operator` 为 `Gt` 或 `Lt`，`values` 恰好一个元素但不是整数
- **THEN** 渲染中断并返回错误，错误消息包含 `[definitions.nodeSelectorRequirement]` 前缀与 `values` 字段名

#### Scenario: values 不是数组

- **WHEN** `values` 存在且不是数组类型
- **THEN** 渲染中断并返回错误，错误消息包含 `[definitions.nodeSelectorRequirement]` 前缀与 `values` 字段名

## 非目标

- 不解析 string 简写条目、不对条目去重。
- 不拆分、去空、去重或规范化 `values`。
- 不校验标签键语法。
- 不输出 `status` 或其他 `NodeSelectorTerm` 字段。
