---
updated_at: "2026-11-28T09:18:57Z"
---

# definitions.downwardAPIProjection 规格

## Purpose

为 `VolumeProjection.downwardAPI` 提供 core/v1 `DownwardAPIProjection` 的可复用渲染能力。

## ADDED Requirements

### Requirement: 渲染 items 字段

系统 MUST 以原生 map 为上下文，仅渲染 core/v1 `DownwardAPIProjection` 的 `items` 字段；`items` 缺失或为空数组时 MUST 输出空片段；未定义的输入字段 MUST 静默忽略。

#### Scenario: 未提供 items

- **WHEN** 上下文为 `{}` 或 `{items: []}`
- **THEN** 模板输出为空

#### Scenario: 仅渲染 items

- **WHEN** 上下文包含合法 `items` 以及其他未定义字段
- **THEN** 输出仅包含 `items`，其他字段不输出

### Requirement: items 委托、去重与去空

系统 MUST 将 `items` 作为可选 DownwardAPIVolumeFile array：每个条目 MUST 为原生 map，并逐项委托 `definitions.downwardAPIVolumeFile` 渲染；子模板输出为空时 MUST 剔除该条目，完全相同的结果 MUST 只保留首个；空数组或全部结果被剔除时 MUST 省略 `items`；`items` 不是 array、条目不是 map、子模板输出非法 YAML 或子模板校验失败时 MUST 中断渲染。

#### Scenario: 重复条目去重

- **WHEN** `items` 包含两个完全相同的 DownwardAPIVolumeFile
- **THEN** 输出只包含一个对应的 `items` 条目

#### Scenario: items 类型非法

- **WHEN** `items` 不是 array，或某个条目不是 map
- **THEN** 渲染中断并报告类型错误

#### Scenario: 子模板校验失败

- **WHEN** 某个条目缺少 `definitions.downwardAPIVolumeFile` 要求的必填内容，或 `path` 非法
- **THEN** 渲染中断并报告子模板校验错误

## 非目标

- 不创建或修改 `definitions.downwardAPIVolumeFile`。
