---
updated_at: "2026-11-18T17:33:46Z"
---

# definitions.httpHeader 规格

## Purpose

新增命名模板 `definitions.httpHeader`，将 map 上下文中的 `name` 与 `value` 校验、归一化后渲染为可嵌入 HTTPGetAction 的 HTTPHeader 字段片段。

## ADDED Requirements

### Requirement: 字段校验与输出

系统 MUST 接受包含 `name` 与 `value` 的 map 上下文。`name` 与 `value` MUST 均为 string；两者去除首尾空白后 MUST 均非空，否则 MUST 中断渲染。输出 MUST 按 Kubernetes HTTPHeader 官方顺序包含去除首尾空白后的 `name`、`value` 字符串字段。

#### Scenario: 有效字段

- **WHEN** 上下文包含 `name: " X-Foo "` 与 `value: " bar "`
- **THEN** 按顺序输出 `name: "X-Foo"` 与 `value: "bar"`

#### Scenario: 字段缺失、为空或仅含空白

- **WHEN** `name` 或 `value` 缺失、为空字符串，或去除首尾空白后为空
- **THEN** 渲染中断

#### Scenario: 非字符串字段

- **WHEN** `name` 或 `value` 不是 string
- **THEN** 渲染中断

## 非目标

- 不校验 HTTPHeader 名称或值的协议语法。
- 不处理 `name`、`value` 之外的其他字段。
