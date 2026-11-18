---
updated_at: "2026-11-18T14:24:25Z"
---

# definitions.configMapEnvSource 规格

## Purpose

定义库模板 `definitions.configMapEnvSource`，将输入 map 中的 `name` 与可选 `optional` 渲染为 Kubernetes `ConfigMapEnvSource` YAML 字段片段。

## ADDED Requirements

### Requirement: ConfigMapEnvSource 片段

系统 MUST 接受包含 `name` 与可选 `optional` 的 map，并输出仅含这两个字段的 YAML 字段片段；字段顺序 MUST 为 `name`、`optional`。

#### Scenario: 仅提供 name

- **WHEN** 调用方传入 `name: app-config`
- **THEN** 输出包含值为 `app-config` 的 `name` 字段，且不包含 `optional` 字段

#### Scenario: 提供显式 false

- **WHEN** 调用方传入 `name: app-config` 与 `optional: false`
- **THEN** 输出中 `name` 字段先于 `optional` 字段，且 `optional` 值为 `false`

### Requirement: name 归一与校验

系统 MUST 将 `name` 作为必填字符串，在取值后移除首尾空白；去除后 MUST 非空并符合 RFC1123 Subdomain，最多 253 字符。去除空白后为空、不是字符串或不符合名称规则时 MUST 中断渲染。

#### Scenario: 移除首尾空白

- **WHEN** `name` 为 `"  app-config  "`
- **THEN** 输出 `name` 值为 `app-config`

#### Scenario: 缺少 name

- **WHEN** 调用方未提供 `name`、传入 `null`，或 `name` 去除空白后为空字符串
- **THEN** 渲染中断，且不输出字段片段

#### Scenario: name 非法

- **WHEN** `name` 不是字符串，或不符合 RFC1123 Subdomain，或超过 253 字符
- **THEN** 渲染中断

### Requirement: optional 渲染与省略

系统 MUST 将缺失、显式 `null`、空字符串或仅空白字符串的 `optional` 视为未提供并省略该字段。非空 `optional` MUST 只接受原生布尔值或字符串 `"true"`、`"false"`，并渲染对应布尔值；显式 `false` MUST 保留。其他值 MUST 中断渲染。

#### Scenario: 空值省略

- **WHEN** `optional` 为 `null`、空字符串或仅空白字符串
- **THEN** 输出不包含 `optional` 字段

#### Scenario: 字符串布尔值

- **WHEN** `optional` 为字符串 `"true"` 或 `"false"`
- **THEN** 输出对应值的 `optional` 布尔字段

#### Scenario: optional 非法

- **WHEN** `optional` 是非空且不是原生布尔值、字符串 `"true"` 或字符串 `"false"` 的值
- **THEN** 渲染中断

## 非目标

- 只输出 `name`、`optional` 字段片段，不包含 `configMapRef` 父键与 `envFrom` 数组包装。
- 不校验被引用的 ConfigMap 是否存在。
