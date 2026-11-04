---
updated_at: "2026-11-04T05:55:16Z"
---

# 修正 LabelSelectorRequirement 模板规格

## MODIFIED Requirements

### Requirement: LabelSelectorRequirement 字段渲染

系统 MUST 渲染单个 Kubernetes `LabelSelectorRequirement` 片段，并按 `key`、`operator`、`values` 的顺序输出字段。

`key`、`operator`、`values` 的取值 MUST 遵循统一的多层字段解析：按调用上下文自身、`.Context`、`.Values`、`.Values.global` 的优先级取首个有效值；在每个数据源内，非空的 `keyAlias`、`operatorAlias`、`valuesAlias` 优先于同名规范键，空别名回退到规范键；别名不跨数据源生效。

`key` 与 `operator` 为必填。两者缺失、为 `null` 或为空字符串时 MUST 中断渲染，并输出既有必填校验能力产生的失败消息。`key` 非字符串时 MUST 中断渲染。

`key` MUST 为字符串并符合 Kubernetes 标签键语法：可选前缀段与 `/` 分隔符，后接名称段；名称段为 1-63 个字符，以字母或数字开头结尾，中间只允许 `-`、`_`、`.`；前缀段为点分隔的小写字母数字标签序列，每段以字母或数字开头结尾，中间只允许 `-`。`key` 含多于一个 `/` 时 MUST 中断渲染，失败消息使用 `[definitions.labelSelectorRequirement]` 前缀。

名称段与前缀段的字符与长度规则 MUST 委托既有字符串正则校验能力执行，其失败消息保留该能力自身的消息前缀。前缀段总长超过 253 个字符时 MUST 中断渲染。

`operator` MUST 为字符串且取值只能是 `In`、`NotIn`、`Exists`、`DoesNotExist`，大小写敏感；其他取值 MUST 中断渲染并给出合法取值范围。

`values` 为可选数组。缺失或为空数组时 MUST 不输出该字段；非数组时 MUST 中断渲染。元素 MUST NOT 逐个校验类型，输出时 MUST 统一转为字符串；元素中的 `null` MUST 视为空值，转换后为空数组时 MUST 不输出该字段。本模板 MUST NOT 判定 `values` 与 `operator` 的适用性，该判定由调用方负责。

本模板自身产生的失败 MUST 使用 `[definitions.labelSelectorRequirement]` 前缀；委托既有能力产生的失败保留被委托能力的消息前缀。

#### Scenario: 渲染 In 表达式

- **WHEN** 传入 `key` 为 `app.kubernetes.io/name`、`operator` 为 `In`、`values` 为 `["web", "api"]`
- **THEN** 输出依次包含 `key`、`operator`、`values` 三个字段
- **AND** `values` 为两项字符串数组

#### Scenario: 省略 values

- **WHEN** 传入 `operator` 为 `Exists` 且未提供 `values`
- **THEN** 输出只包含 `key` 与 `operator`

#### Scenario: values 为空数组

- **WHEN** 传入 `operator` 为 `In` 且 `values` 为空数组
- **THEN** 输出只包含 `key` 与 `operator`

#### Scenario: 子模板不判定 values 适用性

- **WHEN** 直接传入 `operator` 为 `Exists` 且 `values` 为非空字符串数组
- **THEN** 输出包含 `key`、`operator`、`values` 三个字段

#### Scenario: 别名生效

- **WHEN** 同一数据源内提供非空 `keyAlias` 且未提供 `key`
- **THEN** 使用别名值渲染 `key`

#### Scenario: 规范键优先于空别名

- **WHEN** 同一数据源内 `keyAlias` 为空字符串且提供 `key`
- **THEN** 使用 `key` 的值渲染

#### Scenario: 名称或运算符缺失

- **WHEN** `key` 或 `operator` 缺失、为 `null` 或为空字符串
- **THEN** 中断渲染，失败消息来自既有必填校验能力

#### Scenario: key 非字符串

- **WHEN** 传入的 `key` 为数字或布尔等非字符串类型
- **THEN** 中断渲染并输出带 `[definitions.labelSelectorRequirement]` 前缀的失败消息

#### Scenario: 多个分隔符

- **WHEN** `key` 含有两个 `/`
- **THEN** 中断渲染并输出带 `[definitions.labelSelectorRequirement]` 前缀的失败消息

#### Scenario: 名称段或前缀段不合规

- **WHEN** `key` 的名称段含非法字符或长度超出 1-63，或前缀段含大写字母或不符合标签规则
- **THEN** 中断渲染，失败消息来自既有字符串正则校验能力

#### Scenario: 前缀段超长

- **WHEN** `key` 的前缀段总长超过 253 个字符
- **THEN** 中断渲染

#### Scenario: 非法运算符

- **WHEN** `operator` 取值不在 `In`、`NotIn`、`Exists`、`DoesNotExist` 之内，例如 `in`
- **THEN** 中断渲染并输出合法取值范围

#### Scenario: 运算符首尾空白

- **WHEN** `operator` 为 `Exists ` 等带首尾空白的合法取值
- **THEN** 去除首尾空白后正常渲染 `operator: Exists`

#### Scenario: values 类型非法

- **WHEN** `values` 不是数组
- **THEN** 中断渲染

#### Scenario: values 元素强制转字符串

- **WHEN** 传入 `values` 为非字符串数组，例如 `["a", 3, true]`
- **THEN** 输出 `values` 为三项字符串数组，数字与布尔元素按其字符串形式渲染

#### Scenario: values 仅含 null 元素

- **WHEN** 传入 `values` 为 `[null]`
- **THEN** 输出不包含 `values` 字段

### Requirement: LabelSelector matchExpressions 项归一化

系统 MUST 在 `definitions.labelSelector` 的 `matchExpressions` 原生对象项中分别取出 `key`、`operator`、`values`，按统一的多层字段解析取值：非空的同名 `*Alias` 优先于规范键，空别名回退规范键；取到的值归一化后传递给 `definitions.labelSelectorRequirement`。

该项取到的 `key` 或 `operator` 为空、或 `operator` 不在允许范围内时 MUST 中断渲染并输出带 `[definitions.labelSelector]` 前缀的失败消息。`key` 的标签键语法 MUST 由 `definitions.labelSelectorRequirement` 校验，失败消息使用其前缀。

`values` 的适用性 MUST 由该项按 `operator` 判定：`In`、`NotIn` 要求非空数组，缺失、空数组或仅含 `null` 的数组时 MUST 中断渲染；`Exists`、`DoesNotExist` 不接受有效 `values`，去除 `null` 后非空时 MUST 中断渲染。该项 MUST NOT 重复校验 `values` 元素类型，元素统一转为字符串后传递。上述失败消息均使用 `[definitions.labelSelector]` 前缀。

#### Scenario: 原生对象携带别名

- **WHEN** `matchExpressions` 项为对象并包含非空 `keyAlias`，且未提供 `key`
- **THEN** 该项按别名取到标签键并正常渲染

#### Scenario: 原生对象字段为空

- **WHEN** `matchExpressions` 项为对象且 `key` 为空字符串，或 `operator` 不在允许范围内
- **THEN** 中断渲染并输出带 `[definitions.labelSelector]` 前缀的失败消息

#### Scenario: 原生对象标签键非法

- **WHEN** `matchExpressions` 项为对象且 `key` 不满足标签键语法
- **THEN** 中断渲染，失败消息来自 `definitions.labelSelectorRequirement`

#### Scenario: 字符串简写不受影响

- **WHEN** `matchExpressions` 项为 `app = web` 字符串简写
- **THEN** 归一化结果不包含任何别名键，渲染输出与本次修复前一致

#### Scenario: In 缺少 values

- **WHEN** `matchExpressions` 项为对象，`operator` 为 `In` 且未提供 `values`
- **THEN** 中断渲染并输出带 `[definitions.labelSelector]` 前缀的失败消息

#### Scenario: Exists 携带非空 values

- **WHEN** `matchExpressions` 项为对象，`operator` 为 `Exists` 或 `DoesNotExist` 且 `values` 非空
- **THEN** 中断渲染并输出带 `[definitions.labelSelector]` 前缀的失败消息

#### Scenario: Exists 携带空 values

- **WHEN** `matchExpressions` 项为对象，`operator` 为 `Exists` 且 `values` 为空数组、为 `null` 或仅含 `null`
- **THEN** 正常渲染，输出只包含 `key` 与 `operator`

#### Scenario: 原生对象 key 非字符串

- **WHEN** `matchExpressions` 项为对象且 `key` 为数字或布尔等非字符串类型
- **THEN** 中断渲染并输出带 `[definitions.labelSelector]` 前缀的失败消息

## 非目标

- 不改变 `values` 与 `operator` 的适用性校验归属，该职责仍由父级承担。
- 不重构 `base.field`、`base.slice` 等其他基础层能力。
- 不新增 `LabelSelector` 与 `LabelSelectorRequirement` 之外的能力。
