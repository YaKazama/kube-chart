---
updated_at: "2026-11-17T17:45:33Z"
---

# definitions.secretKeySelector 规格

## Purpose

新增共享结构能力 `definitions.secretKeySelector`，把单个 map 上下文渲染为 Kubernetes `SecretKeySelector` 字段片段，供 `definitions.envVarSource` 的 `secretKeyRef` 分支使用。同时统一 Secret 与 ConfigMap 的 data key 字符集校验，以及 `secretKeyRef`、`configMapKeyRef`、`fileKeyRef` 三个选择器的 `optional` 取值规则。

## ADDED Requirements

### Requirement: 字段渲染顺序与类型

系统 MUST 按官方字段顺序渲染 `SecretKeySelector` 的 `key`、`name`、`optional` 三个字段。

- `key` 与 `name` MUST 以双引号字符串输出。
- `optional` 为可选字段，缺省时不输出该字段；出现时 MUST 以布尔标量输出，显式 `false` 也输出。
- 输入中除这三个字段之外的键静默忽略。
- 输出 MUST 为单层字段片段，不包含 `secretKeyRef` 父键。

#### Scenario: 三字段齐全

- **WHEN** 输入为 `key: password`、`name: db-creds`、`optional: true`
- **THEN** 输出依次为 `key: "password"`、`name: "db-creds"`、`optional: true`

#### Scenario: optional 缺省

- **WHEN** 输入只有 `key` 与 `name`
- **THEN** 只输出 `key` 与 `name`，不含 `optional`

#### Scenario: optional 显式 false

- **WHEN** `optional` 为 `false`
- **THEN** 输出 `optional: false`

#### Scenario: 额外键忽略

- **WHEN** 输入含三个官方字段与未定义键 `foo`
- **THEN** 输出不含 `foo`

### Requirement: name 必填与 DNS subdomain 校验

系统 MUST 要求 `name` 非空，并限制为 RFC1123 Subdomain（DNS subdomain）。

- `name` 缺失、为 `null` 或只含空白时 MUST 中断渲染，失败消息 MUST 包含 `name`。
- 允许的字符为小写字母、数字、`-` 与 `.`；每段长度不超过 63 字符且首尾为字母或数字；总长不超过 253 字符。
- MUST NOT 采用 RFC1035 或 RFC1123 Label 规则，因此以数字开头与含点分段均为合法。
- 不符合规则时 MUST 中断渲染，失败消息 MUST 包含实际取值。
- 规则 MUST 由集中定义的固定表达式与长度上限表达，不在业务模板内内联。

#### Scenario: 典型名称

- **WHEN** `name` 为 `db-creds`
- **THEN** 渲染成功并输出 `name: "db-creds"`

#### Scenario: 数字开头与点分段

- **WHEN** `name` 为 `1secret` 或 `app.config`
- **THEN** 均渲染成功

#### Scenario: 长度边界

- **WHEN** `name` 为 63 字符的单段或总长 253 字符的多段名称
- **THEN** 渲染成功

#### Scenario: 字符集不匹配

- **WHEN** `name` 为 `My-Secret`、`secret_name` 或 `.secret`
- **THEN** 渲染中断，失败消息包含实际取值

#### Scenario: 单段超长

- **WHEN** `name` 为 64 字符的单段
- **THEN** 渲染中断

#### Scenario: 总长超限

- **WHEN** `name` 为 254 字符的多段名称
- **THEN** 渲染中断

#### Scenario: name 缺失或为空白

- **WHEN** `name` 缺失或为只含空白的字符串
- **THEN** 渲染中断，失败消息包含 `name`

### Requirement: key 必填与字符集校验

系统 MUST 要求 `key` 非空，并限制为 Secret data key 字符集。

- `key` 缺失、为 `null` 或只含空白时 MUST 中断渲染，失败消息 MUST 包含 `key`。
- `key` 为非字符串标量（如原生数字或布尔）时 MUST 中断渲染。
- 允许的字符为字母、数字、`-`、`_` 与 `.`；MUST NOT 限制首尾字符或最大长度。
- 不符合字符集时 MUST 中断渲染，失败消息 MUST 包含 `key` 与实际取值。
- 规则 MUST 由集中定义的固定表达式表达，不在业务模板内内联。

#### Scenario: 典型键

- **WHEN** `key` 为 `LOG_LEVEL`、`app.key`、`db-password` 或字符串 `"1"`
- **THEN** 全部渲染成功并输出对应字符串

#### Scenario: 特殊首尾字符

- **WHEN** `key` 为 `.key`、`key.`、`_key` 或 `-key`
- **THEN** 全部渲染成功

#### Scenario: 含空白

- **WHEN** `key` 为 `k ey`
- **THEN** 渲染中断，失败消息包含 `key` 与实际取值

#### Scenario: 含分隔符

- **WHEN** `key` 为 `k/ey` 或 `k:ey`
- **THEN** 渲染中断，失败消息包含 `key` 与实际取值

#### Scenario: key 缺失或为空白

- **WHEN** `key` 缺失或为只含空白的字符串
- **THEN** 渲染中断，失败消息包含 `key`

#### Scenario: 非字符串类型中断

- **WHEN** `key` 为原生数字 `1` 或原生布尔 `true`
- **THEN** 渲染中断

### Requirement: optional 接受布尔值与字符串 true/false

系统 MUST 接受原生布尔值以及字符串 `true`／`false` 作为 `optional` 的取值。

- 原生 `true` 与 `false` MUST 输出为布尔标量。
- 字符串 `true` 与 `false`（含带引号形式）MUST 输出为布尔标量。
- 数字、map、list 与其他字符串 MUST 中断渲染。

#### Scenario: 原生布尔

- **WHEN** `optional` 分别为原生 `true` 与 `false`
- **THEN** 输出 `optional: true` 与 `optional: false`

#### Scenario: 字符串布尔

- **WHEN** `optional` 为字符串 `"true"` 或 `"false"`
- **THEN** 输出 `optional: true` 或 `optional: false`

#### Scenario: 数字中断

- **WHEN** `optional` 为 `1`
- **THEN** 渲染中断

#### Scenario: 其他字符串与集合中断

- **WHEN** `optional` 为 `"yes"` 或 map
- **THEN** 渲染中断

## MODIFIED Requirements

### Requirement: configMapKeySelector 的 key 字符集校验

系统 MUST 对 `definitions.configMapKeySelector` 的 `key` 执行与 `definitions.secretKeySelector` 相同的字符集校验。

- `key` 缺失、为 `null` 或只含空白时 MUST 中断渲染，失败消息 MUST 包含 `key`。
- 允许的字符为字母、数字、`-`、`_` 与 `.`；MUST NOT 限制首尾字符或最大长度。
- 不符合字符集时 MUST 中断渲染，失败消息 MUST 包含 `key` 与实际取值。
- 其余字段行为保持不变：`key` 与 `name` 以双引号字符串输出，`name` 经 RFC1123 Subdomain 校验；`optional` 见下一条 Requirement。

#### Scenario: 合法键仍渲染

- **WHEN** `key` 为 `LOG_LEVEL` 或 `app.key`
- **THEN** 渲染成功并输出对应字符串

#### Scenario: 非法键中断

- **WHEN** `key` 为 `k/ey` 或 `k ey`
- **THEN** 渲染中断，失败消息包含 `key` 与实际取值

#### Scenario: 两个选择器行为一致

- **WHEN** 同一 `key` 分别输入 `definitions.configMapKeySelector` 与 `definitions.secretKeySelector`
- **THEN** 两者的成功或失败结果相同，且失败消息均包含实际取值

### Requirement: configMapKeySelector 的 optional 取值

系统 MUST 对 `definitions.configMapKeySelector` 的 `optional` 执行与 `definitions.secretKeySelector` 相同的取值规则。

- 原生 `true` 与 `false` MUST 输出为布尔标量。
- 字符串 `true` 与 `false`（含带引号形式）MUST 输出为布尔标量。
- 数字、map、list 与其他字符串 MUST 中断渲染。

#### Scenario: 字符串布尔启用 optional

- **WHEN** `optional` 为字符串 `"true"`
- **THEN** 输出 `optional: true`

#### Scenario: 非布尔取值中断

- **WHEN** `optional` 为 `1` 或 `"yes"`
- **THEN** 渲染中断

### Requirement: fileKeySelector 的 optional 取值

系统 MUST 对 `definitions.fileKeySelector` 的 `optional` 执行与 `definitions.secretKeySelector` 相同的取值规则。

- 原生 `true` 与 `false` MUST 输出为布尔标量。
- 字符串 `true` 与 `false`（含带引号形式）MUST 输出为布尔标量。
- 数字、map、list 与其他字符串 MUST 中断渲染。

#### Scenario: 字符串布尔启用 optional

- **WHEN** `optional` 为字符串 `"true"`
- **THEN** 输出 `optional: true`

#### Scenario: 非布尔取值中断

- **WHEN** `optional` 为 `1`
- **THEN** 渲染中断

### Requirement: envVarSource 的 secretKeyRef 字符串简写必需段数

系统 MUST 要求 `definitions.envVarSource` 中 `secretKeyRef` 的字符串简写至少包含 2 段。

- 段数少于 2 时 MUST NOT 组装该字段，输出空内容且不中断渲染。
- 达到 2 段时 MUST 按 `name`、`key`、`optional` 的位次组装。
- `optional` 段 MUST 按本规格的 `optional` 取值规则解析，`true` 与 `false` 均生效。
- 超出 3 段的多余段 MUST 被忽略。
- 其余字段的位次映射与互斥规则保持不变。

#### Scenario: 单段不组装

- **WHEN** `secretKeyRef` 为 `db-creds`
- **THEN** 不输出任何 `secretKeyRef` 内容且不中断渲染

#### Scenario: 两段组装

- **WHEN** `secretKeyRef` 为 `db-creds password`
- **THEN** 输出 `name` 为 `db-creds`、`key` 为 `password`

#### Scenario: 三段启用 optional

- **WHEN** `secretKeyRef` 为 `db-creds password true`
- **THEN** 输出 `name` 为 `db-creds`、`key` 为 `password`、`optional: true`

#### Scenario: 多余段忽略

- **WHEN** `secretKeyRef` 为 `db-creds password true extra`
- **THEN** 输出 `name`、`key`、`optional` 三个字段，`extra` 被忽略

## 非目标

- 不渲染 `EnvVarSource` 的其他字段。
- 不实现 `definitions.envVarSource` 的分发与互斥逻辑变更。
- 不校验 `name` 指向的 Secret 或 ConfigMap 是否存在。
- 不校验 `key` 是否真实存在于目标对象。
