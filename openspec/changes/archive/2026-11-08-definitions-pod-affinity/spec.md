---
updated_at: "2026-11-08T14:28:28Z"
---

# PodAffinity 共享结构规格

## Purpose

为 Kubernetes `PodAffinity` 对象提供共享结构渲染入口，把父级传入的 `preferredDuringSchedulingIgnoredDuringExecution` 与 `requiredDuringSchedulingIgnoredDuringExecution` 按元素分别委托给对应的术语子模板，并按 API 字段顺序渲染为可嵌入的字段片段。

## ADDED Requirements

### Requirement: 渲染 PodAffinity 字段片段

系统 MUST 从入参 map 读取 `preferredDuringSchedulingIgnoredDuringExecution` 与 `requiredDuringSchedulingIgnoredDuringExecution`，并 MUST 按 Kubernetes API 字段顺序输出 `preferredDuringSchedulingIgnoredDuringExecution` 先于 `requiredDuringSchedulingIgnoredDuringExecution`。

系统 MUST 输出可作为单个 `PodAffinity` 内容的 YAML 字段片段，返回值 MUST 可被调用方解析为 map。

两个字段都无有效内容时，系统 MUST 返回空字符串，MUST NOT 输出空字段或空 map。

两个字段 MUST 保持输入顺序，每个有效元素 MUST 对应一项输出；系统 MUST NOT 在本层合并、去重或重排元素。

系统 MUST 只识别上述两个规范长键；同级 `<键名>Alias` 与短键 `preferred`、`required` MUST NOT 参与输出，短键归一化由父级 `definitions.affinity` 负责。

入参中除上述两个规范长键以外的字段 MUST 被忽略。系统 MUST NOT 输出 `status` 或规格未定义的其他字段。

#### Scenario: 两个字段同时提供

- **WHEN** 入参同时提供非空的 `preferredDuringSchedulingIgnoredDuringExecution` 与非空的 `requiredDuringSchedulingIgnoredDuringExecution`
- **THEN** 输出先包含 `preferredDuringSchedulingIgnoredDuringExecution`、后包含 `requiredDuringSchedulingIgnoredDuringExecution`

#### Scenario: 只提供一个字段

- **WHEN** 入参只提供两个字段中的一个
- **THEN** 输出只包含该字段

#### Scenario: 两个字段都为空

- **WHEN** 两个字段缺失，或都是空 array
- **THEN** 返回空字符串，不输出任何字段

#### Scenario: 短键与别名不被识别

- **WHEN** 入参只提供 `preferred`、`required`、`preferredDuringSchedulingIgnoredDuringExecutionAlias` 或 `requiredDuringSchedulingIgnoredDuringExecutionAlias`
- **THEN** 返回空字符串，不输出任何字段

#### Scenario: 未定义字段被忽略

- **WHEN** 入参除两个规范长键外还包含其他键
- **THEN** 输出不包含这些键

### Requirement: 委托术语子模板

`preferredDuringSchedulingIgnoredDuringExecution` 的每个元素 MUST 原样作为 `definitions.weightedPodAffinityTerm` 的入参；`requiredDuringSchedulingIgnoredDuringExecution` 的每个元素 MUST 原样作为 `definitions.podAffinityTerm` 的入参。

系统 MUST NOT 在本层校验、归一化、拆分、去重或去空元素内部字段；`weight`、`topologyKey`、`labelSelector`、`namespaceSelector`、`matchLabelKeys`、`namespaces` 等字段 MUST 原样传递给对应子模板。

对应子模板的返回值 MUST 可解析为单个 map；返回值无法解析时系统 MUST 中断渲染，错误信息 MUST 包含所属字段名与元素下标。

每个有效元素 MUST 产生一项输出；系统 MUST NOT 对子模板的输出再执行去重、合并或去空。

#### Scenario: 元素原样透传

- **WHEN** `preferredDuringSchedulingIgnoredDuringExecution` 的某个元素包含 `weight` 与术语字段
- **THEN** `definitions.weightedPodAffinityTerm` 收到的入参与该元素完全一致，本层不新增、删除或改写任何键

#### Scenario: 元素内部字段不处理

- **WHEN** 元素包含 `namespaceSelector`、`labelSelector`、`matchLabelKeys` 或 `namespaces`
- **THEN** 这些字段原样传递，本层不解析 `matchExpressions`、`matchFields` 或 `namespaces` 内部结构

#### Scenario: 子模板返回非法内容

- **WHEN** 对应子模板返回无法解析为 map 的内容
- **THEN** 渲染中断并返回错误

### Requirement: 输入类型与空元素边界

字段取值 MUST 为 array；取值不是 array 时 MUST 中断渲染，错误信息 MUST 包含所属字段名。

字段取值为空 array 时 MUST 跳过该字段，不产生输出。

元素 MUST 为 map；元素为 `null` 或空 map 时 MUST 跳过，不产生输出项。

元素为 string、数字、布尔或 array 时 MUST 中断渲染，错误信息 MUST 包含所属字段名与元素下标。

#### Scenario: 空数组跳过

- **WHEN** 两个字段都是空 array
- **THEN** 返回空字符串

#### Scenario: 空元素跳过

- **WHEN** 字段 array 包含 `null` 或空 map 元素
- **THEN** 输出不包含这些元素对应的条目

#### Scenario: 字段不是数组

- **WHEN** 任一字段取值为 map、string 或数字
- **THEN** 渲染中断并返回错误

#### Scenario: 元素类型非法

- **WHEN** 字段 array 的元素为 string、数字、布尔或 array
- **THEN** 渲染中断并返回错误

## 非目标

- 不实现 `definitions.weightedPodAffinityTerm` 与 `definitions.podAffinityTerm`。
- 不处理 `matchExpressions` 与 `matchFields`。
- 不处理元素内部字段的取值、归一化、校验与渲染。
- 不实现元素内部内容与子模板输出的去重、去空。
