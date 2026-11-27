---
updated_at: "2026-11-27T02:44:38Z"
---

# PVC 卷源定义规格

## Purpose

定义 `definitions.persistentVolumeClaimVolumeSource` 的可观察行为，使 PVC 卷源按官方 `PersistentVolumeClaimVolumeSource` 结构渲染。

## ADDED Requirements

### Requirement: PersistentVolumeClaimVolumeSource 字段渲染

系统 MUST 按 `claimName`、`readOnly` 顺序渲染 PVC 卷源字段；`claimName` 必填，`readOnly` 可选，缺省时不输出。

#### Scenario: 仅提供 claimName

- **WHEN** 上下文为 `{claimName: "data"}`
- **THEN** 输出 `claimName: "data"`，不输出 `readOnly`

#### Scenario: 提供完整字段

- **WHEN** 上下文为 `{claimName: "data", readOnly: true}`
- **THEN** 按 `claimName`、`readOnly` 顺序输出，`readOnly` 为 `true`

#### Scenario: 显式 false

- **WHEN** `readOnly` 为 `false`
- **THEN** 输出 `readOnly: false`

#### Scenario: 输入形态一致

- **WHEN** 上下文为原生 map 或父模板清洗后的 map，且字段值相同
- **THEN** 两种形态渲染结果一致

### Requirement: PersistentVolumeClaimVolumeSource 输入校验

系统 MUST 在 `claimName` 缺失、为空或不是 string，或 `readOnly` 类型非法时中断渲染并报错。

#### Scenario: claimName 缺失或为空

- **WHEN** 上下文缺少 `claimName` 或 `claimName` 为空
- **THEN** 渲染中断并报错

#### Scenario: claimName 类型非法

- **WHEN** `claimName` 不是 string 标量
- **THEN** 渲染中断并报错

#### Scenario: readOnly 类型非法

- **WHEN** `readOnly` 既不是 boolean 也不是大小写不敏感的 `true`/`false` 字符串
- **THEN** 渲染中断并报错
