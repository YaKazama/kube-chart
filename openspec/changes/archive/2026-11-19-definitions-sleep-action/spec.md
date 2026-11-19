---
updated_at: "2026-11-19T14:14:48Z"
---

# 新增 definitions.sleepAction 规格

## Purpose

为 Kubernetes `SleepAction` 提供共享结构渲染能力，把 `seconds` 归一为 integer 后输出字段片段，供 `definitions.lifecycleHandler` 等上层结构委托调用。

## ADDED Requirements

### Requirement: SleepAction 片段渲染

系统 MUST 在 map 上下文中处理 `seconds`；当 `seconds` 为整数语义数值时，只输出 `seconds` 一个字段，且该字段以 integer 渲染。

#### Scenario: 原生整数输入

- **WHEN** 上下文为 `seconds: 30`，取值为 int 或 int64
- **THEN** 输出 `seconds: 30`，不带引号

#### Scenario: 整值 float64 输入

- **WHEN** 上下文为 `seconds: 30.0`
- **THEN** 输出 `seconds: 30`，不带引号

#### Scenario: 大整数 float64 输入

- **WHEN** 上下文为 `seconds` 取值 12345678 的 float64
- **THEN** 输出 `seconds: 12345678`

#### Scenario: 上限边界接受

- **WHEN** 上下文 `seconds` 取值为 9007199254740991
- **THEN** 输出 `seconds: 9007199254740991`

### Requirement: 缺失与空值不渲染

系统 MUST 在 `seconds` 缺失、为 null 或为空字符串时输出空内容，且不中断渲染。

#### Scenario: 字段缺失

- **WHEN** 上下文不包含 `seconds`
- **THEN** 输出为空内容，渲染继续

#### Scenario: 显式 null

- **WHEN** 上下文为 `seconds: null`
- **THEN** 输出为空内容，渲染继续

#### Scenario: 空字符串

- **WHEN** 上下文为 `seconds: ""`
- **THEN** 输出为空内容，渲染继续

### Requirement: 非法输入中断

系统 MUST 在 `seconds` 不是整数语义数值或超出允许范围时中断渲染。

#### Scenario: 字符串输入

- **WHEN** 上下文为 `seconds: "30"` 或任何其他字符串
- **THEN** 渲染中断

#### Scenario: 非整数 float64

- **WHEN** 上下文为 `seconds: 3.7`
- **THEN** 渲染中断

#### Scenario: 布尔、序列与映射输入

- **WHEN** 上下文 `seconds` 为 true、list 或 map
- **THEN** 渲染中断

#### Scenario: 低于下限

- **WHEN** 上下文为 `seconds: 0` 或负数
- **THEN** 渲染中断

#### Scenario: 高于上限

- **WHEN** 上下文 `seconds` 取值为 9007199254740992
- **THEN** 渲染中断，不因精度丢失而静默截断

## 非目标

- 不处理 `lifecycle`、`postStart`、`preStop` 等父级字段，也不输出 `apiVersion`、`kind` 或 `status`。
- 不校验 sleep 时长在 Kubernetes 运行时的实际约束。
