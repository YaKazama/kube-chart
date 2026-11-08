---
updated_at: "2026-11-08T17:10:57Z"
---

# PreferredSchedulingTerm preference 必填规格

## MODIFIED Requirements

### Requirement: 渲染 PreferredSchedulingTerm 字段片段

系统 MUST 从入参 map 读取 `weight` 与 `preference`，并按 Kubernetes API 字段顺序输出 `weight` 先于 `preference`。

系统 MUST 输出可作为 `preferredDuringSchedulingIgnoredDuringExecution` 单个元素的 YAML 字段片段。

`weight` 与 `preference` 均为必填字段，输出 MUST 同时包含两者。

系统 MUST 识别 `weight`、`preference` 的同级 `<键名>Alias`；非空别名 MUST 优先于同名规范键，别名缺失或为空时 MUST 回退同名规范键。

入参中除 `weight`、`preference` 及其同级别名以外的字段 MUST 被忽略，MUST NOT 参与输出。

系统 MUST NOT 输出 `status` 或规格未定义的其他字段。

#### Scenario: weight 与 preference 同时提供

- **WHEN** 入参同时提供合法的 `weight` 与非空的 `preference`
- **THEN** 输出同时包含 `weight` 与 `preference` 两个字段，`weight` 在前

#### Scenario: 只提供 weight

- **WHEN** 入参只提供合法的 `weight`，不含 `preference` 及其同级别名
- **THEN** 渲染中断并返回错误，错误信息包含 `preference`

#### Scenario: preference 为空

- **WHEN** `preference` 缺失、为 `null` 或为空 map
- **THEN** 渲染中断并返回错误，错误信息包含 `preference`

#### Scenario: 别名优先

- **WHEN** 入参同时提供 `weight` 与取值不同的 `weightAlias`
- **THEN** 输出使用 `weightAlias` 的取值

#### Scenario: 空别名回退

- **WHEN** 入参提供空的 `preferenceAlias` 与非空的 `preference`
- **THEN** 输出使用 `preference` 的取值

#### Scenario: 未定义字段被忽略

- **WHEN** 入参除 `weight` 与 `preference` 外还包含其他键
- **THEN** 输出不包含这些键

### Requirement: 校验 weight

系统 MUST 要求 `weight` 存在且为 1 - 100 闭区间内的整数。

`weight` 缺失、为 `null` 或为空字符串时 MUST 中断渲染。

`weight` 取值无法作为整数识别时 MUST 中断渲染，包括非数字字符串、布尔值、map、list 以及带小数的浮点数。

`weight` 为小于 1 或大于 100 的整数时 MUST 中断渲染。

#### Scenario: weight 缺失

- **WHEN** 入参不含 `weight`
- **THEN** 渲染中断并返回错误

#### Scenario: weight 为空

- **WHEN** `weight` 为 `null` 或空字符串
- **THEN** 渲染中断并返回错误

#### Scenario: weight 非整数

- **WHEN** `weight` 为 `abc`、`true`、map、list 或 `1.5`
- **THEN** 渲染中断并返回错误

#### Scenario: weight 低于下限

- **WHEN** `weight` 为 `0` 或负数
- **THEN** 渲染中断并返回错误

#### Scenario: weight 高于上限

- **WHEN** `weight` 为 `101` 或更大的整数
- **THEN** 渲染中断并返回错误

#### Scenario: weight 取值合法

- **WHEN** `weight` 为 `1` 到 `100` 之间的整数，含边界值
- **THEN** 输出 `weight: <该整数>`

### Requirement: 委托 preference 到 NodeSelectorTerm

系统 MUST 要求 `preference` 存在且为非空 map。

`preference` 缺失、为 `null`、为空字符串或为空 map 时 MUST 中断渲染。该必填校验 MUST 复用既有必填取值能力，错误信息 MUST 保留该能力自身的消息前缀并与 `weight` 的必填失败形式一致。

系统 MUST 把 `preference` 原样作为上下文委托 `definitions.nodeSelectorTerm`，并以该模板返回的 map 作为 `preference` 字段内容。

系统 MUST NOT 自行解析 `preference` 内部的 `matchExpressions`、`matchFields` 或其中的字符串简写。

`preference` 取值不是 map 时 MUST 中断渲染。

子模板返回内容为空或无法恢复为 map 时 MUST 中断渲染，错误信息 MUST 包含 `[definitions.preferredSchedulingTerm]` 前缀与 `preference` 字段路径。

#### Scenario: 原样委托

- **WHEN** `preference` 含 `matchExpressions` 与 `matchFields`
- **THEN** 两者内容原样传入 `definitions.nodeSelectorTerm`，输出 `preference` 取自该模板返回值

#### Scenario: preference 缺失或为空

- **WHEN** `preference` 缺失、为 `null`、为空字符串或为空 map
- **THEN** 渲染中断，失败消息来自既有必填取值能力且包含 `preference`，与 `weight` 必填缺失的消息形式一致

#### Scenario: preference 不是 map

- **WHEN** `preference` 为字符串、布尔值或 list
- **THEN** 渲染中断，错误信息以 `[definitions.preferredSchedulingTerm]` 开头

#### Scenario: 子模板返回空内容

- **WHEN** `definitions.nodeSelectorTerm` 返回空内容
- **THEN** 渲染中断并返回错误，错误信息包含 `[definitions.preferredSchedulingTerm]` 与 `preference`

#### Scenario: 子模板返回非 map

- **WHEN** `definitions.nodeSelectorTerm` 的返回值无法恢复为 map
- **THEN** 渲染中断并返回错误

### Requirement: preferredDuringSchedulingIgnoredDuringExecution 委托

系统 MUST 逐项委托 `definitions.preferredSchedulingTerm` 渲染 `preferredDuringSchedulingIgnoredDuringExecution` 的每个 `PreferredSchedulingTerm`。

系统 MUST 为每项向下传递该项的 `weight` 与 `preference`；`preference` MUST 携带该项的 `matchExpressions` 与 `matchFields`。

系统 MUST 保持输入项顺序；每个输入项 MUST 在输出中对应一项，MUST NOT 合并、去重或重排。

系统 MUST NOT 校验 `weight` 的整数类型与 1 - 100 取值范围；取值存在且为标量时 MUST 以该取值向下传递，范围校验由 `definitions.preferredSchedulingTerm` 负责。

系统 MUST 识别 term 内的 `weightAlias`、`matchExpressionsAlias`、`matchFieldsAlias`；非空别名 MUST 优先于同名规范键，别名缺失或为空时 MUST 回退同名规范键。

单个 term 的 `matchExpressions` 与 `matchFields` 归一化后都为空时 MUST 中断渲染，MUST NOT 向 `definitions.preferredSchedulingTerm` 传递空 `preference`。错误信息 MUST 包含 `[definitions.nodeAffinity]` 前缀、字段路径与元素下标。

`matchExpressions` 与 `matchFields` 至少一个非空时 MUST 仍委托子模板，MUST NOT 跳过该 term。

#### Scenario: 单项委托

- **WHEN** `preferredDuringSchedulingIgnoredDuringExecution` 含一项，带 `weight: 1`、`matchExpressions` 与 `matchFields`
- **THEN** 输出包含一项，其内容来自子模板返回值

#### Scenario: 多项保持顺序

- **WHEN** `preferredDuringSchedulingIgnoredDuringExecution` 含多项且 `weight` 各不相同
- **THEN** 输出项顺序与输入顺序一致

#### Scenario: weight 超出范围仍委托

- **WHEN** 某一项的 `weight` 为 `101`
- **THEN** 系统仍委托子模板，MUST NOT 因范围问题中断渲染

#### Scenario: 空匹配条件中断

- **WHEN** 某一项的 `matchExpressions` 与 `matchFields` 归一化后都为空
- **THEN** 渲染中断并返回错误，错误信息包含 `[definitions.nodeAffinity]`、`preferredDuringSchedulingIgnoredDuringExecution` 与元素下标

#### Scenario: 仅 matchFields 非空仍委托

- **WHEN** 某一项只提供 `matchFields`，未提供 `matchExpressions`
- **THEN** 系统正常委托子模板，输出包含对应项

#### Scenario: 子项别名优先

- **WHEN** 某一项同时提供 `weight` 与取值不同的 `weightAlias`
- **THEN** 传给子模板的 `weight` 取自 `weightAlias`

#### Scenario: 空子项别名回退

- **WHEN** 某一项提供空 `matchExpressionsAlias` 与非空的 `matchExpressions`
- **THEN** 传给子模板的 `preference.matchExpressions` 取自 `matchExpressions`

## 非目标

- 不改变 `weight` 的校验规则、取值范围与失败边界。
- 不改变 `definitions.nodeSelectorTerm` 的入参契约与内部行为。
- 不处理 `nodeAffinity`、`podAffinity`、`podAntiAffinity` 的 map 类型兼容。
- 不改变 `requiredDuringSchedulingIgnoredDuringExecution` 分支的行为。
