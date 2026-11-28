---
updated_at: "2026-11-28T08:56:01Z"
---

# definitions.clusterTrustBundleProjection 规格

## Purpose

为 `VolumeProjection.clusterTrustBundle` 提供 core/v1 `ClusterTrustBundleProjection` 的可复用渲染能力。

## ADDED Requirements

### Requirement: 渲染字段与顺序

系统 MUST 以原生 map 为上下文渲染 core/v1 `ClusterTrustBundleProjection` 的 YAML 字段片段，并按官方字段顺序 `labelSelector`、`name`、`optional`、`path`、`signerName` 输出已生效字段；未定义的输入字段 MUST 静默忽略。

#### Scenario: 最小有效输入

- **WHEN** 上下文为 `{name: "trust-bundle", path: "ca.crt"}`
- **THEN** 输出仅包含 `name` 与 `path`，且 `name` 位于 `path` 之前

#### Scenario: 较完整有效输入

- **WHEN** 上下文为 `{signerName: "example.com/signer", labelSelector: {matchLabels: {app: "web"}}, optional: false, path: "ca.crt"}`
- **THEN** 输出按 `labelSelector`、`optional`、`path`、`signerName` 的顺序排列

### Requirement: name 与 signerName 二选一

系统 MUST 将 `name` 与 `signerName` 作为可选 string，并要求两者恰好一个非空；空白字符串按缺失处理；两者都缺失或都非空时 MUST 中断渲染并报告字段错误。生效的 `name` 与 `signerName` MUST 以带引号字符串输出。

#### Scenario: 仅提供 name

- **WHEN** 上下文为 `{name: "trust-bundle", path: "ca.crt"}`
- **THEN** 输出包含 `name: "trust-bundle"`

#### Scenario: 同时提供 name 与 signerName

- **WHEN** `name` 与 `signerName` 均为非空字符串
- **THEN** 渲染中断并报告两者互斥

#### Scenario: 两者都缺失

- **WHEN** `name` 缺失或为空白，且 `signerName` 缺失或为空白
- **THEN** 渲染中断并报告必须二选一

### Requirement: path 必填相对路径

系统 MUST 将 `path` 作为必填 string：缺失、为空或仅空白时中断；归一化 `.` 与 `..` 段后必须为相对路径，绝对路径中断；归一化结果为 `..` 或以 `../` 开头时中断。生效的 `path` MUST 以带引号字符串输出。

#### Scenario: 缺失 path

- **WHEN** 上下文未提供 `path`，或 `path` 为空白字符串
- **THEN** 渲染中断并报告 `path` 必填

#### Scenario: 绝对路径

- **WHEN** `path` 为 `/etc/ca.crt`
- **THEN** 渲染中断并报告必须为相对路径

#### Scenario: 逃逸路径

- **WHEN** `path` 归一化后为 `..` 或以 `../` 开头
- **THEN** 渲染中断并报告路径不得逃逸

#### Scenario: 归一化相对路径

- **WHEN** `path` 为 `certs/./ca.crt`
- **THEN** 输出 `path: "certs/ca.crt"`

### Requirement: labelSelector 委托与伴随约束

系统 MUST 将 `labelSelector` 作为可选 LabelSelector map。`labelSelector` 为空（缺失、null、空字符串或空 map）时 MUST 按未设置处理：不渲染，也不触发与 `signerName` 的伴随约束。非空 `labelSelector` MUST 为 map，并整体委托 `definitions.labelSelector` 渲染，其内部字段必填与格式校验由该模板负责，失败时中断渲染；非空 `labelSelector` 仅允许与 `signerName` 同时出现，`signerName` 缺失或为空时 MUST 中断。

#### Scenario: signerName 与非空 labelSelector 同时出现

- **WHEN** `signerName` 非空且 `labelSelector` 为非空合法 map
- **THEN** 输出 `labelSelector` 字段，内容由 `definitions.labelSelector` 决定

#### Scenario: 空 labelSelector 与 name 并存

- **WHEN** 上下文为 `{name: "trust-bundle", path: "ca.crt", labelSelector: {}}`
- **THEN** 输出不包含 `labelSelector`，且不中断渲染

#### Scenario: 空 labelSelector 与 signerName 并存

- **WHEN** 上下文为 `{signerName: "example.com/signer", path: "ca.crt", labelSelector: {}}`
- **THEN** 输出不包含 `labelSelector`，且不中断渲染

#### Scenario: 非空 labelSelector 缺少 signerName

- **WHEN** `labelSelector` 为非空 map，但 `signerName` 缺失或为空白
- **THEN** 渲染中断并报告 `labelSelector` 仅允许与 `signerName` 同时使用

#### Scenario: name 与非空 labelSelector 并存

- **WHEN** `name` 与非空 `labelSelector` 同时存在
- **THEN** 渲染中断

#### Scenario: labelSelector 类型非法

- **WHEN** 非空 `labelSelector` 不是 map
- **THEN** 渲染中断并报告类型错误

#### Scenario: 非空 labelSelector 内部校验失败

- **WHEN** 非空 `labelSelector` 缺少 `matchLabels` 等 `definitions.labelSelector` 要求的必填内容
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

- 不实现 `ClusterTrustBundleProjection` 之外的其他 VolumeProjection 子结构。
- 不改变既有 `VolumeProjection` 的字段选择与互斥行为。
