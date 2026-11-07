---
updated_at: "2026-11-07T16:37:22Z"
---

# NodeAffinity 共享结构规格

## Purpose

为 Kubernetes `NodeAffinity` 对象提供共享结构渲染入口，使父级已归一化的两个规范长键完成子项取值、字段包裹与子模板委托。

## ADDED Requirements

### Requirement: 顶层字段取值与输出顺序

系统 MUST 从入参 map 读取 `preferredDuringSchedulingIgnoredDuringExecution` 与 `requiredDuringSchedulingIgnoredDuringExecution` 两个规范长键。

系统 MUST 只识别上述两个规范长键；`preferred`、`required` 等短键以及两个键的同级 `<键名>Alias` MUST 被忽略，MUST NOT 参与取值或输出。

系统 MUST 按 Kubernetes API 字段顺序输出：`preferredDuringSchedulingIgnoredDuringExecution` 先于 `requiredDuringSchedulingIgnoredDuringExecution`。

字段无有效内容时 MUST NOT 输出该字段；两个字段都无有效内容时 MUST 输出空结果，MUST NOT 输出空 map 或占位结构。

系统 MUST 输出可嵌入 `affinity.nodeAffinity` 下的 YAML 字段片段。

#### Scenario: 两个字段同时提供

- **WHEN** 入参同时包含两个规范长键且取值均为非空 array
- **THEN** 输出按 `preferredDuringSchedulingIgnoredDuringExecution`、`requiredDuringSchedulingIgnoredDuringExecution` 顺序同时包含两个键

#### Scenario: 只提供 required

- **WHEN** 入参只包含非空的 `requiredDuringSchedulingIgnoredDuringExecution`
- **THEN** 输出只包含 `requiredDuringSchedulingIgnoredDuringExecution`，不出现 `preferredDuringSchedulingIgnoredDuringExecution`

#### Scenario: 字段为空

- **WHEN** `preferredDuringSchedulingIgnoredDuringExecution` 为空 array
- **THEN** 输出不包含 `preferredDuringSchedulingIgnoredDuringExecution`

#### Scenario: 两个字段都无有效内容

- **WHEN** 入参不含两个规范长键，或两者均为空 array
- **THEN** 系统输出空结果

#### Scenario: 短键被忽略

- **WHEN** 入参只提供 `preferred` 与 `required`
- **THEN** 系统输出空结果

#### Scenario: 同级别名被忽略

- **WHEN** 入参只提供 `preferredDuringSchedulingIgnoredDuringExecutionAlias`
- **THEN** 系统输出空结果

### Requirement: preferredDuringSchedulingIgnoredDuringExecution 委托

系统 MUST 逐项委托 `definitions.preferredSchedulingTerm` 渲染 `preferredDuringSchedulingIgnoredDuringExecution` 的每个 `PreferredSchedulingTerm`。

系统 MUST 为每项向下传递该项的 `weight` 与 `preference`；`preference` MUST 携带该项的 `matchExpressions` 与 `matchFields`。

系统 MUST 保持输入项顺序；每个输入项 MUST 在输出中对应一项，MUST NOT 合并、去重或重排。

系统 MUST NOT 校验 `weight` 的整数类型与 1 - 100 取值范围；取值存在且为标量时 MUST 以该取值向下传递，范围校验由 `definitions.preferredSchedulingTerm` 负责。

系统 MUST 识别 term 内的 `weightAlias`、`matchExpressionsAlias`、`matchFieldsAlias`；非空别名 MUST 优先于同名规范键，别名缺失或为空时 MUST 回退同名规范键。

单个 term 的 `matchExpressions` 与 `matchFields` 都为空时 MUST 仍委托子模板，MUST NOT 跳过该 term。

#### Scenario: 单项委托

- **WHEN** `preferredDuringSchedulingIgnoredDuringExecution` 含一项，带 `weight: 1`、`matchExpressions` 与 `matchFields`
- **THEN** 输出包含一项，其内容来自子模板返回值

#### Scenario: 多项保持顺序

- **WHEN** `preferredDuringSchedulingIgnoredDuringExecution` 含多项且 `weight` 各不相同
- **THEN** 输出项顺序与输入顺序一致

#### Scenario: weight 超出范围仍委托

- **WHEN** 某一项的 `weight` 为 `101`
- **THEN** 系统仍委托子模板，MUST NOT 因范围问题中断渲染

#### Scenario: 空匹配条件仍委托

- **WHEN** 某一项的 `matchExpressions` 与 `matchFields` 都为空
- **THEN** 系统仍委托子模板，输出仍包含对应项

#### Scenario: 子项别名优先

- **WHEN** 某一项同时提供 `weight` 与取值不同的 `weightAlias`
- **THEN** 传给子模板的 `weight` 取自 `weightAlias`

#### Scenario: 空子项别名回退

- **WHEN** 某一项提供空 `matchExpressionsAlias` 与非空的 `matchExpressions`
- **THEN** 传给子模板的 `preference.matchExpressions` 取自 `matchExpressions`

### Requirement: requiredDuringSchedulingIgnoredDuringExecution 委托

系统 MUST 把 `requiredDuringSchedulingIgnoredDuringExecution` 的 term array 包裹为 `nodeSelectorTerms` 对象后整体委托 `definitions.nodeSelector`。

传给 `definitions.nodeSelector` 的 map MUST 只包含 `nodeSelectorTerms` 一个键，其元素为 `requiredDuringSchedulingIgnoredDuringExecution` 的各个 term。

每个 term MUST 以 `matchExpressions`、`matchFields` 作为元素字段向下传递；两者都为空时 MUST 仍传递该 term，MUST NOT 剔除。

系统 MUST 保持 term 顺序；每个输入 term MUST 在 `nodeSelectorTerms` 中对应一个元素，MUST NOT 合并、去重或重排。

系统 MUST 识别 term 内的 `matchExpressionsAlias`、`matchFieldsAlias`；非空别名 MUST 优先于同名规范键，别名缺失或为空时 MUST 回退同名规范键。

`definitions.nodeSelector` MUST 从 `nodeSelectorTerms` 键取值并渲染 `NodeSelector`；本层 MUST NOT 渲染 `nodeSelectorTerms` 内部结构。

#### Scenario: 包裹为 nodeSelectorTerms

- **WHEN** `requiredDuringSchedulingIgnoredDuringExecution` 含一个 term
- **THEN** 传给 `definitions.nodeSelector` 的 map 只含 `nodeSelectorTerms`，且该数组含一个元素

#### Scenario: 多项保持顺序

- **WHEN** `requiredDuringSchedulingIgnoredDuringExecution` 含多个 term
- **THEN** `nodeSelectorTerms` 元素顺序与输入一致

#### Scenario: 空匹配条件仍传递

- **WHEN** 某一 term 的 `matchExpressions` 与 `matchFields` 都为空
- **THEN** `nodeSelectorTerms` 仍包含该 term

#### Scenario: 子项别名优先

- **WHEN** 某一 term 同时提供 `matchFields` 与取值不同的 `matchFieldsAlias`
- **THEN** `nodeSelectorTerms` 中该 term 的 `matchFields` 取自 `matchFieldsAlias`

### Requirement: NodeAffinity 输入失败边界

两个规范长键的取值 MUST 为 array；取值存在且不是 array 时 MUST 中断渲染，错误信息 MUST 包含 `[definitions.nodeAffinity]` 前缀与对应字段路径。

array 元素 MUST 为 map；存在非 map 元素时 MUST 中断渲染，错误信息 MUST 包含 `[definitions.nodeAffinity]` 前缀、对应字段路径与元素下标。

`preferredDuringSchedulingIgnoredDuringExecution` 每项的 `weight` MUST 存在且非空；缺失、`null` 或空字符串时 MUST 中断渲染，错误信息 MUST 包含 `[definitions.nodeAffinity]` 前缀与该项的完整字段路径。

`weight` 的取值 MUST 为单个标量；取值为 map 或 array 时 MUST 中断渲染，错误信息 MUST 包含 `[definitions.nodeAffinity]` 前缀与该项的 `weight` 字段路径。

term 的 `matchExpressions`、`matchFields` 取值 MUST 为 array；取值存在且不是 array 时 MUST 中断渲染，错误信息 MUST 包含 `[definitions.nodeAffinity]` 前缀与对应字段路径。

子模板返回值无法解析为 YAML 时 MUST 中断渲染，错误信息 MUST 包含 `[definitions.nodeAffinity]` 前缀与对应字段名。

系统 MUST NOT 校验子模板返回值的内部字段与结构。

#### Scenario: 规范长键不是 array

- **WHEN** `preferredDuringSchedulingIgnoredDuringExecution` 取值为 map
- **THEN** 渲染中断，错误信息包含 `[definitions.nodeAffinity]` 与 `preferredDuringSchedulingIgnoredDuringExecution`

#### Scenario: term 不是 map

- **WHEN** `requiredDuringSchedulingIgnoredDuringExecution` 的某个元素取值为字符串
- **THEN** 渲染中断，错误信息包含 `[definitions.nodeAffinity]`、`requiredDuringSchedulingIgnoredDuringExecution` 与元素下标

#### Scenario: weight 缺失

- **WHEN** `preferredDuringSchedulingIgnoredDuringExecution` 的某一项不含 `weight`
- **THEN** 渲染中断，错误信息包含 `[definitions.nodeAffinity]` 与该项的 `weight` 字段路径

#### Scenario: weight 为空字符串

- **WHEN** `preferredDuringSchedulingIgnoredDuringExecution` 的某一项 `weight` 为空字符串
- **THEN** 渲染中断，错误信息包含 `[definitions.nodeAffinity]` 与该项的 `weight` 字段路径

#### Scenario: weight 不是标量

- **WHEN** `preferredDuringSchedulingIgnoredDuringExecution` 的某一项 `weight` 取值为 map 或 array
- **THEN** 渲染中断，错误信息包含 `[definitions.nodeAffinity]` 与该项的 `weight` 字段路径

#### Scenario: 匹配条件不是 array

- **WHEN** `preferredDuringSchedulingIgnoredDuringExecution` 的某一项 `matchExpressions` 取值为 map
- **THEN** 渲染中断，错误信息包含 `[definitions.nodeAffinity]` 与该项的 `matchExpressions` 字段路径

#### Scenario: 子模板返回不可解析内容

- **WHEN** 被委托的子模板返回文本不是合法 YAML
- **THEN** 渲染中断，错误信息包含 `[definitions.nodeAffinity]` 与对应字段名

## 非目标

- 不实现 `definitions.preferredSchedulingTerm`、`definitions.nodeSelector`、`definitions.nodeSelectorTerm`、`definitions.nodeSelectorRequirement` 及任何被委托结构的独立模板。
- 不校验 `weight` 的整数类型与 1 - 100 取值范围；仅将非标量取值作为失败边界拒绝。
- 不解析、渲染或校验 `matchExpressions`、`matchFields` 内部的字符串简写与 `NodeSelectorRequirement` 结构。
- 不处理 `NodeAffinity` 之外的其他字段，不引入 `nodeSelector` 等额外顶层键。
- 不识别短键 `preferred`、`required`，也不在本层做短键到规范长键的归一化。
- 不修改 `definitions.affinity` 的既有委托行为与 `templates/api-resources/Definitions/` 下既有模板。
