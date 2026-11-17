---
updated_at: "2026-11-17T15:49:04Z"
---

# definitions.configMapKeySelector 规格

## Purpose

新增共享结构能力 `definitions.configMapKeySelector`，把单个 map 上下文渲染为 Kubernetes `ConfigMapKeySelector` 字段片段，供 `definitions.envVarSource` 的 `configMapKeyRef` 分支使用。

## ADDED Requirements

### Requirement: 字段渲染顺序与类型

系统 MUST 按官方字段顺序渲染 `ConfigMapKeySelector` 的 `key`、`name`、`optional` 三个字段。

- `key` MUST 以双引号字符串输出。
- `name` MUST 以双引号字符串输出。
- `optional` MUST 以布尔值输出，不加引号。
- 输入中除这三个字段之外的键静默忽略。

#### Scenario: 三字段齐全

- **WHEN** 输入为 `key: LOG_LEVEL`、`name: app-config`、`optional: true`
- **THEN** 输出依次为 `key: "LOG_LEVEL"`、`name: "app-config"`、`optional: true`

#### Scenario: 只提供必需字段

- **WHEN** 输入只有 `key` 与 `name`
- **THEN** 只输出这两个字段，不输出 `optional`

#### Scenario: 额外键忽略

- **WHEN** 输入含 `key`、`name` 与未定义键 `foo`
- **THEN** 输出不含 `foo`

### Requirement: 必填字段校验

系统 MUST 要求 `key` 与 `name` 均非空，并在不满足时中断渲染。

- `key` 缺失或为空白时中断，失败消息 MUST 包含 `key`。
- `name` 缺失或为空白时中断，失败消息 MUST 包含 `name`。

#### Scenario: key 缺失

- **WHEN** 输入只有 `name`
- **THEN** 渲染中断，失败消息包含 `key`

#### Scenario: name 缺失

- **WHEN** 输入只有 `key`
- **THEN** 渲染中断，失败消息包含 `name`

#### Scenario: name 为空白

- **WHEN** `name` 为只含空白的字符串
- **THEN** 渲染中断，失败消息包含 `name`

### Requirement: name 按 RFC1123 Subdomain 校验

系统 MUST 在 `name` 非空后按 RFC1123 Subdomain 规则校验，并复用共享的 RFC 校验能力完成该判断。

- 允许小写字母、数字、连字符与点分隔的多段；每段以字母或数字开头和结尾，长度不超过 63。
- 整体长度 MUST 不超过 253 字符。
- 不符合规则时中断渲染，失败消息 MUST 包含实际取值。

#### Scenario: 合法多段名称

- **WHEN** `name` 为 `app.config`
- **THEN** 渲染成功并输出该名称

#### Scenario: 含下划线

- **WHEN** `name` 为 `app_config`
- **THEN** 渲染中断，失败消息包含 `app_config`

#### Scenario: 超过 253 字符

- **WHEN** `name` 为 254 个合法字符组成的名称
- **THEN** 渲染中断，失败消息包含该取值

#### Scenario: 段首尾非法

- **WHEN** `name` 为 `-app` 或 `app-`
- **THEN** 渲染中断

### Requirement: RFC 校验能力新增 Subdomain 模式

系统 MUST 为共享 RFC 校验能力新增 RFC1123 Subdomain 模式，并将该模式用于 `name` 校验。

- 新模式 MUST 接受符合 RFC1123 Subdomain 且不超过 253 字符的取值。
- 新模式 MUST 拒绝不符合规则的取值，失败消息 MUST 包含实际取值。
- 既有 RFC1035 Label、RFC1123 Label 与 RBAC 三个模式的校验结果与失败消息 MUST 保持不变。

#### Scenario: 新模式接受 Subdomain

- **WHEN** 使用新模式校验 `app.config`
- **THEN** 校验通过

#### Scenario: 新模式拒绝 Label 不合规段

- **WHEN** 使用新模式校验 `-app`
- **THEN** 校验中断

#### Scenario: 既有模式行为不变

- **WHEN** 使用既有 RFC1035、RFC1123 或 RBAC 模式校验其原有合法与非法取值
- **THEN** 校验结果与失败消息均与变更前一致

### Requirement: optional 只接受原生布尔值

系统 MUST 只接受原生布尔值作为 `optional`。

- `optional` 为 `true` 或 `false` 时按布尔输出，`false` 也 MUST 输出。
- `optional` 为字符串（包括 `"true"`、`"false"`）时中断渲染，失败消息 MUST 包含 `optional`。
- `optional` 为其他类型时中断渲染。

#### Scenario: 显式 false

- **WHEN** `optional` 为原生 `false`
- **THEN** 输出 `optional: false`

#### Scenario: 字符串布尔值

- **WHEN** `optional` 为字符串 `"true"`
- **THEN** 渲染中断，失败消息包含 `optional`

#### Scenario: 数字

- **WHEN** `optional` 为数字 `1`
- **THEN** 渲染中断，失败消息包含 `optional`

### Requirement: 父级必需段数修正

系统 MUST 使 `definitions.envVarSource` 的 `configMapKeyRef` 字符串形态在少于两段时不再组装，以匹配 `key` 与 `name` 同时必填。

#### Scenario: 单段不再组装

- **WHEN** `definitions.envVarSource` 收到 `configMapKeyRef: "cfg"`
- **THEN** 不组装该字段，输出空内容

#### Scenario: 两段可组装

- **WHEN** `definitions.envVarSource` 收到 `configMapKeyRef: "cfg LOG_LEVEL"`
- **THEN** 组装为 `name: cfg`、`key: LOG_LEVEL` 并委托本能力

## 非目标

- 不渲染 `EnvVarSource` 的其他字段。
- 不实现 `definitions.envVarSource` 的分发逻辑。
- 不校验 `name` 指向的 ConfigMap 是否真实存在，也不校验 `key` 是否存在于该 ConfigMap。
- 不接受字符串形态的 `optional`；紧凑字符串写法产生的字符串值由调用方负责转换，本 change 不实现该转换。
