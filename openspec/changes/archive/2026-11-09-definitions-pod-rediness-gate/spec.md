---
updated_at: "2026-11-09T14:05:18Z"
---

# definitions.podReadinessGate 模板规格

## Purpose

新增 `definitions.podReadinessGate`，把父级传入的单个 readinessGate 上下文渲染为 Kubernetes `PodReadinessGate` 条目。

## ADDED Requirements

### Requirement: Pod readinessGate 条目渲染

系统 MUST 依据父级传入的 `conditionType` 渲染单条 `PodReadinessGate` 条目，输出只包含 `conditionType` 字段，且该值以带引号标量输出。

#### Scenario: 渲染非空 conditionType

- **WHEN** 父级传入非空 string 类型的 `conditionType`
- **THEN** 渲染结果只包含一个 `conditionType` 字段，其值为去除首尾空白后的带引号标量

#### Scenario: 空值不渲染

- **WHEN** `conditionType` 缺失、为 `null` 或为空
- **THEN** 模板返回空内容，不输出任何字段

#### Scenario: 非法类型中断渲染

- **WHEN** `conditionType` 存在且不是 string 类型
- **THEN** 渲染中断，并产生以本模板标识的错误消息

## 非目标

- 不处理 `readinessGates` 数组的循环、字符串简写归一化、条目合并与去重；这些由父级负责。
- 不校验 `conditionType` 的取值合法性。
- 不输出 `PodReadinessGate` 以外的字段。
