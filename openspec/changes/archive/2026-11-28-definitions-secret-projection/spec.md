---
updated_at: "2026-11-28T09:59:07Z"
---

# definitions.secretProjection 规格

## Purpose

为 Kubernetes `SecretProjection` 提供共享结构渲染能力，供 `definitions.volumeProjection` 等上层模板复用。

## ADDED Requirements

### Requirement: SecretProjection 字段渲染

系统 MUST 按 Kubernetes `SecretProjection` 官方字段顺序渲染原生 map 输入，只读取 `items`、`name`、`optional`，其他字段静默忽略。

#### Scenario: 仅提供 name

- **WHEN** 输入为 `{name: "app-secret"}`
- **THEN** 输出仅包含 `name: "app-secret"`

#### Scenario: 完整字段按官方顺序渲染

- **WHEN** 输入同时包含合法的 `items`、`name` 和显式 `optional: false`
- **THEN** 输出依次为 `items`、`name`、`optional`，且 `optional` 保持 `false`

#### Scenario: name 缺失或为空

- **WHEN** `name` 缺失、为 null、空字符串或仅空白字符串
- **THEN** 中断渲染并报告 `name` 为必填字段

#### Scenario: name 非法

- **WHEN** `name` 不是合法的 RFC1123 Subdomain
- **THEN** 中断渲染并报告名称非法

#### Scenario: optional 为空

- **WHEN** `optional` 缺失、为 null、空字符串或仅空白字符串
- **THEN** 不输出 `optional`

#### Scenario: optional 非法

- **WHEN** `optional` 不是 boolean 或字面量 `"true"`、`"false"`
- **THEN** 中断渲染

### Requirement: SecretProjection items 委托与去重

系统 MUST 将 `items` 逐项委托给 `definitions.keyToPath` 渲染，并对渲染结果去重、去空后按 KeyToPath 数组输出。

#### Scenario: items 去重去空

- **WHEN** `items` 中存在渲染结果完全相同的条目，或渲染结果为空的条目
- **THEN** 重复条目只保留首个，空结果被剔除

#### Scenario: items 为空

- **WHEN** `items` 为空数组，或所有条目的渲染结果均为空
- **THEN** 不输出 `items`

#### Scenario: items 容器非法

- **WHEN** `items` 不是数组，或任一 `items` 条目不是对象
- **THEN** 中断渲染

#### Scenario: items 条目内容非法

- **WHEN** `items` 条目的 KeyToPath 字段不合法
- **THEN** 中断渲染并报告对应字段错误

## 非目标

- 不创建或修改 `definitions.keyToPath`。
- 不校验 `name` 指向的 Secret 是否存在。
- 不输出 `secret` 父键或 `VolumeProjection` 包装。
