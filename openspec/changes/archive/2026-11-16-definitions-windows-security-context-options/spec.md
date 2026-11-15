---
updated_at: "2026-11-15T17:38:30Z"
---

# definitions.windowsSecurityContextOptions 规格

## Purpose

按 Kubernetes `WindowsSecurityContextOptions` 结构渲染 Windows 专用安全上下文字段片段，供 `securityContext` 与 `podSecurityContext` 复用。

## ADDED Requirements

### Requirement: WindowsSecurityContextOptions 字段片段渲染

系统 MUST 以单个 map 作为上下文，按 `gmsaCredentialSpec`、`gmsaCredentialSpecName`、`hostProcess`、`runAsUserName` 的固定顺序渲染 WindowsSecurityContextOptions 字段片段，并返回可解析为 map 的 YAML 内容。

全部字段可选。`gmsaCredentialSpec`、`gmsaCredentialSpecName`、`runAsUserName` 为字符串字段，`hostProcess` 为布尔字段并遵循下一条 Requirement。

#### Scenario: 渲染完整结构

- **WHEN** 上下文提供四个字段且 `hostProcess` 为 `true`
- **THEN** 输出按固定顺序包含四个字段，字符串字段为 YAML 字符串，`hostProcess` 为布尔值 `true`

#### Scenario: 仅提供部分字段

- **WHEN** 上下文只提供其中一部分字段
- **THEN** 输出只包含已提供的字段，且顺序仍为固定顺序

#### Scenario: 上下文缺省

- **WHEN** 上下文不包含任何受支持字段
- **THEN** 模板正常渲染并返回空内容

#### Scenario: 字符串字段去除首尾空白

- **WHEN** 字符串字段去除首尾空白后非空
- **THEN** 输出该去除首尾空白后的值，并保持 YAML 字符串类型，`on`、`yes`、`true` 等文本不被解析为布尔或数值

#### Scenario: 字符串字段为空值

- **WHEN** 字符串字段为 null、空字符串或仅含空白
- **THEN** 不输出该字段，且不中断渲染

#### Scenario: 字符串字段类型非法

- **WHEN** 字符串字段为 map、list、布尔或数值
- **THEN** 渲染中断

#### Scenario: 未知字段

- **WHEN** 上下文包含上述四个字段以外的键
- **THEN** 该键被忽略，不参与输出

### Requirement: hostProcess 布尔语义

系统 MUST 按 `base.bool` 的既有语义处理 `hostProcess`：接受原生布尔或字面量字符串 `"true"`、`"false"`，其他类型或非法字面量中断渲染；仅当值为 `true` 时输出该字段。

#### Scenario: 值为 true

- **WHEN** `hostProcess` 为原生布尔 `true` 或字面量字符串 `"true"`
- **THEN** 输出 `hostProcess` 字段，值为布尔 `true`

#### Scenario: 值为 false

- **WHEN** `hostProcess` 为原生布尔 `false` 或字面量字符串 `"false"`
- **THEN** 不输出 `hostProcess` 字段，且不中断渲染

#### Scenario: 值类型非法

- **WHEN** `hostProcess` 为 `"yes"`、数值、map 或 list
- **THEN** 渲染中断

## 非目标

- 本 change 不处理 Schema。
