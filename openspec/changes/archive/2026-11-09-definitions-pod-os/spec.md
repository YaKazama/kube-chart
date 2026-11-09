---
updated_at: "2026-11-09T13:47:38Z"
---

# PodOS 共享结构规格

## Purpose

新增共享结构能力 `definitions.podOS`，把父级传入的单个操作系统描述渲染为符合 Kubernetes `PodOS` 的 YAML 字段片段，并对 `name` 做小写归一与枚举校验。

## ADDED Requirements

### Requirement: 渲染 PodOS 字段片段

系统 MUST 接受 map 输入，只读取 `name`，并输出仅包含 `name` 的 YAML 字段片段。

系统 MUST 输出可作为单个 `PodOS` 嵌入父级 `os` 字段的片段；`name` 值 MUST 以可读作 string 的 YAML 标量输出，取值为 `linux` 或 `windows`。

系统 MUST 识别同级 `nameAlias`；非空 `nameAlias` MUST 优先于 `name`，别名缺失或为空时 MUST 回退 `name`。

入参中除 `name` 及其同级别名以外的字段 MUST 被忽略，MUST NOT 参与输出。

系统 MUST NOT 输出 `apiVersion`、`kind`、`status` 或规格未定义的其他字段。

#### Scenario: 合法名称

- **WHEN** 入参为 `name: linux`
- **THEN** 输出只包含 `name`，取值为 `linux`

#### Scenario: 别名优先

- **WHEN** 入参同时提供 `name: linux` 与 `nameAlias: windows`
- **THEN** 输出取值为 `windows`

#### Scenario: 空别名回退

- **WHEN** 入参提供空的 `nameAlias` 与非空的 `name: linux`
- **THEN** 输出取值为 `linux`

#### Scenario: 未定义字段被忽略

- **WHEN** 入参除 `name` 外还包含 `namespace`、`kind` 等其他键
- **THEN** 输出不包含这些键

### Requirement: 小写归一

系统 MUST 在校验前把 `name` 去除首尾空白并转为小写，并 MUST 以小写结果作为校验与输出取值。

系统 MUST 接受大小写不同的合法取值，包括 `Linux`、`WINDOWS` 及其与首尾空白的组合。

#### Scenario: 首字母大写

- **WHEN** 入参为 `name: Linux`
- **THEN** 输出取值为 `linux`

#### Scenario: 全大写

- **WHEN** 入参为 `name: WINDOWS`
- **THEN** 输出取值为 `windows`

#### Scenario: 含首尾空白

- **WHEN** 入参为 `name: "  Linux  "`
- **THEN** 输出取值为 `linux`

### Requirement: name 为空时跳过渲染

系统 MUST 在 `name` 去除首尾空白后为空时输出空内容且不中断渲染，包括 `name` 缺失、为 `null`、为空字符串或只含空白的情况。

调用方 MUST 能把空输出识别为“该结构不生效”并跳过 `os` 字段。

#### Scenario: name 缺失

- **WHEN** 入参不含 `name` 且不含非空 `nameAlias`
- **THEN** 模板输出为空内容，渲染不中断

#### Scenario: name 为 null 或空字符串

- **WHEN** `name` 为 `null` 或 `""`
- **THEN** 模板输出为空内容，渲染不中断

#### Scenario: name 只含空白

- **WHEN** `name` 为只含空白的字符串
- **THEN** 模板输出为空内容，渲染不中断

### Requirement: 校验 name 枚举

系统 MUST 要求归一化后的 `name` 属于 `linux`、`windows`。

`name` 归一化后不在上述范围时 MUST 中断渲染，包括 `darwin`、`Linux 2` 等其他取值，以及布尔值、整数、map、list 等非 string 输入。

中断时的失败信息 MUST 由执行枚举校验的既有渲染能力产生并保留其自身前缀，MUST 包含字段名 `name` 与允许取值 `linux`、`windows`。

#### Scenario: 未知取值

- **WHEN** `name` 为 `darwin` 或 `linux2`
- **THEN** 渲染中断并返回错误，错误信息包含 `name` 与 `linux`、`windows`

#### Scenario: 不是 string

- **WHEN** `name` 为布尔值、整数、map 或 list
- **THEN** 渲染中断并返回错误，错误信息包含 `name` 与 `linux`、`windows`

## 非目标

- 不实现 `PodOS` 以外的其他结构，如 `PodSchedulingGate`、`PodResourceClaim`。
- 不负责父级 `os` 字段的字符串简写归一化，该归一化由调用方完成。
- 不做操作系统与容器镜像或节点标签的一致性校验。
