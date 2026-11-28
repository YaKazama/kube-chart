---
updated_at: "2026-11-28T09:47:31Z"
---

# definitions.podCertificateProjection 规格

## Purpose

为 `VolumeProjection.podCertificate` 提供 core/v1 `PodCertificateProjection` 的可复用渲染能力。

## ADDED Requirements

### Requirement: 渲染字段与顺序

系统 MUST 以原生 map 为上下文，按官方字段顺序 `certificateChainPath`、`credentialBundlePath`、`keyPath`、`keyType`、`maxExpirationSeconds`、`signerName`、`userAnnotations` 输出已生效字段；未定义的输入字段 MUST 静默忽略；任一字段类型非法时 MUST 中断渲染。

#### Scenario: 最小有效输入

- **WHEN** 上下文为 `{signerName: "example.com/signer", keyType: "RSA3072", credentialBundlePath: "credential-bundle.pem"}`
- **THEN** 输出按 `credentialBundlePath`、`keyType`、`signerName` 的顺序排列

#### Scenario: 两种文件布局同时配置

- **WHEN** 上下文同时包含 `credentialBundlePath`、`keyPath` 与 `certificateChainPath`
- **THEN** 输出按 `certificateChainPath`、`credentialBundlePath`、`keyPath` 的官方顺序排列

#### Scenario: 字段类型非法

- **WHEN** `keyType` 为数值、`signerName` 为 map、路径字段为布尔、`maxExpirationSeconds` 为非整数或 `userAnnotations` 非 map
- **THEN** 渲染中断并报告类型错误

### Requirement: signerName 与 keyType 必填

系统 MUST 将 `signerName` 与 `keyType` 作为必填 string；缺失、为空或仅空白时中断。`keyType` MUST 只允许 `RSA3072`、`RSA4096`、`ECDSAP256`、`ECDSAP384`、`ECDSAP521`、`ED25519`，其他值 MUST 中断渲染。

#### Scenario: 缺失必填字段

- **WHEN** `signerName` 或 `keyType` 缺失、为空或仅空白
- **THEN** 渲染中断并报告字段必填

#### Scenario: 非法 keyType

- **WHEN** `keyType` 为 `RSA2048` 等不在枚举范围的值
- **THEN** 渲染中断并报告合法枚举范围

### Requirement: 文件布局与相对路径

系统 MUST 将 `certificateChainPath`、`credentialBundlePath`、`keyPath` 作为可选 string；配置时 MUST 为相对路径。`keyPath` 与 `certificateChainPath` MUST 同时出现或同时缺失；文件布局 MUST 至少配置 `credentialBundlePath` 单文件方式或 `keyPath` + `certificateChainPath` 双文件方式之一，两种方式可以同时配置。

#### Scenario: 仅配置单文件方式

- **WHEN** 仅提供 `credentialBundlePath`，未提供 `keyPath` 与 `certificateChainPath`
- **THEN** 渲染正常，输出包含 `credentialBundlePath`

#### Scenario: 仅配置双文件方式

- **WHEN** 同时提供 `keyPath` 与 `certificateChainPath`，未提供 `credentialBundlePath`
- **THEN** 渲染正常，输出包含两个路径字段

#### Scenario: 双文件字段不成对

- **WHEN** 只提供 `keyPath` 与 `certificateChainPath` 中的一个
- **THEN** 渲染中断并报告两者必须成对出现

#### Scenario: 未配置任何文件布局

- **WHEN** 三个路径字段都缺失或为空
- **THEN** 渲染中断并报告至少需要一种文件布局

#### Scenario: 绝对路径

- **WHEN** 任一路径字段为绝对路径
- **THEN** 渲染中断并报告必须为相对路径

### Requirement: maxExpirationSeconds 范围

系统 MUST 将 `maxExpirationSeconds` 作为可选整数秒；提供时 MUST 位于 3600–7862400 闭区间，越界或非整数时中断；缺失、空值或 null 时省略，由 API 使用默认值 86400 秒。

#### Scenario: 边界值

- **WHEN** `maxExpirationSeconds` 为 `3600` 或 `7862400`
- **THEN** 输出对应整数值

#### Scenario: 越界值

- **WHEN** `maxExpirationSeconds` 小于 `3600` 或大于 `7862400`
- **THEN** 渲染中断并报告允许范围

#### Scenario: 未提供 maxExpirationSeconds

- **WHEN** `maxExpirationSeconds` 缺失、为空或为 null
- **THEN** 输出不包含 `maxExpirationSeconds`

### Requirement: userAnnotations 键校验

系统 MUST 将 `userAnnotations` 作为可选 map，键与值均为 string；键 MUST 为带 DNS 子域前缀的限定名 `<prefix>/<name>`，prefix 最多 253 字符且符合 DNS 子域语法，name 符合注解键名称语法；键在校验与输出前 MUST 去除首尾空白；值只校验 string 类型，不校验内容。键不符合限定名、缺少域名前缀或值不是 string 时 MUST 中断渲染。

#### Scenario: 合法 userAnnotations

- **WHEN** `userAnnotations` 为 `{"example.com/team": "platform"}`
- **THEN** 输出包含对应注解键值

#### Scenario: 键缺少域名前缀

- **WHEN** 键为 `team` 等不含 `/` 前缀的值
- **THEN** 渲染中断并报告必须为域名前缀限定名

#### Scenario: 键语法非法

- **WHEN** prefix 不是合法 DNS 子域，或 name 不符合注解键名称语法
- **THEN** 渲染中断并报告键格式错误

#### Scenario: 值类型非法

- **WHEN** 任一注解值不是 string
- **THEN** 渲染中断并报告类型错误

## 非目标

- 不校验 `userAnnotations` 值的业务含义或整体大小。
