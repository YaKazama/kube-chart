---
updated_at: "2026-11-18T14:37:40Z"
---

# definitions.secretEnvSource规格

## Purpose

为 Kubernetes `EnvFromSource.secretRef` 提供可嵌入的 `SecretEnvSource` 字段片段渲染能力。

## ADDED Requirements

### Requirement: SecretEnvSource 字段片段

系统 MUST 接受包含必填 `name` 与可选 `optional` 的 map，并输出仅含 `SecretEnvSource` 字段的 YAML 片段；字段顺序 MUST 为 `name`、`optional`，且不得包含 `secretRef` 父键或 `envFrom` 数组包装。

#### Scenario: 渲染完整字段片段

- **WHEN** 输入包含合法 `name` 和合法 `optional`
- **THEN** 输出依次包含带引号的 `name` 和 `optional` 字段，不包含父键或数组包装

#### Scenario: 仅渲染必填字段

- **WHEN** 输入只包含合法 `name`
- **THEN** 输出只包含带引号的 `name` 字段，不输出 `optional`

### Requirement: 名称归一与校验

系统 MUST 在取得 `name` 后移除首尾空白，并以移除后的值判断是否为空、按 Kubernetes RFC1123 Subdomain 规则校验且限制最多 253 个字符；空值、非字符串或不符合规则时 MUST 中断渲染。

#### Scenario: 归一后校验名称

- **WHEN** `name` 带有首尾空白但移除后合法
- **THEN** 输出移除首尾空白后的 `name`

#### Scenario: 拒绝空名称

- **WHEN** `name` 缺失、为显式 `null`、空字符串或仅空白字符串
- **THEN** 渲染中断

#### Scenario: 拒绝非法名称

- **WHEN** `name` 不是字符串、不符合 RFC1123 Subdomain 规则或超过 253 个字符
- **THEN** 渲染中断

### Requirement: optional 归一与省略

系统 MUST 在 `optional` 缺失、为显式 `null`、空字符串或仅空白字符串时省略该字段；其他输入 MUST 仅接受原生布尔值或字符串 `"true"`、`"false"` 并输出对应布尔标量，显式 `false` MUST 保留；其他值 MUST 中断渲染。

#### Scenario: 省略空 optional

- **WHEN** `optional` 缺失、为显式 `null`、空字符串或仅空白字符串
- **THEN** 输出不包含 `optional` 字段

#### Scenario: 保留有效 optional

- **WHEN** `optional` 为原生布尔值或字符串 `"true"`、`"false"`
- **THEN** 输出对应的布尔标量，且原生 `false` 或字符串 `"false"` 仍保留该字段

#### Scenario: 拒绝非法 optional

- **WHEN** `optional` 不是原生布尔值或字符串 `"true"`、`"false"`
- **THEN** 渲染中断

## 非目标

- 不输出 `secretRef` 父键或 `envFrom` 数组包装。
- 不校验被引用的 Secret 是否存在。
