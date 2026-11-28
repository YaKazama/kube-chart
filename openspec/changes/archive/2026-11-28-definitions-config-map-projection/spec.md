---
updated_at: "2026-11-28T09:06:36Z"
---

# definitions.configMapProjection 规格

## Purpose

为 `VolumeProjection.configMap` 提供 core/v1 `ConfigMapProjection` 的可复用渲染能力。

## ADDED Requirements

### Requirement: 渲染字段与顺序

系统 MUST 以原生 map 为上下文渲染 core/v1 `ConfigMapProjection` 的 YAML 字段片段，并按官方字段顺序 `items`、`name`、`optional` 输出已生效字段；未定义的输入字段 MUST 静默忽略。

#### Scenario: 最小有效输入

- **WHEN** 上下文为 `{name: "app-config"}`
- **THEN** 输出仅包含 `name: "app-config"`

#### Scenario: 较完整有效输入

- **WHEN** 上下文为 `{name: "app-config", items: [{key: "LOG_LEVEL", path: "app/config.conf"}], optional: false}`
- **THEN** 输出按 `items`、`name`、`optional` 的顺序排列

### Requirement: name 必填且为合法 ConfigMap 名称

系统 MUST 将 `name` 作为必填 string：缺失、为空或仅空白时中断；MUST 按 RFC1123 Subdomain 校验且最多 253 字符；生效的 `name` MUST 以带引号字符串输出。

#### Scenario: 缺失或空白 name

- **WHEN** `name` 缺失、为空或仅空白
- **THEN** 渲染中断并报告 `name` 必填

#### Scenario: 非法 name

- **WHEN** `name` 为 `app_config` 等不符合 RFC1123 Subdomain 的值
- **THEN** 渲染中断并报告名称格式错误

#### Scenario: 合法 name

- **WHEN** `name` 为 `app-config`
- **THEN** 输出 `name: "app-config"`

### Requirement: items 委托、去重与去空

系统 MUST 将 `items` 作为可选 KeyToPath array：每个条目 MUST 为原生 map，并逐项委托 `definitions.keyToPath` 渲染；子模板输出为空时 MUST 剔除该条目，完全相同的结果 MUST 只保留首个；空数组或全部结果被剔除时 MUST 省略 `items`；`items` 不是 array、条目不是 map、子模板输出非法 YAML 或子模板校验失败时 MUST 中断渲染。`items` 的 `path` 相对路径与 `..` 逃逸拒绝由 `definitions.keyToPath` 负责。

#### Scenario: 重复条目去重

- **WHEN** `items` 包含两个完全相同的 KeyToPath
- **THEN** 输出只包含一个对应的 `items` 条目

#### Scenario: 空数组

- **WHEN** `items` 为空数组
- **THEN** 输出不包含 `items`

#### Scenario: items 类型非法

- **WHEN** `items` 不是 array，或某个条目不是 map
- **THEN** 渲染中断并报告类型错误

#### Scenario: 子模板校验失败

- **WHEN** 某个条目的 `path` 为绝对路径或逃逸路径，或缺少数 `definitions.keyToPath` 要求的必填内容
- **THEN** 渲染中断并报告子模板校验错误

### Requirement: optional 布尔

系统 MUST 将 `optional` 作为可选 boolean：接受布尔值或字面量字符串 `"true"`、`"false"`；显式 `false` MUST 输出；缺失、空值或 null 时省略；其他类型或值 MUST 中断渲染。

#### Scenario: 显式 false

- **WHEN** `optional` 为 `false` 或字符串 `"false"`
- **THEN** 输出 `optional: false`

#### Scenario: 未提供 optional

- **WHEN** `optional` 缺失、为空或为 null
- **THEN** 输出不包含 `optional`

#### Scenario: 非法 optional

- **WHEN** `optional` 为 `"yes"` 等非布尔表示
- **THEN** 渲染中断并报告布尔类型错误

## 非目标

- 不创建或修改 `definitions.keyToPath`。
