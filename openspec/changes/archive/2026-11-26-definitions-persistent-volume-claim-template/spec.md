---
updated_at: "2026-11-25T17:17:23Z"
---

# `definitions.persistentVolumeClaimTemplate` 规格

## Purpose

为 `Volume.ephemeral.volumeClaimTemplate` 提供 Kubernetes `PersistentVolumeClaimTemplate` 字段片段渲染能力。

## ADDED Requirements

### Requirement: PersistentVolumeClaimTemplate 字段片段渲染

系统 MUST 接受原生 map 上下文，输出可嵌入 `volumeClaimTemplate` 的 `metadata` 与 `spec` 字段片段，且不包含 `volumeClaimTemplate` 父键、文档分隔符、`status` 或控制字段。

#### Scenario: 渲染 metadata 与 spec

- **WHEN** 上下文包含 `metadata` 与 `spec`
- **THEN** 输出同时包含 `metadata` 与 `spec` 字段片段
- **AND** `metadata` 的内容由 `definitions.objectMeta` 对该 map 的输出决定
- **AND** `spec` 的内容由 `core.persistentVolumeClaimSpec` 对该 map 的输出决定

#### Scenario: 省略缺失或为空的 metadata

- **WHEN** 上下文缺失 `metadata`，或其值为 `null` 或空 map
- **THEN** 输出仅包含 `spec`

#### Scenario: metadata 子模板无有效输出

- **WHEN** `definitions.objectMeta` 返回空内容
- **THEN** 输出仅包含 `spec`

### Requirement: 输入失败边界

系统 MUST 在上下文或字段非法时中断渲染，本层错误消息以 `[definitions.persistentVolumeClaimTemplate]` 开头并包含字段路径。

#### Scenario: spec 缺失

- **WHEN** 上下文缺失 `spec`
- **THEN** 渲染中断

#### Scenario: spec 为空

- **WHEN** `spec` 为 `null` 或空 map
- **THEN** 渲染中断

#### Scenario: spec 渲染结果为空

- **WHEN** `core.persistentVolumeClaimSpec` 返回空内容
- **THEN** 渲染中断

#### Scenario: 字段无法作为 map 处理

- **WHEN** `metadata` 或 `spec` 的值无法恢复为 map
- **THEN** 渲染中断

#### Scenario: 子模板返回非法 YAML

- **WHEN** `definitions.objectMeta` 或 `core.persistentVolumeClaimSpec` 返回非法 YAML
- **THEN** 渲染中断

#### Scenario: 非 map 上下文

- **WHEN** 模板上下文不是 map
- **THEN** 渲染中断

## 非目标

- 不创建 `core.persistentVolumeClaimSpec`；其字段级行为不属于本变更。
- 不修改 `definitions.objectMeta` 的现有输出与失败行为。
