---
updated_at: "2026-11-26T15:55:07Z"
---

# 新增 definitions.imageVolumeSource 规格

## Purpose

为 Kubernetes `ImageVolumeSource` 提供可复用的字段渲染能力，并修正 `definitions.volume` 中 `image` 字符串简写的 `pullPolicy` 枚举匹配。

## ADDED Requirements

### Requirement: definitions.imageVolumeSource 字段渲染

系统 MUST 将上下文 map 渲染为 Kubernetes `ImageVolumeSource` 字段片段，并按官方顺序输出 `pullPolicy`、`reference`。

- `reference` MUST 为非空 string；缺失、空或非 string 时 MUST 中断。
- `pullPolicy` 可选；缺失或空值时 MUST 不输出。
- `pullPolicy` 非空时 MUST 为官方枚举值之一：`Always`、`IfNotPresent`、`Never`；MUST 按大小写敏感校验并原样输出；非法枚举或非 string 时 MUST 中断。
- 上下文未声明的键 MUST 静默忽略。

#### Scenario: 仅渲染 reference

- **WHEN** 上下文为 `{reference: "nginx:1.27"}`
- **THEN** 输出仅含 `reference: "nginx:1.27"`

#### Scenario: 渲染 pullPolicy 与 reference

- **WHEN** 上下文为 `{reference: "nginx:1.27", pullPolicy: "Always"}`
- **THEN** 输出按顺序包含 `pullPolicy: "Always"` 与 `reference: "nginx:1.27"`

#### Scenario: 空 pullPolicy 不渲染

- **WHEN** 上下文为 `{reference: "nginx:1.27", pullPolicy: ""}`
- **THEN** 输出仅含 `reference`，不含 `pullPolicy`

#### Scenario: reference 缺失或为空

- **WHEN** 上下文缺失 `reference` 或 `reference` 为空字符串
- **THEN** 渲染中断

#### Scenario: reference 不是 string

- **WHEN** 上下文为 `{reference: 1}`
- **THEN** 渲染中断

#### Scenario: pullPolicy 大小写不匹配

- **WHEN** 上下文为 `{reference: "nginx:1.27", pullPolicy: "always"}`
- **THEN** 渲染中断

#### Scenario: pullPolicy 不在枚举内

- **WHEN** 上下文为 `{reference: "nginx:1.27", pullPolicy: "Sometimes"}`
- **THEN** 渲染中断

#### Scenario: pullPolicy 不是 string

- **WHEN** 上下文为 `{reference: "nginx:1.27", pullPolicy: 1}`
- **THEN** 渲染中断

### Requirement: definitions.volume image 字符串简写

当 `definitions.volume` 的 `image` source 为 string 时，系统 MUST 按 `<reference> [pullPolicy]` 解析。

- `reference` MUST 为非空 token。
- `pullPolicy` 可选，MUST 以大小写不敏感方式匹配官方枚举值 `Always`、`IfNotPresent`、`Never`。
- 输入不符合上述范围时 MUST 以 `image: '<值>' does not match '<reference> [pullPolicy]'` 中断。
- 解析成功后 MUST 将 map 委托 `definitions.imageVolumeSource`：`reference` 为捕获值；`pullPolicy` 非空时 MUST 为对应官方枚举值，为空或未提供时 MUST 不下传。

#### Scenario: 仅 reference

- **WHEN** `image` 为 `nginx:1.27`
- **THEN** 输出 `image` 下仅含 `reference: nginx:1.27`

#### Scenario: pullPolicy 大小写不敏感并归一化

- **WHEN** `image` 为 `nginx:1.27 always`
- **THEN** 输出按顺序包含 `pullPolicy: Always` 与 `reference: nginx:1.27`

#### Scenario: pullPolicy 使用其他官方枚举

- **WHEN** `image` 为 `nginx:1.27 IfNotPresent`
- **THEN** 输出 `pullPolicy: IfNotPresent`

#### Scenario: pullPolicy 非法

- **WHEN** `image` 为 `nginx:1.27 Sometimes`
- **THEN** 渲染以 `does not match '<reference> [pullPolicy]'` 中断

#### Scenario: 空字符串

- **WHEN** `image` 为空字符串
- **THEN** 渲染以 `does not match '<reference> [pullPolicy]'` 中断
