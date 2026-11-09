---
updated_at: "2026-11-09T16:56:12Z"
---

# base.string.normalize 规格

## Purpose

新增 `base.string.normalize`，把 `include "base.get"` 返回的 YAML 序列化标量文本还原为真实 string 值，供 string 分支的调用方继续使用。

## ADDED Requirements

### Requirement: 字符串标量解码

系统 MUST 把入参 string 按单个 YAML 标量解码，并在解码结果为 string 时返回该值本身，不改变其内容、首尾空白或内部换行。入参 MUST 为 `include` 输出的原始文本，调用方不得预先改写。

#### Scenario: 解码普通标量与引号标量

- **WHEN** 入参为 `gpu`、`hello`、`"on"`、`'yes'`、`"007"` 或 `"a: b"` 这类 YAML 序列化标量
- **THEN** 返回对应的字面值 `gpu`、`hello`、`on`、`yes`、`007`、`a: b`

#### Scenario: 保留首尾空白

- **WHEN** 入参为 `'  spaced  '` 或 `'   '` 这类引号包裹且含首尾空白的标量
- **THEN** 分别返回 `  spaced  ` 与 `   `，保留首尾空白

#### Scenario: 解码多行标量

- **WHEN** 入参为块标量形态（以 `|` 或 `>` 起始并含后续缩进行）
- **THEN** 返回解码后的多行内容，结果不含 `|`、`>` 指示符，换行与折叠按 YAML 语义保留

### Requirement: 空输入返回空字符串

系统 MUST 在入参为空字符串或其解码结果为 `null` 时返回空字符串，不视为错误。

#### Scenario: 空输入

- **WHEN** 入参为空字符串、`null`、`~` 或其他解码为 `null` 的文本
- **THEN** 返回空字符串，渲染不中断

### Requirement: 非法入参中断渲染

系统 MUST 在入参不是 string、入参无法解析为 YAML 标量，或解码结果不是 string 时中断渲染，并以本模板标识产出失败消息。

#### Scenario: 入参不是 string 类型

- **WHEN** 调用方传入的不是 string 值，例如 map 或 list
- **THEN** 渲染中断，并产生带 `[base.string.normalize]` 前缀且指明实际类型的消息

#### Scenario: 解析失败

- **WHEN** 入参为无法解析为单个标量的文本，例如 `a: b` 或 `- x`
- **THEN** 渲染中断，并产生带 `[base.string.normalize]` 前缀的消息

#### Scenario: 解码结果不是 string

- **WHEN** 入参为布尔、数值、map 或 list 形态的 YAML 文本
- **THEN** 渲染中断，并产生带 `[base.string.normalize]` 前缀且指明实际类型的消息

## 非目标

- 不做 `trim`、空白归一或其他内容改写。
- 不解析 map、array 结构，也不代为调用 `fromYamlArray`。
- 不校验业务格式、枚举或长度。
- 不替代 `base.get` 的取值、别名、数据源优先级与合并能力。
- 不修改 `base.string.verify`。
- 不承担空值渲染；需要输出 `key: ""` 时由调用方选用既有能力。
- 不改造存量 `SYS.YAML_QUOTED` 调用点。
