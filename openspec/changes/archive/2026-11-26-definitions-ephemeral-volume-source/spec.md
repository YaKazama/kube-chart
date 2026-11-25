---
updated_at: "2026-11-25T16:42:15Z"
---

# `definitions.ephemeralVolumeSource` 规格

## Purpose

为 Kubernetes EphemeralVolumeSource 提供共享结构渲染能力，供 `definitions.volume` 的 `ephemeral` 源复用。

## ADDED Requirements

### Requirement: 原生 map 上下文与字段范围

系统 MUST 只接受原生 map 上下文，并且只读取 `volumeClaimTemplate` 字段；未声明的键必须静默忽略，输出不得包含 `ephemeral` 父键。

#### Scenario: 未声明的键

- **WHEN** 上下文包含 `volumeClaimTemplate` 以外的任意键
- **THEN** 这些键不出现在输出中，也不触发错误

#### Scenario: 输出范围

- **WHEN** 模板成功渲染
- **THEN** 输出只包含当前层字段，不包含 `ephemeral` 父键

### Requirement: volumeClaimTemplate 必填且可恢复为非空 map

系统 MUST 在 `volumeClaimTemplate` 缺失、为 null、为空 map 或无法恢复为 map 时中断渲染并报错。

#### Scenario: 缺失或为 null

- **WHEN** 上下文不包含 `volumeClaimTemplate`，或其值为 null
- **THEN** 渲染中断并报错

#### Scenario: 空 map

- **WHEN** `volumeClaimTemplate` 的值为空 map
- **THEN** 渲染中断并报错

#### Scenario: 无法恢复为 map 的值

- **WHEN** `volumeClaimTemplate` 的值为无法恢复为 map 的字符串、列表或其他类型
- **THEN** 渲染中断并报错

### Requirement: 子模板委托与字段输出

系统 MUST 将非空 `volumeClaimTemplate` 作为上下文调用 `definitions.persistentVolumeClaimTemplate`；子模板返回非空内容时输出 `volumeClaimTemplate` 字段，返回空内容时不输出该字段，且不因输出为空而中断或附加提示。

#### Scenario: 子模板返回非空内容

- **WHEN** `volumeClaimTemplate` 为非空 map，且 `definitions.persistentVolumeClaimTemplate` 返回非空字段片段
- **THEN** 输出包含 `volumeClaimTemplate` 字段

#### Scenario: 子模板返回空内容

- **WHEN** `volumeClaimTemplate` 为非空 map，且 `definitions.persistentVolumeClaimTemplate` 返回空内容
- **THEN** 输出不包含 `volumeClaimTemplate` 字段，且渲染不中断

## 非目标

- 不实现 `definitions.persistentVolumeClaimTemplate`；`volumeClaimTemplate` 的最终渲染委托该模板，本 change 不读取或校验其内部结构。该子模板未定义时真实渲染会中断，隔离验证需提供同名 fixture。
- 不接受字符串简写形式，也不处理父模板清洗后的 map。
- 不负责判断 volume 是否声明 `ephemeral`，也不处理 `projected` 源；这些约束由父模板 `definitions.volume` 负责。
- 不对子模板占位期间的空输出做额外校验或提示。
