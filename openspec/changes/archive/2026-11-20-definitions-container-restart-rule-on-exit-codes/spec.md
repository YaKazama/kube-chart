---
updated_at: "2026-11-19T17:52:50Z"
---

# definitions.containerRestartRuleOnExitCodes 规格

## Purpose

为 Kubernetes `ContainerRestartRuleOnExitCodes` 提供可复用的 YAML 字段片段渲染，集中完成退出码匹配规则的字段校验、枚举归一化与输出。

## ADDED Requirements

### Requirement: 退出码匹配规则字段片段渲染

系统 MUST 将 map 上下文中的 `operator` 与 `values` 渲染为 `ContainerRestartRuleOnExitCodes` YAML 字段片段。`operator` MUST 为 string，并按大小写不敏感的 `In` / `NotIn` 枚举校验后以官方值输出；`values` MUST 为包含 1 至 255 个整数元素的 integer array，显式整数 `0` MUST 保留，元素 MUST 以整数类型保留其取值。任一字段缺失、类型非法、枚举非法、数组为空、元素数量超过 255 或元素不是整数时，系统 MUST 中断渲染。

#### Scenario: 上下文不是 map

- **WHEN** 上下文不是 map
- **THEN** 渲染中断

#### Scenario: 合法规则输出

- **WHEN** 上下文为 `operator: In`、`values: [0, 1]` 的 map
- **THEN** 输出包含 `operator: "In"` 与保留 `0`、`1` 的 `values` 数组

#### Scenario: operator 大小写不敏感归一化

- **WHEN** `operator` 为 `in`、`IN`、`notin` 或 `NoTiN` 等 `In` / `NotIn` 的大小写变体
- **THEN** 输出分别归一化为官方值 `In` 或 `NotIn`

#### Scenario: operator 缺失或类型非法

- **WHEN** `operator` 缺失、为 null、为空字符串，或为 bool、数值、map、array 等非 string 类型
- **THEN** 渲染中断

#### Scenario: operator 枚举非法

- **WHEN** `operator` 不是 `In` / `NotIn` 的大小写变体
- **THEN** 渲染中断

#### Scenario: values 缺失或类型非法

- **WHEN** `values` 缺失、为 null，或为 string、数值、map 等非 array 类型
- **THEN** 渲染中断

#### Scenario: values 为空数组

- **WHEN** `values` 为空数组
- **THEN** 渲染中断

#### Scenario: values 数量边界

- **WHEN** `values` 包含 1 个或 255 个整数元素
- **THEN** 正常渲染全部元素

#### Scenario: values 数量超过上限

- **WHEN** `values` 包含 256 个或更多整数元素
- **THEN** 渲染中断

#### Scenario: values 包含非整数元素

- **WHEN** `values` 包含 string、bool、map、array、null 或非整数数值元素
- **THEN** 渲染中断

## 非目标

- 不渲染 `exitCodes`、`action`、`restartPolicyRules` 等父级键，也不处理 `definitions.containerRestartRule` 的 string 简写。
- 不为 `operator` 或 `values` 提供默认值，不定义这两个字段之外的输出。
