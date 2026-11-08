---
updated_at: "2026-11-08T16:10:18Z"
---

# 标签键校验统一规格

## Purpose

为 Kubernetes 标签键语法提供唯一的共享校验入口，使各共享结构与资源模板复用同一套拆分、段语法与前缀长度规则，并让失败消息归属实际发起校验的调用方模板。

## ADDED Requirements

### Requirement: 校验标签键语法

系统 MUST 提供统一的标签键语法校验能力，入参 MUST 包含待校验的标签键、调用方模板名与调用方字段路径。

系统 MUST 先去除标签键首尾空白，再按 `/` 拆分；拆分结果 MUST 至多两段，末段为名称段，其前一段为可选前缀段。

名称段 MUST 为 1 至 63 个字符，首尾 MUST 为字母或数字，中间只允许 `-`、`_`、`.`。

前缀段 MUST 为点分隔的小写 DNS 标签序列，每段首尾 MUST 为小写字母或数字，中间只允许 `-`；前缀段总长 MUST NOT 超过 253 个字符。

校验通过时 MUST 返回去除首尾空白后的标签键，MUST NOT 改写其余字符。

标签键不是 string 类型、包含两个及以上 `/`、名称段不符合名称段语法、前缀段不符合前缀段语法或前缀段超过 253 个字符时 MUST 中断渲染。

上述失败消息 MUST 统一采用 `[<调用方模板名>] <调用方字段路径>: <原因>` 格式，MUST NOT 出现 `[base.labelKey]` 或任何被委托能力的消息前缀。

#### Scenario: 无前缀的合法标签键

- **WHEN** 标签键为 `zone`
- **THEN** 校验通过并返回 `zone`

#### Scenario: 带前缀的合法标签键

- **WHEN** 标签键为 `topology.kubernetes.io/zone`
- **THEN** 校验通过并返回该值

#### Scenario: 首尾空白被去除

- **WHEN** 标签键为 `"  app.kubernetes.io/name  "`
- **THEN** 校验通过并返回 `app.kubernetes.io/name`

#### Scenario: 标签键不是字符串

- **WHEN** 标签键为布尔值、数值、map 或 list
- **THEN** 渲染中断，失败消息以调用方模板名与字段路径开头

#### Scenario: 多个分隔符

- **WHEN** 标签键为 `a/b/c`
- **THEN** 渲染中断，失败消息为 `[<调用方模板名>] <调用方字段路径>: '<该值>' allows at most one '/' separator`

#### Scenario: 名称段非法

- **WHEN** 标签键为 `-zone`、`zone-`、`Zone Key`，或名称段超过 63 个字符
- **THEN** 渲染中断，失败消息为 `[<调用方模板名>] <调用方字段路径>: '<该值>' does not match label key name syntax`

#### Scenario: 前缀段非法

- **WHEN** 标签键为 `Bad_Prefix/name` 或 `a..b/name`
- **THEN** 渲染中断，失败消息为 `[<调用方模板名>] <调用方字段路径>: '<该值>' does not match label key prefix syntax`

#### Scenario: 前缀段超长

- **WHEN** 标签键的前缀段总长超过 253 个字符
- **THEN** 渲染中断，失败消息为 `[<调用方模板名>] <调用方字段路径>: prefix '<前缀段>' exceeds 253 characters`

## MODIFIED Requirements

### Requirement: 校验 key

`matchExpressions` 与 `matchFields` 的 `key` MUST 按 Kubernetes 标签键语法校验，MUST NOT 按字段路径语法放行。

`key` MUST 为非空 string，MUST 由至多一个 `/` 分隔为可选的 DNS 前缀段与名称段；名称段与前缀段 MUST 符合 Kubernetes 标签键的字符与长度约束，前缀段长度 MUST NOT 超过 253 个字符。

标签键语法校验 MUST 由项目统一的标签键校验能力完成。

`key` 缺失、为 `null`、为空字符串或不符合上述语法时 MUST 中断渲染，错误信息 MUST 包含所属字段名与条目下标，且模板名前缀 MUST 为 `[definitions.nodeSelectorTerm]`，MUST NOT 出现被委托能力的消息前缀。

#### Scenario: 合法 key

- **WHEN** `key` 为 `c` 或 `app.kubernetes.io/name`
- **THEN** 正常渲染

#### Scenario: key 缺失或为空

- **WHEN** map 条目不含 `key`，或 `key` 为空字符串
- **THEN** 渲染中断并返回错误，错误信息包含 `matchExpressions` 或 `matchFields`、条目下标与 `key`

#### Scenario: key 语法非法

- **WHEN** `key` 含两个及以上 `/`，名称段以 `-` 开头，或前缀段含大写字母
- **THEN** 渲染中断并返回带 `[definitions.nodeSelectorTerm]` 前缀的错误信息

#### Scenario: 字段路径写法

- **WHEN** `key` 为不符合标签键语法的字段路径写法
- **THEN** 渲染中断并返回带 `[definitions.nodeSelectorTerm]` 前缀的错误信息

### Requirement: LabelSelectorRequirement 字段渲染

系统 MUST 渲染单个 Kubernetes `LabelSelectorRequirement` 片段，并按 `key`、`operator`、`values` 的顺序输出字段。

`key`、`operator`、`values` 的取值 MUST 遵循统一的多层字段解析：按调用上下文自身、`.Context`、`.Values`、`.Values.global` 的优先级取首个有效值；在每个数据源内，非空的 `keyAlias`、`operatorAlias`、`valuesAlias` 优先于同名规范键，空别名回退到规范键；别名不跨数据源生效。

`key` 与 `operator` 为必填。两者缺失、为 `null` 或为空字符串时 MUST 中断渲染，并输出既有必填校验能力产生的失败消息。`key` 非字符串时 MUST 中断渲染。

`key` MUST 为字符串并符合 Kubernetes 标签键语法：可选前缀段与 `/` 分隔符，后接名称段；名称段为 1-63 个字符，以字母或数字开头结尾，中间只允许 `-`、`_`、`.`；前缀段为点分隔的小写字母数字标签序列，每段以字母或数字开头结尾，中间只允许 `-`。`key` 含多于一个 `/` 时 MUST 中断渲染。

标签键语法校验 MUST 由项目统一的标签键校验能力完成，其失败消息 MUST 以 `[definitions.labelSelectorRequirement]` 为模板名前缀，MUST NOT 保留被委托能力自身的消息前缀。前缀段总长超过 253 个字符时 MUST 中断渲染，失败消息的字段路径 MUST 为 `key`。

`operator` MUST 为字符串且取值只能是 `In`、`NotIn`、`Exists`、`DoesNotExist`，大小写敏感；其他取值 MUST 中断渲染并给出合法取值范围。

`values` 为可选数组。缺失或为空数组时 MUST 不输出该字段；非数组时 MUST 中断渲染。元素 MUST NOT 逐个校验类型，输出时 MUST 统一转为字符串；元素中的 `null` MUST 视为空值，转换后为空数组时 MUST 不输出该字段。本模板 MUST NOT 判定 `values` 与 `operator` 的适用性，该判定由调用方负责。

本模板自身产生的失败 MUST 使用 `[definitions.labelSelectorRequirement]` 前缀；标签键语法校验失败同样使用该前缀；其余由既有能力产生的失败保留被委托能力的消息前缀。

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
- **THEN** 中断渲染并输出带 `[definitions.labelSelectorRequirement]` 前缀的失败消息

#### Scenario: 前缀段超长

- **WHEN** `key` 的前缀段总长超过 253 个字符
- **THEN** 中断渲染并输出带 `[definitions.labelSelectorRequirement]` 前缀、字段路径为 `key` 的失败消息

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

### Requirement: 校验 topologyKey

系统 MUST 要求 `topologyKey` 存在且为非空 string。

`topologyKey` MUST 满足 Kubernetes 标签键语法，校验 MUST 由项目统一的标签键校验能力完成。

`topologyKey` 缺失、为 `null` 或为空字符串时 MUST 中断渲染。

`topologyKey` 不是 string 类型、不符合标签键语法时 MUST 中断渲染，且失败消息的模板名前缀 MUST 为 `[definitions.podAffinityTerm]`、字段路径 MUST 为 `topologyKey`，MUST NOT 出现被委托能力的消息前缀。

#### Scenario: topologyKey 缺失或为空

- **WHEN** 入参不含 `topologyKey`，或其值为 `null`、空字符串
- **THEN** 渲染中断并返回错误

#### Scenario: topologyKey 不是 string

- **WHEN** `topologyKey` 为布尔值、数值、map 或 list
- **THEN** 渲染中断并返回带 `[definitions.podAffinityTerm]` 前缀、字段路径为 `topologyKey` 的错误

#### Scenario: topologyKey 语法非法

- **WHEN** `topologyKey` 为 `-zone`、`zone-`、`Zone Key`、`a/b/c`，或名称段超过 63 字符
- **THEN** 渲染中断并返回带 `[definitions.podAffinityTerm]` 前缀的错误

#### Scenario: topologyKey 语法合法

- **WHEN** `topologyKey` 为 `zone` 或 `topology.kubernetes.io/zone`
- **THEN** 输出 `topologyKey` 且取值为该字符串

### Requirement: 渲染 matchLabelKeys 与 mismatchLabelKeys

系统 MUST 把 `matchLabelKeys` 与 `mismatchLabelKeys` 输出为 string array。

两个字段的列表项 MUST 按与 `topologyKey` 相同的标签键语法校验，校验 MUST 由项目统一的标签键校验能力完成。

两个字段 MUST 去重并剔除空字符串项。

字段缺失、为 `null`、为空 array 或去重后为空时 MUST NOT 输出对应字段。

取值不是 array 时 MUST 中断渲染。

列表项不符合标签键语法时 MUST 中断渲染，且失败消息的模板名前缀 MUST 为 `[definitions.podAffinityTerm]`、字段路径 MUST 为 `<字段名>[<项下标>]`，MUST NOT 出现被委托能力的消息前缀。

#### Scenario: 合法的键列表

- **WHEN** `matchLabelKeys` 为 `["app", "app.kubernetes.io/name", "app"]`
- **THEN** 输出 `matchLabelKeys` 且去重后为 `["app", "app.kubernetes.io/name"]`

#### Scenario: 键列表为空

- **WHEN** `matchLabelKeys` 或 `mismatchLabelKeys` 为 `[]`、`null` 或只含空字符串
- **THEN** 输出不包含对应字段

#### Scenario: 键列表不是 array

- **WHEN** `matchLabelKeys` 为字符串或 map
- **THEN** 渲染中断并返回错误

#### Scenario: 键语法非法

- **WHEN** `matchLabelKeys` 含 `-app` 或 `a/b/c`
- **THEN** 渲染中断并返回带 `[definitions.podAffinityTerm]` 前缀、字段路径含字段名与项下标的错误

## 非目标

- 不为 `definitions.objectMeta` 的 `labels` 增加键语法校验。
- 不为 `definitions.nodeSelectorRequirement` 的 `key` 增加标签键语法校验。
- 不改变标签键语法规则本身（名称段、前缀段与前缀长度约束）。
- 不调整本次范围之外其他字段的失败消息与行为。
