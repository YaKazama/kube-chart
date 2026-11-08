---
updated_at: "2026-11-08T15:15:00Z"
---

# PodAffinity 共享结构规格（weightedPodAffinityTerm 上下文修正）

## MODIFIED Requirements

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

两个字段的每个有效元素 MUST 产生一项输出，输出顺序 MUST 与输入顺序一致；系统 MUST NOT 在本层合并、去重或重排元素。

对应子模板的返回值 MUST 可解析为单个 map；返回值无法解析时系统 MUST 中断渲染，错误信息 MUST 包含所属字段名与元素下标。

系统 MUST NOT 在本层校验、归一化或渲染元素内部术语字段的语义。

#### Scenario: preferred 元素归一化为两个键

- **WHEN** `preferredDuringSchedulingIgnoredDuringExecution` 的某个元素包含 `weight` 与术语字段
- **THEN** `definitions.weightedPodAffinityTerm` 收到的 map 只含 `weight` 与 `podAffinityTerm` 两个键

#### Scenario: 术语字段原样放入 podAffinityTerm

- **WHEN** 元素包含 `topologyKey`、`labelSelector`、`namespaceSelector`、`matchLabelKeys` 或 `namespaces`
- **THEN** 这些字段以原字段名与取值出现在 `podAffinityTerm` 下，本层不解析其内部结构

#### Scenario: 元素只有 weight

- **WHEN** 元素除 `weight` 外没有其他字段，也不含 `podAffinityTerm`
- **THEN** 渲染中断并返回错误，错误信息包含 `podAffinityTerm` 与元素下标

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

## ADDED Requirements

### Requirement: 校验 preferred 元素的 weight

`preferredDuringSchedulingIgnoredDuringExecution` 的每个有效元素 MUST 提供 `weight`。

系统 MUST 识别同级 `weightAlias`；非空 `weightAlias` MUST 参与取值，`weightAlias` 不得影响其他字段的归一化。

`weight` 取值 MUST 为 integer；`weight` 为 string、bool、map、array 或非整数数值时 MUST 中断渲染。

`weight` 为带引号的数字时 MUST 中断渲染，MUST NOT 按 integer 接受。

`weight` 缺失、为 `null` 或为空字符串时 MUST 中断渲染。

系统 MUST NOT 在本层校验 `weight` 的 1-100 取值范围。

失败信息 MUST 包含模板名、所属字段名与元素下标。

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

#### Scenario: weight 超出范围不中断

- **WHEN** 元素 `weight` 为 integer 且取值超出 1-100
- **THEN** 正常渲染，本层不做范围校验

#### Scenario: weightAlias 参与取值

- **WHEN** 元素同时含 `weight: 11` 与非空 `weightAlias: 22`
- **THEN** 子模板收到 `weight: 22`，且 `weightAlias` 不出现在 `podAffinityTerm` 下

## 非目标

- 不实现 `definitions.weightedPodAffinityTerm` 与 `definitions.podAffinityTerm`。
- 不处理术语字段的取值、归一化与校验。
- 不修改 `requiredDuringSchedulingIgnoredDuringExecution` 的透传行为。
