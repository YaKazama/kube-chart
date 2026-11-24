---
updated_at: "2026-11-24T16:13:18Z"
---

# definitions.emptyDirVolumeSource 规格

## Purpose

为库 Chart 提供 `definitions.emptyDirVolumeSource` 模板，把原生 map 或父模板清洗后的上下文渲染为 Kubernetes `EmptyDirVolumeSource` YAML 字段片段。

## ADDED Requirements

### Requirement: 上下文兼容

系统 MUST 接受原生 map 与父模板清洗后的 map 两种上下文；两种形态都只读取 `EmptyDirVolumeSource` 定义的键，父模板清洗后的值视为已归一化，不再重复清洗。

#### Scenario: 原生 map 输入

- **WHEN** 模板以 `{medium: "Memory", sizeLimit: "1Gi"}` 原生 map 调用
- **THEN** 校验后输出包含 `medium` 与 `sizeLimit` 的 YAML 字段片段

#### Scenario: 父模板清洗后的 map 输入

- **WHEN** 模板以已归一化的 `{medium: "Memory", sizeLimit: "1Gi"}` 调用
- **THEN** 模板直接校验并输出，不对值做二次清洗

### Requirement: medium 取值与校验

系统 MUST 仅接受 `""` 与 `Memory` 作为 `medium` 的有效取值，枚举比较 MUST 大小写敏感；缺省、`null` 或 `""` 时 MUST 不渲染该字段；其他值 MUST 中断渲染。

#### Scenario: 合法 medium

- **WHEN** `medium` 为 `Memory`
- **THEN** 输出 `medium` 字段

#### Scenario: 空 medium

- **WHEN** `medium` 缺省、为 `null` 或为 `""`
- **THEN** 不输出 `medium` 字段

#### Scenario: 非法 medium

- **WHEN** `medium` 为 `memory` 或其他非 `Memory` 的值
- **THEN** 中断渲染并报告错误

### Requirement: sizeLimit 取值与校验

系统 MUST 接受数值或字符串形式的 Quantity；字符串的 YAML 引号 MUST 被解码；缺省或空值 MUST 不渲染该字段；非法 Quantity MUST 中断渲染。

#### Scenario: 合法 sizeLimit

- **WHEN** `sizeLimit` 为 `1Gi`（带或不带 YAML 引号）或数值 `1024`
- **THEN** 输出 `sizeLimit` 字段

#### Scenario: 空 sizeLimit

- **WHEN** `sizeLimit` 缺省、为 `null` 或为 `""`
- **THEN** 不输出 `sizeLimit` 字段

#### Scenario: 非法 sizeLimit

- **WHEN** `sizeLimit` 为 `1GG` 或其他不符合 Quantity 规范的值
- **THEN** 中断渲染并报告错误

### Requirement: 空内容与未知键

系统 MUST 在上下文为空 map 时输出空内容，不渲染任何字段；`EmptyDirVolumeSource` 定义之外的键 MUST 被忽略；`emptyDir` 父键 MUST 由调用方处理。

#### Scenario: 空 map

- **WHEN** 上下文为空 map
- **THEN** 输出空内容，不渲染任何字段

#### Scenario: 未知键

- **WHEN** 上下文除 `medium`、`sizeLimit` 外还包含其他键（含 `mediumAlias`、`sizeLimitAlias`）
- **THEN** 忽略这些键，不输出对应字段，也不中断渲染

### Requirement: 字段顺序与输出边界

系统 MUST 按 Kubernetes API 字段顺序输出实际生效的 `medium`、`sizeLimit`；MUST 只输出可作为 `emptyDir` 值解析的合法 YAML 字段片段，不输出 `emptyDir` 父键、`apiVersion` 或 `kind`。

#### Scenario: 字段顺序

- **WHEN** `medium` 与 `sizeLimit` 同时有效
- **THEN** `medium` 字段位于 `sizeLimit` 字段之前

#### Scenario: 可被 Kubernetes 接受

- **WHEN** `medium` 与 `sizeLimit` 均通过校验
- **THEN** 输出可作为 `emptyDir` 值解析的合法 YAML 字段片段

## 非目标

- 不处理 `emptyDir` 之外的卷类型。
- 不负责组装 `emptyDir` 父键，空 map 的 `emptyDir: {}` 由调用方处理。
- 不把原生值归一化为父模板清洗后的形态。
