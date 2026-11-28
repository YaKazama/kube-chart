---
updated_at: "2026-11-28T11:00:06Z"
---

# definitions.secretVolumeSource 规格

## Purpose

为 Kubernetes `SecretVolumeSource` 提供共享结构渲染能力，供 `definitions.volume` 的 `secret` 字段等上层模板复用。

## ADDED Requirements

### Requirement: SecretVolumeSource 字段渲染

系统 MUST 按 Kubernetes `SecretVolumeSource` 官方字段顺序渲染原生 map 输入，只读取 `defaultMode`、`items`、`optional`、`secretName`，其他字段静默忽略。

#### Scenario: 仅提供 secretName

- **WHEN** 输入为 `{secretName: "app-secret"}`
- **THEN** 输出仅包含 `secretName: "app-secret"`

#### Scenario: 完整字段按官方顺序渲染

- **WHEN** 输入同时包含合法的 `defaultMode`、`items`、`optional: false` 和 `secretName`
- **THEN** 输出依次为 `defaultMode`、`items`、`optional`、`secretName`

#### Scenario: defaultMode 为空

- **WHEN** `defaultMode` 缺失、为 null、空字符串或仅空白字符串
- **THEN** 不输出 `defaultMode`

#### Scenario: defaultMode 显式 0

- **WHEN** `defaultMode` 为 `0`
- **THEN** 输出 `defaultMode: 0`

#### Scenario: optional 为空

- **WHEN** `optional` 缺失、为 null、空字符串或仅空白字符串
- **THEN** 不输出 `optional`

#### Scenario: optional 非法

- **WHEN** `optional` 不是 boolean 或字面量 `"true"`、`"false"`
- **THEN** 中断渲染

#### Scenario: secretName 缺失或为空

- **WHEN** `secretName` 缺失、为 null、空字符串或仅空白字符串
- **THEN** 中断渲染并报告 `secretName` 为必填字段

#### Scenario: secretName 非法

- **WHEN** `secretName` 不是合法的 RFC1123 Subdomain
- **THEN** 中断渲染

### Requirement: items 解析、委托与去重

系统 MUST 接受 KeyToPath map 数组、string 数组或两者混合；string 元素按 `<key> <path> [mode]` 清洗为 KeyToPath map，逐项委托 `definitions.keyToPath`，并对渲染结果去重、去空后输出。

#### Scenario: string array 元素解析

- **WHEN** `items` 为 `["tls.crt tls.crt", "tls.key certs/tls.key 0400"]`
- **THEN** 每个字符串按 `<key> <path> [mode]` 清洗后委托 `definitions.keyToPath`，输出对应 KeyToPath 条目

#### Scenario: 混合数组

- **WHEN** `items` 同时包含 map 元素与 string 元素
- **THEN** string 元素先清洗为 KeyToPath map，map 元素原样委托，全部条目按顺序输出

#### Scenario: 去重去空

- **WHEN** `items` 中存在渲染结果完全相同的条目，或空白字符串、渲染结果为空的条目
- **THEN** 重复条目只保留首个，空白与空结果被剔除

#### Scenario: items 为空

- **WHEN** `items` 为空数组，或所有元素均为空白字符串
- **THEN** 不输出 `items`

#### Scenario: items 容器非法

- **WHEN** `items` 不是数组，或任一元素既不是对象也不是字符串
- **THEN** 中断渲染

#### Scenario: string 元素格式非法

- **WHEN** string 元素不符合 `<key> <path> [mode]`
- **THEN** 中断渲染

#### Scenario: KeyToPath 内容非法

- **WHEN** 条目清洗后的 KeyToPath 字段不合法
- **THEN** 中断渲染并报告对应字段错误

## 非目标

- 不创建或修改 `definitions.keyToPath`。
- 不调整 `definitions.volume` 的 `secret` 简写解析。
- 不校验 `secretName` 指向的 Secret 是否存在。
- 不输出 `secret` 父键或 `Volume` 包装。
