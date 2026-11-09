---
updated_at: "2026-11-09T13:33:26Z"
---

# LocalObjectReference 共享结构规格

## Purpose

新增共享结构能力 `definitions.localObjectReference`，把父级传入的单个引用上下文渲染为符合 Kubernetes `LocalObjectReference` 的 YAML 字段片段，并按 RFC 1035 校验引用名。

## ADDED Requirements

### Requirement: 渲染 LocalObjectReference 字段片段

系统 MUST 接受 map 输入，只读取 `name`，并输出仅包含 `name` 的 YAML 字段片段。

系统 MUST 输出可作为单个 `LocalObjectReference` 嵌入父级字段的片段；`name` MUST 以双引号标量输出。

系统 MUST 识别同级 `nameAlias`；非空 `nameAlias` MUST 优先于 `name`，别名缺失或为空时 MUST 回退 `name`。

入参中除 `name` 及其同级别名以外的字段 MUST 被忽略，MUST NOT 参与输出。

系统 MUST NOT 输出 `status`、`apiVersion`、`kind` 或规格未定义的其他字段。

#### Scenario: 合法名称

- **WHEN** 入参为 `name: web`
- **THEN** 输出 `name: "web"`，不包含其他字段

#### Scenario: 别名优先

- **WHEN** 入参同时提供 `name` 与取值不同的 `nameAlias`
- **THEN** 输出使用 `nameAlias` 的取值

#### Scenario: 空别名回退

- **WHEN** 入参提供空的 `nameAlias` 与非空的 `name`
- **THEN** 输出使用 `name` 的取值

#### Scenario: 未定义字段被忽略

- **WHEN** 入参除 `name` 外还包含其他键
- **THEN** 输出不包含这些键

### Requirement: name 为空时跳过渲染

系统 MUST 在 `name` 去除首尾空白后为空时输出空内容且不中断渲染，包括 `name` 缺失、为 `null`、为空字符串或只含空白的情况。

调用方 MUST 能把空输出识别为“该项不生效”并跳过该引用项。

#### Scenario: name 缺失

- **WHEN** 入参不含 `name` 且不含非空 `nameAlias`
- **THEN** 模板输出为空内容，渲染不中断

#### Scenario: name 为 null 或空字符串

- **WHEN** `name` 为 `null` 或 `""`
- **THEN** 模板输出为空内容，渲染不中断

#### Scenario: name 只含空白

- **WHEN** `name` 为只含空白的字符串
- **THEN** 模板输出为空内容，渲染不中断

### Requirement: 校验 name 的 RFC 1035 语法

系统 MUST 在 `name` 非空时按 RFC 1035 标签语法对完整取值做全量匹配，去除首尾空白后参与校验与输出。

`name` MUST 满足：长度 1 - 63 个字符；首字符 MUST 为小写字母；末字符 MUST 为小写字母或数字；其余字符只允许小写字母、数字与 `-`。

`name` 不是 string 时 MUST 中断渲染。

`name` 不符合 RFC 1035 语法时 MUST 中断渲染，失败信息 MUST 指明 `name` 与 RFC 1035 规则。

本模板自身产生的失败消息 MUST 以 `[definitions.localObjectReference]` 开头；委托既有能力完成校验时产生的失败 MUST 保留该能力自身的前缀。

#### Scenario: 最小与最大长度

- **WHEN** `name` 为单个小写字母或 63 个字符的合法名称
- **THEN** 校验通过并输出该名称

#### Scenario: 含首尾空白

- **WHEN** `name` 为 `" web "`
- **THEN** 校验通过并输出 `name: "web"`

#### Scenario: 大写或下划线

- **WHEN** `name` 为 `Web` 或 `web_app`
- **THEN** 渲染中断并返回错误

#### Scenario: 首尾字符非法

- **WHEN** `name` 以 `-` 开头、以 `-` 结尾或以数字开头
- **THEN** 渲染中断并返回错误

#### Scenario: 超出长度上限

- **WHEN** `name` 为 64 个字符
- **THEN** 渲染中断并返回错误

#### Scenario: 不是 string

- **WHEN** `name` 为 map、list、布尔值或整数
- **THEN** 渲染中断并返回错误

## 非目标

- 不实现 `ObjectReference`、`SecretReference`、`TypedLocalObjectReference` 或其他引用结构。
- 不负责父级数组的循环、条目合并、去重与顺序。
- 不校验引用对象是否真实存在，也不输出 `namespace`、`kind`、`apiVersion` 等引用限定字段。
