---
updated_at: "2026-11-09T04:34:03Z"
---

# PodAntiAffinity 共享结构规格

## Purpose

为 Kubernetes `PodAntiAffinity` 对象提供共享结构渲染入口，把父级传入的 `preferredDuringSchedulingIgnoredDuringExecution` 与 `requiredDuringSchedulingIgnoredDuringExecution` 按元素委托给既有术语子模板，并按 API 字段顺序渲染为可嵌入的字段片段。

## ADDED Requirements

### Requirement: 渲染 PodAntiAffinity 字段片段

系统 MUST 从入参 map 读取 `preferredDuringSchedulingIgnoredDuringExecution` 与 `requiredDuringSchedulingIgnoredDuringExecution`，并 MUST 按 Kubernetes API 字段顺序输出 `preferredDuringSchedulingIgnoredDuringExecution` 先于 `requiredDuringSchedulingIgnoredDuringExecution`。

系统 MUST 输出可作为单个 `PodAntiAffinity` 内容的 YAML 字段片段，返回值 MUST 可被调用方解析为 map；返回值 MUST NOT 包含 `podAntiAffinity` 键本身。

两个字段都无有效内容时，系统 MUST 返回空字符串，MUST NOT 输出空字段或空 map。

每个有效元素 MUST 对应一项输出，输出顺序 MUST 与输入顺序一致；系统 MUST NOT 在本层合并、去重或重排元素。

系统 MUST 只识别上述两个规范长键；同级 `<键名>Alias` 与短键 `preferred`、`required` MUST NOT 参与输出，短键归一化由父级 `definitions.affinity` 负责。

入参中除上述两个规范长键以外的字段 MUST 被忽略。系统 MUST NOT 输出 `status` 或规格未定义的其他字段。

本层产生的失败信息 MUST 包含模板名 `definitions.podAntiAffinity` 与所属字段名；失败涉及具体元素时 MUST 包含元素下标。委托子模板产生的失败信息由该子模板负责；系统 MUST NOT 捕获或改写这些消息，MUST 原样传播。

#### Scenario: 两个字段同时提供

- **WHEN** 入参同时提供非空的 `preferredDuringSchedulingIgnoredDuringExecution` 与非空的 `requiredDuringSchedulingIgnoredDuringExecution`
- **THEN** 输出先包含 `preferredDuringSchedulingIgnoredDuringExecution`、后包含 `requiredDuringSchedulingIgnoredDuringExecution`

#### Scenario: 只提供一个字段

- **WHEN** 入参只提供两个字段中的一个
- **THEN** 输出只包含该字段

#### Scenario: 两个字段都为空

- **WHEN** 两个字段缺失，或都是空 array
- **THEN** 返回空字符串，不输出任何字段

#### Scenario: 短键与同级别名不被识别

- **WHEN** 入参只提供 `preferred`、`required`、`preferredDuringSchedulingIgnoredDuringExecutionAlias` 或 `requiredDuringSchedulingIgnoredDuringExecutionAlias`
- **THEN** 返回空字符串，不输出任何字段

#### Scenario: 未定义字段被忽略

- **WHEN** 入参除两个规范长键外还包含其他键
- **THEN** 输出不包含这些键

### Requirement: 委托术语子模板

`requiredDuringSchedulingIgnoredDuringExecution` 的每个元素 MUST 原样作为 `definitions.podAffinityTerm` 的入参。

`preferredDuringSchedulingIgnoredDuringExecution` 的每个有效元素 MUST 先归一化为只含 `weight` 与 `podAffinityTerm` 两个键的 map，再作为 `definitions.weightedPodAffinityTerm` 的入参。

归一化时，元素中除 `weight` 及其同级 `weightAlias` 外的其余字段 MUST 原样放入 `podAffinityTerm`，字段名与取值 MUST NOT 被改写。

`weightAlias` MUST NOT 出现在 `podAffinityTerm` 下。

元素本身已含 `podAffinityTerm` 键时，其余字段 MUST 合并进该 `podAffinityTerm` map，MUST NOT 再嵌套一层。

合并时 MUST 以元素已有的 `podAffinityTerm` 为主：同名键冲突时 MUST 保留 `podAffinityTerm` 内已有的值。

元素已有的 `podAffinityTerm` 为空 map 时 MUST 按 map 处理并继续合并其余字段；`podAffinityTerm` 缺失时 MUST 以空 map 为合并起点。

元素已有的 `podAffinityTerm` 不是 map 时 MUST 中断渲染，错误信息 MUST 包含所属字段名与元素下标。

归一化后的 `podAffinityTerm` MUST 为非空 map；合并结果为空 map 时 MUST 中断渲染，错误信息 MUST 包含所属字段名与元素下标。

系统 MUST NOT 省略 `podAffinityTerm` 键，MUST NOT 向 `definitions.weightedPodAffinityTerm` 传递空 map。

对应子模板的返回值 MUST 可解析为单个 map；返回值无法解析时系统 MUST 中断渲染，错误信息 MUST 包含所属字段名与元素下标。

系统 MUST NOT 在本层校验、归一化或渲染元素内部术语字段的语义。

#### Scenario: preferred 元素归一化为两个键

- **WHEN** `preferredDuringSchedulingIgnoredDuringExecution` 的某个元素包含 `weight` 与术语字段
- **THEN** `definitions.weightedPodAffinityTerm` 收到的 map 只含 `weight` 与 `podAffinityTerm` 两个键

#### Scenario: 术语字段原样放入 podAffinityTerm

- **WHEN** 元素包含 `topologyKey`、`labelSelector`、`namespaceSelector`、`matchLabelKeys`、`mismatchLabelKeys` 或 `namespaces`
- **THEN** 这些字段以原字段名与取值出现在 `podAffinityTerm` 下，本层不解析其内部结构

#### Scenario: 元素只有 weight

- **WHEN** 元素除 `weight` 外没有其他字段，也不含 `podAffinityTerm`
- **THEN** 渲染中断并返回错误，错误信息包含 `podAntiAffinity`、`podAffinityTerm` 与元素下标

#### Scenario: 已有 podAffinityTerm 为空 map 且无其他字段

- **WHEN** 元素只含 `weight` 与 `podAffinityTerm: {}`
- **THEN** 渲染中断并返回错误，错误信息包含 `podAffinityTerm` 与元素下标

#### Scenario: 合并进已有 podAffinityTerm

- **WHEN** 元素同时含 `weight`、`topologyKey` 与 `podAffinityTerm` map
- **THEN** `topologyKey` 出现在该 `podAffinityTerm` 内，层级不增加

#### Scenario: 同名键以 podAffinityTerm 为准

- **WHEN** 元素含 `topologyKey: a` 且 `podAffinityTerm` 内含 `topologyKey: b`
- **THEN** 输出的 `podAffinityTerm.topologyKey` 为 `b`

#### Scenario: 已有 podAffinityTerm 为空 map

- **WHEN** 元素含 `podAffinityTerm: {}` 与 `topologyKey`
- **THEN** 该 `topologyKey` 被合并进 `podAffinityTerm`

#### Scenario: podAffinityTerm 不是 map

- **WHEN** 元素含非 map 的 `podAffinityTerm` 取值
- **THEN** 渲染中断并返回错误

#### Scenario: required 元素原样传递

- **WHEN** `requiredDuringSchedulingIgnoredDuringExecution` 的某个元素包含术语字段
- **THEN** `definitions.podAffinityTerm` 收到的入参与该元素完全一致，本层不新增、删除或改写任何键

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

### Requirement: 校验 preferred 元素的 weight

`preferredDuringSchedulingIgnoredDuringExecution` 的每个有效元素 MUST 提供 `weight`。

系统 MUST 识别同级 `weightAlias`；非空 `weightAlias` MUST 参与取值，`weightAlias` 不得影响其他字段的归一化。

`weight` 取值 MUST 为 integer；`weight` 为 string、bool、map、array 或非整数数值时 MUST 中断渲染。

`weight` 为带引号的数字时 MUST 中断渲染，MUST NOT 按 integer 接受。

`weight` 缺失、为 `null` 或为空字符串时 MUST 中断渲染。

本层失败信息 MUST 包含模板名 `definitions.podAntiAffinity`、所属字段名与元素下标。

系统 MUST NOT 在本层校验 `weight` 的 1-100 取值范围；归一化后的 `weight` MUST 原样交由 `definitions.weightedPodAffinityTerm`，该依赖自身的 1-100 闭区间校验 MUST 保持生效，取值超出时渲染 MUST 中断，失败信息由该依赖层负责。

#### Scenario: weight 合法

- **WHEN** 元素提供 integer 形态的 `weight`
- **THEN** 正常渲染，`definitions.weightedPodAffinityTerm` 收到该整数值

#### Scenario: weight 缺失

- **WHEN** 元素不含 `weight` 与 `weightAlias`
- **THEN** 渲染中断并返回错误

#### Scenario: weight 为 null 或空字符串

- **WHEN** 元素 `weight` 为 `null` 或 `""`
- **THEN** 渲染中断并返回错误

#### Scenario: weight 为带引号的数字

- **WHEN** 元素 `weight` 为 `"11"`
- **THEN** 渲染中断并返回错误

#### Scenario: weight 为非数值类型

- **WHEN** 元素 `weight` 为 bool、map 或 array
- **THEN** 渲染中断并返回错误

#### Scenario: weight 为浮点数

- **WHEN** 元素 `weight` 为 `1.5` 等非整数数值
- **THEN** 渲染中断并返回错误

#### Scenario: weight 超出范围由依赖层中断

- **WHEN** 元素 `weight` 为 integer 且取值超出 1-100
- **THEN** 本层不执行范围校验，渲染在 `definitions.weightedPodAffinityTerm` 处中断并返回错误

#### Scenario: weightAlias 参与取值

- **WHEN** 元素同时含 `weight: 11` 与非空 `weightAlias: 22`
- **THEN** 子模板收到 `weight: 22`，且 `weightAlias` 不出现在 `podAffinityTerm` 下

## 非目标

- 不实现 `definitions.weightedPodAffinityTerm` 与 `definitions.podAffinityTerm`。
- 不实现 `preferred`、`required` 短键归一化。
- 不处理元素内部术语字段的取值、归一化与校验。
- 不校验 `weight` 的 1-100 取值范围；该范围由 `definitions.weightedPodAffinityTerm` 负责。
- 不修改 `definitions.podAffinity` 及其私有辅助模板的可观察行为。
