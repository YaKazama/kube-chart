---
updated_at: "2026-11-09T05:21:55Z"
---

# PodAffinity 与 PodAntiAffinity 二级模板失败消息前缀规格

## ADDED Requirements

### Requirement: 二级模板失败消息使用自身模板名

`definitions.podAffinity` 与 `definitions.podAntiAffinity` 两个结构族下共 6 个二级模板（各自的 `termList`、`weightedTermList`、`weightedTerm`）产生的每条失败消息 MUST 使用产生该消息的二级模板的完整模板名作为前缀。

失败消息格式 MUST 为 `[模板名] 字段路径: 错误原因`；`字段路径` MUST 包含所属字段名，失败涉及具体元素时 MUST 包含该元素的数组下标。

失败消息的字段路径与错误原因文本 MUST 保持与修正前一致，本 change MUST NOT 改变任何失败条件、失败判定顺序或触发失败的输入。

`definitions.podAffinity` 与 `definitions.podAntiAffinity` 两个一级模板 MUST NOT 为二级模板产生的失败消息提供前缀，也 MUST NOT 捕获、包装或改写二级模板的失败消息。

两个一级模板自身产生的失败消息（若存在）MUST 继续使用一级模板名作为前缀。

依赖层（`base.*`、`definitions.podAffinityTerm`、`definitions.weightedPodAffinityTerm`）产生的失败消息 MUST 保持各自模板前缀，本层 MUST NOT 改写。

#### Scenario: 术语数组字段取值不是 array

- **WHEN** `requiredDuringSchedulingIgnoredDuringExecution` 或 `preferredDuringSchedulingIgnoredDuringExecution` 的取值不是 array
- **THEN** 失败消息前缀为产生它的 `termList` 或 `weightedTermList` 的完整模板名，消息体包含字段名与 `must be array type`

#### Scenario: 数组元素不是 map

- **WHEN** 数组元素为 string、数字、布尔或 array
- **THEN** 失败消息前缀为对应 `termList` 或 `weightedTermList` 的完整模板名，消息体包含字段名、元素下标与 `must be map type`

#### Scenario: 被委托模板返回非法 YAML

- **WHEN** 被委托的术语子模板返回值无法解析为 map
- **THEN** 失败消息前缀为对应 `termList` 或 `weightedTermList` 的完整模板名，消息体包含字段名、元素下标与 `returned invalid YAML`

#### Scenario: preferred 元素缺少 weight

- **WHEN** `preferred` 元素缺失 `weight` 与 `weightAlias`，或其值为 `null`、空字符串
- **THEN** 失败消息前缀为对应 `weightedTerm` 的完整模板名，消息体包含元素下标与 `weight: required field is missing or empty`

#### Scenario: preferred 元素 weight 形态非法

- **WHEN** `preferred` 元素的 `weight` 不是 integer 形态
- **THEN** 失败消息前缀为对应 `weightedTerm` 的完整模板名，消息体包含元素下标与 `weight: must be integer type`

#### Scenario: preferred 元素 podAffinityTerm 非法

- **WHEN** `preferred` 元素的 `podAffinityTerm` 不是 map，或合并后为空 map
- **THEN** 失败消息前缀为对应 `weightedTerm` 的完整模板名，消息体包含元素下标与 `podAffinityTerm:` 失败原因

#### Scenario: 依赖层失败消息不被改写

- **WHEN** 失败由 `base.*`、`definitions.podAffinityTerm` 或 `definitions.weightedPodAffinityTerm` 产生
- **THEN** 失败消息保持该依赖层自身的模板名前缀

#### Scenario: 成功输出保持不变

- **WHEN** 入参不触发任何失败
- **THEN** 两个一级模板输出的字段片段与修正前逐字节一致

## MODIFIED Requirements

### Requirement: 渲染 PodAntiAffinity 字段片段

系统 MUST 从入参 map 读取 `preferredDuringSchedulingIgnoredDuringExecution` 与 `requiredDuringSchedulingIgnoredDuringExecution`，并 MUST 按 Kubernetes API 字段顺序输出 `preferredDuringSchedulingIgnoredDuringExecution` 先于 `requiredDuringSchedulingIgnoredDuringExecution`。

系统 MUST 输出可作为单个 `PodAntiAffinity` 内容的 YAML 字段片段，返回值 MUST 可被调用方解析为 map；返回值 MUST NOT 包含 `podAntiAffinity` 键本身。

两个字段都无有效内容时，系统 MUST 返回空字符串，MUST NOT 输出空字段或空 map。

每个有效元素 MUST 对应一项输出，输出顺序 MUST 与输入顺序一致；系统 MUST NOT 在本层合并、去重或重排元素。

系统 MUST 只识别上述两个规范长键；同级 `<键名>Alias` 与短键 `preferred`、`required` MUST NOT 参与输出，短键归一化由父级 `definitions.affinity` 负责。

入参中除上述两个规范长键以外的字段 MUST 被忽略。系统 MUST NOT 输出 `status` 或规格未定义的其他字段。

失败信息 MUST 使用产生该消息的命名模板的完整模板名作为前缀；字段路径 MUST 包含所属字段名，失败涉及具体元素时 MUST 包含元素下标。委托子模板产生的失败信息由该子模板负责；系统 MUST NOT 捕获或改写这些消息，MUST 原样传播。

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

### Requirement: 校验 preferred 元素的 weight

`preferredDuringSchedulingIgnoredDuringExecution` 的每个有效元素 MUST 提供 `weight`。

系统 MUST 识别同级 `weightAlias`；非空 `weightAlias` MUST 参与取值，`weightAlias` 不得影响其他字段的归一化。

`weight` 取值 MUST 为 integer；`weight` 为 string、bool、map、array 或非整数数值时 MUST 中断渲染。

`weight` 为带引号的数字时 MUST 中断渲染，MUST NOT 按 integer 接受。

`weight` 缺失、为 `null` 或为空字符串时 MUST 中断渲染。

失败信息 MUST 使用产生该消息的命名模板的完整模板名作为前缀，并 MUST 包含所属字段名与元素下标。

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

- 不改变 `definitions.podAffinity`、`definitions.podAntiAffinity` 的成功输出行为。
- 不重构或合并 6 个二级模板的逻辑。
- 不新增或删除任何 `define`。
- 不修正依赖层、`definitions.affinity` 或缺省能力的失败消息。
