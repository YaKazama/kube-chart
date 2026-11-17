---
updated_at: "2026-11-17T16:01:12Z"
---

# definitions.objectFieldSelector 规格

## Purpose

新增共享结构能力 `definitions.objectFieldSelector`，把单个 map 上下文渲染为 Kubernetes `ObjectFieldSelector` 字段片段，供 `definitions.envVarSource` 的 `fieldRef` 分支使用。

## ADDED Requirements

### Requirement: 字段渲染顺序与类型

系统 MUST 按官方字段顺序渲染 `ObjectFieldSelector` 的 `apiVersion`、`fieldPath` 两个字段。

- `apiVersion` MUST 以双引号字符串输出，缺省时不输出该字段，不使用官方默认值 `v1`。
- `fieldPath` MUST 以双引号字符串输出。
- 输入中除这两个字段之外的键静默忽略。

#### Scenario: 两个字段齐全

- **WHEN** 输入为 `apiVersion: v1`、`fieldPath: metadata.name`
- **THEN** 输出依次为 `apiVersion: "v1"`、`fieldPath: "metadata.name"`

#### Scenario: apiVersion 缺省

- **WHEN** 输入只有 `fieldPath: spec.nodeName`
- **THEN** 只输出 `fieldPath`，不含 `apiVersion`

#### Scenario: 额外键忽略

- **WHEN** 输入含 `fieldPath` 与未定义键 `foo`
- **THEN** 输出不含 `foo`

### Requirement: fieldPath 必填

系统 MUST 要求 `fieldPath` 非空，并在不满足时中断渲染。

- `fieldPath` 缺失或为空白时中断，失败消息 MUST 包含 `fieldPath`。

#### Scenario: fieldPath 缺失

- **WHEN** 输入只有 `apiVersion`
- **THEN** 渲染中断，失败消息包含 `fieldPath`

#### Scenario: fieldPath 为空白

- **WHEN** `fieldPath` 为只含空白的字符串
- **THEN** 渲染中断，失败消息包含 `fieldPath`

### Requirement: fieldPath 限制为官方支持的字段路径

系统 MUST 在 `fieldPath` 非空后按官方支持的字段路径集校验。

- 允许的取值为 `metadata.name`、`metadata.namespace`、`metadata.uid`、`metadata.labels['<KEY>']`、`metadata.annotations['<KEY>']`、`spec.nodeName`、`spec.serviceAccountName`、`status.hostIP`、`status.podIP`、`status.podIPs`。
- `metadata.uid` 属于 `DownwardAPIVolumeFile.fieldRef` 的支持集，其余字面路径属于 `EnvVarSource.fieldRef` 的支持集；两者合并为本能力的允许列表。
- `metadata.labels['<KEY>']` 与 `metadata.annotations['<KEY>']` 的 `<KEY>` MUST 为非空字符串。
- 不在该集合内的取值 MUST 中断渲染，失败消息 MUST 包含实际取值。
- 规则 MUST 由集中定义的固定表达式表达，不在业务模板内内联。

#### Scenario: 字面路径

- **WHEN** `fieldPath` 分别为 `metadata.name`、`metadata.namespace`、`metadata.uid`、`spec.nodeName`、`spec.serviceAccountName`、`status.hostIP`、`status.podIP`、`status.podIPs`
- **THEN** 全部渲染成功并输出该取值

#### Scenario: 带键的标签路径

- **WHEN** `fieldPath` 为 `metadata.labels['app']` 或 `metadata.annotations['note']`
- **THEN** 渲染成功并输出该取值

#### Scenario: 空键

- **WHEN** `fieldPath` 为 `metadata.labels['']`
- **THEN** 渲染中断，失败消息包含实际取值

#### Scenario: 不在支持列表内

- **WHEN** `fieldPath` 为 `spec.containers[0].name`、`metadata.labels` 或 `status.podIPs[0]`
- **THEN** 渲染中断，失败消息包含实际取值

#### Scenario: 大小写敏感

- **WHEN** `fieldPath` 为 `Metadata.Name`、`metadata.UID` 或 `spec.nodename`
- **THEN** 渲染中断

## 非目标

- 不渲染 `EnvVarSource` 的其他字段。
- 不实现 `definitions.envVarSource` 的分发逻辑。
- 不校验 `metadata.labels['<KEY>']` 与 `metadata.annotations['<KEY>']` 内的键是否符合 Kubernetes 标签键语法。
- 不兼容 `DownwardAPIVolumeFile` 除 `metadata.uid` 以外的路径扩展，如裸 `metadata.labels`。
- 不校验 `apiVersion` 的合法取值。
- 不按调用方区分路径集：`spec.nodeName` 等 `EnvVarSource` 专属路径在 `DownwardAPIVolumeFile` 场景下会被 API Server 拒绝，本能力不做前置区分。
