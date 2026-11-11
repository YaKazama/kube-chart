---
updated_at: "2026-11-11T12:44:38Z"
---

# NodeSelector 共享结构规格

## Purpose

为 Kubernetes `NodeSelector` 对象提供共享结构渲染入口，把父级已归一化的 `NodeSelectorTerm` 数组逐项委托 `definitions.nodeSelectorTerm`，并按 NodeSelector 结构输出可嵌入 `requiredDuringSchedulingIgnoredDuringExecution` 的字段片段。

## ADDED Requirements

### Requirement: 渲染 NodeSelector 字段片段

系统 MUST 从入参 map 读取 `nodeSelectorTerms`，并输出只包含 `nodeSelectorTerms` 一个字段的 YAML 字段片段，返回值 MUST 可以被调用方解析为 map。

系统 MUST 识别 `nodeSelectorTerms` 的同级 `nodeSelectorTermsAlias`；非空别名 MUST 优先于同名规范键，别名缺失或为空时 MUST 回退同名规范键。

入参中除 `nodeSelectorTerms` 及其同级别名以外的字段 MUST 被忽略，MUST NOT 参与输出。

系统 MUST NOT 输出 `status` 或规格未定义的其他字段。

#### Scenario: 单项渲染

- **WHEN** 入参提供含一项有效 term 的 `nodeSelectorTerms`
- **THEN** 输出只包含 `nodeSelectorTerms`，且该数组含一项

#### Scenario: 多项保持顺序

- **WHEN** 入参提供顺序为 A、B、C 的三项有效 term
- **THEN** 输出 `nodeSelectorTerms` 的元素顺序为 A、B、C

#### Scenario: 别名优先

- **WHEN** 入参同时提供 `nodeSelectorTerms` 与取值不同的非空 `nodeSelectorTermsAlias`
- **THEN** 输出使用 `nodeSelectorTermsAlias` 的取值

#### Scenario: 未定义字段被忽略

- **WHEN** 入参除 `nodeSelectorTerms` 外还包含其他键
- **THEN** 输出不包含这些键

#### Scenario: 可作为硬性节点亲和性的值

- **WHEN** 父级把已归一化的 term 数组以 `nodeSelectorTerms` 传入
- **THEN** 返回值可直接作为 `requiredDuringSchedulingIgnoredDuringExecution` 的值解析为 `NodeSelector` map

### Requirement: 校验 nodeSelectorTerms 输入

`nodeSelectorTerms` MUST 为 `NodeSelectorTerm` 数组，且在 NodeSelector 结构中 MUST 有内容。

`nodeSelectorTerms` 缺失、为 YAML `null`、为空字符串或为空数组时 MUST 中断渲染。

`nodeSelectorTerms` 不是数组时 MUST 中断渲染。

系统 MUST 只接受父级已归一化的 map 数组，MUST NOT 解析 string 简写。

数组元素不是 map 时 MUST 中断渲染。

#### Scenario: 缺失或为空

- **WHEN** 入参不含 `nodeSelectorTerms`，或其值为 YAML `null`、空字符串、空数组
- **THEN** 渲染中断，失败消息以 `[definitions.nodeSelector]` 开头

#### Scenario: 不是数组

- **WHEN** `nodeSelectorTerms` 为 map、字符串或数字
- **THEN** 渲染中断，失败消息以 `[definitions.nodeSelector]` 开头

#### Scenario: 元素不是 map

- **WHEN** 数组元素为字符串、数字或布尔值
- **THEN** 渲染中断，失败消息包含 `nodeSelectorTerms` 与条目下标

#### Scenario: 不解析字符串简写

- **WHEN** 数组元素为 `a = b` 这类 string 简写
- **THEN** 渲染中断，MUST NOT 按简写解析为 term

### Requirement: 逐项委托 definitions.nodeSelectorTerm

系统 MUST 把 `nodeSelectorTerms` 的每个元素按 map 形态传递给 `definitions.nodeSelectorTerm` 处理并回收其结果。

系统 MUST 按输入顺序处理与收集，MUST NOT 合并、去重或重排。

系统 MUST NOT 在本层解析或校验 `matchExpressions`、`matchFields` 的内部结构。

`definitions.nodeSelectorTerm` 返回空内容时，该项 MUST NOT 并入输出列表。

`definitions.nodeSelectorTerm` 返回非法 YAML 时 MUST 中断渲染。

收集结果为空数组时 MUST 中断渲染。

#### Scenario: 委托并回收

- **WHEN** 每个 term 都渲染出非空内容
- **THEN** 输出 `nodeSelectorTerms` 的项数等于输入项数，且每项内容来自对应 term 的委托结果

#### Scenario: 空内容项被丢弃

- **WHEN** 部分 term 渲染出空内容、其余 term 渲染出非空内容
- **THEN** 输出只包含非空内容的 term，且保持这些 term 的相对顺序

#### Scenario: 收集结果为空

- **WHEN** 所有 term 的委托结果均为空内容，例如 `nodeSelectorTerms: [{}]`
- **THEN** 渲染中断，失败消息以 `[definitions.nodeSelector]` 开头

#### Scenario: 子模板返回非法 YAML

- **WHEN** `definitions.nodeSelectorTerm` 的返回值无法解析为 YAML
- **THEN** 渲染中断，失败消息包含 `nodeSelectorTerms` 与条目下标

### Requirement: 失败消息归属

本模板自身产生的失败消息 MUST 使用 `[definitions.nodeSelector]` 前缀。

针对单个条目的失败消息 MUST 携带 `nodeSelectorTerms[<index>]` 路径。

`definitions.nodeSelectorTerm` 产生的失败消息 MUST 保持其自身前缀与字段路径，本模板 MUST NOT 改写或追加。

#### Scenario: 本模板失败

- **WHEN** `nodeSelectorTerms` 缺失、为空数组或不是数组
- **THEN** 失败消息以 `[definitions.nodeSelector]` 开头

#### Scenario: 条目失败

- **WHEN** `nodeSelectorTerms` 的某个元素不是 map，或其委托结果无法解析为 YAML
- **THEN** 失败消息以 `[definitions.nodeSelector]` 开头并包含 `nodeSelectorTerms[<index>]`

#### Scenario: 子模板失败

- **WHEN** `definitions.nodeSelectorTerm` 因 term 内部结构非法而中断
- **THEN** 失败消息以 `[definitions.nodeSelectorTerm]` 开头，不出现 `[definitions.nodeSelector]` 前缀

## 非目标

- 不修改 `definitions.nodeAffinity`、`definitions.nodeSelectorTerm` 及其他既有模板。
- 不处理 `definitions.affinity` 中 `nodeAffinity` 之外的字段。
- 不新增或修改任何 `base.*` 公共能力模板。
- 不输出 `status`。
