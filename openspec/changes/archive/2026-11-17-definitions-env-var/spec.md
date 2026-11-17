---
updated_at: "2026-11-17T15:06:52Z"
---

# definitions.envVar 规格

## Purpose

新增共享结构能力 `definitions.envVar`，把单个环境变量上下文渲染为 Kubernetes `EnvVar` 字段片段，并为 `valueFrom` 的紧凑字符串写法提供第一层关键字解析入口。

## ADDED Requirements

### Requirement: EnvVar 基础字段渲染

系统 MUST 从当前上下文读取 `name`、`value` 和 `valueFrom`，只输出 `EnvVar` 的 `name`、`value`、`valueFrom` 字段。

- `name` 必须为字符串；缺失或为空时中断渲染，失败消息必须包含 `name`。
- `value` 与 `valueFrom` 互斥；同时出现时中断渲染。
- `value` MUST 以双引号字符串输出；输入为字符串或非 string 标量时均不得输出为数字或布尔类型。
- `value` 缺省或为空字符串视为未提供。
- `value` 与 `valueFrom` 均未提供时只输出 `name`。
- `value` 为对象或数组时中断渲染，失败消息必须包含 `value`。
- 输入中除 `name`、`value`、`valueFrom` 之外的键静默忽略。

#### Scenario: 渲染字面值

- **WHEN** 输入为 `name: FOO` 与 `value: bar`
- **THEN** 输出含 `name: "FOO"` 与 `value: "bar"`

#### Scenario: 非 string 标量强制字符串输出

- **WHEN** 输入 `name: FOO` 且 `value` 为数字 `123`、浮点数 `1.5` 或布尔 `true`
- **THEN** 输出 `value: "123"`、`value: "1.5"`、`value: "true"`，不产生数字或布尔类型

#### Scenario: value 为对象或数组

- **WHEN** `value` 为 map 或 list
- **THEN** 渲染中断，失败消息包含 `value`

#### Scenario: 缺少 name

- **WHEN** 输入缺少 `name`
- **THEN** 渲染中断，失败消息包含 `name`

#### Scenario: name 为空

- **WHEN** 输入 `name` 为空字符串
- **THEN** 渲染中断

#### Scenario: value 与 valueFrom 并存

- **WHEN** 输入同时包含非空 `value` 和非空 `valueFrom`
- **THEN** 渲染中断

#### Scenario: 只提供 name

- **WHEN** 输入只有 `name`，或 `value` 为空字符串
- **THEN** 只输出 `name` 字段

### Requirement: valueFrom 紧凑字符串的第一层解析

系统 MUST 在 `valueFrom` 为字符串时按逗号或空白切分为两段，第 1 段为关键字（大小写不敏感），第 2 段为原串，并且只按关键字选择 `EnvVarSource` 字段。

- 关键字映射为：`configMap`、`cm` → `configMapKeyRef`；`field` → `fieldRef`；`file` → `fileKeyRef`；`resource` → `resourceFieldRef`；`secret` → `secretKeyRef`。
- 第 2 段 MUST 保留原文，仅去除分隔符产生的首尾空白，不切分、不校验其内部结构。
- 传给 `definitions.envVarSource` 的上下文 MUST 是单键 map，键为映射出的字段名，值为第 2 段原文。

#### Scenario: ConfigMap 关键字

- **WHEN** `valueFrom` 为 `cm app-config LOG_LEVEL`
- **THEN** 委托上下文为 `configMapKeyRef`，值为 `app-config LOG_LEVEL`

#### Scenario: 关键字大小写与逗号分隔

- **WHEN** `valueFrom` 为 `ConfigMap, app-config`
- **THEN** 委托上下文为 `configMapKeyRef`，值为 `app-config`

#### Scenario: 其余关键字

- **WHEN** `valueFrom` 分别为 `field metadata.name`、`file volume-a /etc/x`、`resource limits.cpu`、`secret db-creds password`
- **THEN** 委托上下文的键分别为 `fieldRef`、`fileKeyRef`、`resourceFieldRef`、`secretKeyRef`

### Requirement: valueFrom 原生 map 透传

系统 MUST 在 `valueFrom` 为 map 时把该 map 原样作为 `definitions.envVarSource` 的上下文，不做关键字识别、字段名校验或结构转换。

#### Scenario: 原生 map 透传

- **WHEN** `valueFrom` 为 `configMapKeyRef` 对象
- **THEN** `definitions.envVarSource` 收到同一结构

#### Scenario: 子模板无结果

- **WHEN** `definitions.envVarSource` 返回空结果
- **THEN** 输出不含 `valueFrom` 字段

### Requirement: 无法构成委托上下文时忽略 valueFrom

系统 MUST 在 `valueFrom` 无法构成单键委托上下文时跳过 `valueFrom`，只输出 `name`，不得中断渲染。

#### Scenario: 只有关键字

- **WHEN** `valueFrom` 为 `cm`
- **THEN** 只输出 `name`

#### Scenario: 关键字不在映射内

- **WHEN** `valueFrom` 为 `env app-config`
- **THEN** 只输出 `name`

#### Scenario: valueFrom 为空字符串

- **WHEN** `valueFrom` 为空字符串
- **THEN** 只输出 `name`

### Requirement: 子模板委托边界

系统 MUST 只通过 `definitions.envVarSource` 渲染 `valueFrom` 的内容。

- `definitions.envVarSource` 在当前 change 中不实现，其可用性与内部字段映射由后续 change 提供。
- 本 change MUST NOT 新增该子模板的实现、占位定义或内联替代实现。

#### Scenario: 委托而非内联

- **WHEN** `valueFrom` 产生有效委托上下文
- **THEN** 渲染结果完全来自 `definitions.envVarSource`，本能力不输出 `configMapKeyRef` 等对象内部字段

## 非目标

- 不实现 `definitions.envVarSource`，不输出 `configMapKeyRef`、`fieldRef`、`fileKeyRef`、`resourceFieldRef`、`secretKeyRef` 的对象内部字段。
- 不对齐第二层语法与既有参考正则之间的差异（`secretKeyRef` 的 `key` 是否必填、`fileKeyRef` 是否含 `key` 段）。
- 不处理容器级 `env` 数组的聚合、去重与去空。
- 不校验 `name` 的 Kubernetes 标识符格式。
