---
updated_at: "2026-11-26T06:10:59Z"
---

# core.persistentVolumeClaimSpec 规格

## Purpose

为 Kubernetes 原生 `PersistentVolumeClaimSpec` 提供可复用的字段片段渲染能力。

## ADDED Requirements

### Requirement: PersistentVolumeClaimSpec 字段渲染

系统 MUST 以原生 map 为上下文，按 Kubernetes `PersistentVolumeClaimSpec` 官方字段表覆盖全部字段，并按该表顺序渲染为 YAML 字段片段。所有字段均为可选。

#### Scenario: 渲染全部字段

- **WHEN** 上下文提供合法的 `accessModes`、`dataSource`、`dataSourceRef`、`resources`、`selector`、`storageClassName`、`volumeAttributesClassName`、`volumeMode` 与 `volumeName`
- **THEN** 按上述顺序输出各字段
- **AND** 不输出 `spec`、`status`、`apiVersion` 或 `kind`

#### Scenario: 所有字段缺省

- **WHEN** 上下文中不存在任何受支持字段，或其值均为 `null`、空 map、空数组或空字符串
- **THEN** 输出空内容

#### Scenario: 使用隐式别名

- **WHEN** 上下文为某字段提供非空的同名 `<字段名>Alias`
- **THEN** 使用别名值，并按规范字段名输出

#### Scenario: 字符串规范化

- **WHEN** 标量字符串或 `accessModes` 元素包含首尾空白
- **THEN** 去除首尾空白后再使用
- **AND** 标量字符串为空时视为未提供；`accessModes` 元素为空时按枚举非法处理

### Requirement: accessModes 校验

系统 MUST 只接受字符串数组，并将每项限制为 Kubernetes 官方访问模式枚举。

#### Scenario: 合法访问模式

- **WHEN** `accessModes` 为字符串数组，且每项为 `ReadWriteOnce`、`ReadOnlyMany`、`ReadWriteMany` 或 `ReadWriteOncePod`
- **THEN** 按输入顺序输出该数组；空数组不输出该字段

#### Scenario: 非数组输入

- **WHEN** `accessModes` 不是数组
- **THEN** 渲染中断

#### Scenario: 元素类型非法

- **WHEN** `accessModes` 的任一元素不是字符串
- **THEN** 渲染中断

#### Scenario: 枚举非法

- **WHEN** `accessModes` 的任一元素不在官方枚举内
- **THEN** 渲染中断，并提示合法枚举范围

#### Scenario: 不接受字符串简写

- **WHEN** `accessModes` 以字符串形式提供
- **THEN** 渲染中断

### Requirement: volumeMode 枚举

系统 MUST 将 `volumeMode` 限制为 Kubernetes 官方枚举。

#### Scenario: 合法 volumeMode

- **WHEN** `volumeMode` 为 `Filesystem` 或 `Block`
- **THEN** 输出该字段

#### Scenario: 非法 volumeMode

- **WHEN** `volumeMode` 不是 `Filesystem` 或 `Block`
- **THEN** 渲染中断，并提示合法枚举范围

### Requirement: 子结构委托

系统 MUST 将四个结构化字段委托给对应 definitions 模板，自身不解析其内部结构。

#### Scenario: 非空子结构

- **WHEN** `dataSource`、`dataSourceRef`、`resources` 或 `selector` 为非空 map
- **THEN** 以该 map 为上下文调用 `definitions.typedLocalObjectReference`、`definitions.typedObjectReference`、`definitions.volumeResourceRequirements` 或 `definitions.labelSelector`
- **AND** 输出子模板返回的非空 YAML 片段

#### Scenario: 空子结构

- **WHEN** 对应字段缺失、为 `null` 或为空 map
- **THEN** 不调用子模板，也不输出该字段

#### Scenario: 子模板返回空内容

- **WHEN** 子模板返回空内容
- **THEN** 不输出该字段

#### Scenario: 子模板校验失败

- **WHEN** 任一子模板按其自身契约拒绝输入
- **THEN** 渲染中断

#### Scenario: 子模板输出非法 YAML

- **WHEN** 子模板返回非法 YAML
- **THEN** 渲染中断

### Requirement: 输入边界

系统 MUST 忽略未支持的输入字段，并拒绝不匹配的标量类型。

#### Scenario: 未支持字段

- **WHEN** 上下文包含未列出的键
- **THEN** 静默忽略，不影响已支持字段的输出

#### Scenario: 标量类型非法

- **WHEN** `storageClassName`、`volumeAttributesClassName` 或 `volumeName` 不是字符串
- **THEN** 渲染中断

## 非目标

- 不创建 `definitions.typedLocalObjectReference`、`definitions.typedObjectReference` 与 `definitions.volumeResourceRequirements`。
- 不实现 `TypedLocalObjectReference`、`TypedObjectReference`、`VolumeResourceRequirements` 或 `LabelSelector` 的内部字段校验。
- 不输出 `spec`、`status`、`apiVersion`、`kind` 或任何父级对象。
- 不修改 `definitions.persistentVolumeClaimTemplate` 等现有调用方。
