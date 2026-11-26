---
updated_at: "2026-11-26T09:43:34Z"
---

# definitions.typedLocalObjectReference 规格

## Purpose

为 Kubernetes TypedLocalObjectReference 提供可复用的 YAML 字段片段渲染能力，供同命名空间内的类型化对象引用场景复用。

## ADDED Requirements

### Requirement: TypedLocalObjectReference 字段渲染

`definitions.typedLocalObjectReference` MUST 以原生 map 为上下文，按 `apiGroup`、`kind`、`name` 的官方字段顺序渲染 TypedLocalObjectReference 字段片段，忽略契约以外的字段，且不按输入 map 的键顺序输出。

#### Scenario: 完整引用

- **WHEN** 上下文包含非空 `apiGroup`、`kind` 与 `name`
- **THEN** 输出依次为 `apiGroup`、`kind`、`name`，各字段值保持输入内容且 YAML 解析后仍为字符串

#### Scenario: apiGroup 省略

- **WHEN** 上下文缺少 `apiGroup`，或其值为空字符串、仅空白或 `null`
- **THEN** 输出只包含 `kind` 与 `name`，不输出 `apiGroup`，也不补默认值

#### Scenario: apiGroup 任意值

- **WHEN** `apiGroup` 为非空字符串，包括第三方 API 组
- **THEN** 原样输出该值，不校验 API 组格式

#### Scenario: kind 或 name 缺失

- **WHEN** `kind` 或 `name` 缺失、为 `null` 或仅含空白
- **THEN** 渲染中断，失败消息以 `[definitions.typedLocalObjectReference]` 开头并指明具体字段

#### Scenario: 非法字段类型

- **WHEN** `apiGroup`、`kind` 或 `name` 不是字符串类型
- **THEN** 渲染中断

## 非目标

- 不校验 `apiGroup` 的格式或第三方 API 组的注册状态。
- 不实现 `definitions.typedObjectReference`、`definitions.volumeResourceRequirements` 等其他定义模板。
