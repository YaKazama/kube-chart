---
updated_at: "2026-11-16T05:39:20Z"
---

# definitions.topologySpreadConstraint 规格

## Purpose

按 Kubernetes `TopologySpreadConstraint` 结构渲染单条拓扑分布约束字段片段，供 `PodSpec` 的 `topologySpreadConstraints` 数组逐项复用。

## ADDED Requirements

### Requirement: TopologySpreadConstraint 字段片段渲染

系统 MUST 以单个 map 作为上下文，按 `labelSelector`、`matchLabelKeys`、`maxSkew`、`minDomains`、`nodeAffinityPolicy`、`nodeTaintsPolicy`、`topologyKey`、`whenUnsatisfiable` 的固定顺序渲染 TopologySpreadConstraint 字段片段，并返回可解析为 map 的 YAML 内容。

`maxSkew`、`topologyKey`、`whenUnsatisfiable` 必填；其余字段可选。`labelSelector` 为对象，`matchLabelKeys` 为字符串数组，`maxSkew`、`minDomains` 为整数，其余四个字段为字符串。

#### Scenario: 渲染完整结构

- **WHEN** 上下文提供全部八个字段且取值合法
- **THEN** 输出按固定顺序包含八个字段，`labelSelector` 为对象、`matchLabelKeys` 为字符串数组、`maxSkew` 与 `minDomains` 为 YAML 整数、其余字段为 YAML 字符串

#### Scenario: 仅提供必填字段

- **WHEN** 上下文只提供 `maxSkew`、`topologyKey`、`whenUnsatisfiable`
- **THEN** 输出只包含这三个字段，顺序为 `maxSkew`、`topologyKey`、`whenUnsatisfiable`

#### Scenario: 必填字段缺失

- **WHEN** `maxSkew`、`topologyKey`、`whenUnsatisfiable` 任一缺失、为 null 或为空字符串
- **THEN** 渲染中断

#### Scenario: labelSelector 透传

- **WHEN** `labelSelector` 为对象
- **THEN** 输出以 `labelSelector` 为父键的字段片段，其内容完全由 `definitions.labelSelector` 决定，本模板不解析其内部字段

#### Scenario: whenUnsatisfiable 枚举

- **WHEN** `whenUnsatisfiable` 不是 `DoNotSchedule` 或 `ScheduleAnyway`
- **THEN** 渲染中断，失败消息给出合法取值范围

#### Scenario: nodeAffinityPolicy 与 nodeTaintsPolicy 枚举

- **WHEN** `nodeAffinityPolicy` 或 `nodeTaintsPolicy` 非空且不是 `Honor` 或 `Ignore`
- **THEN** 渲染中断，失败消息给出合法取值范围

#### Scenario: 枚举大小写敏感

- **WHEN** 枚举字段取 `donotschedule`、`honor` 等非精确匹配形式
- **THEN** 渲染中断，不做大小写归一化

#### Scenario: nodeAffinityPolicy 与 nodeTaintsPolicy 为空值

- **WHEN** `nodeAffinityPolicy` 或 `nodeTaintsPolicy` 为 null、空字符串或仅含空白
- **THEN** 不输出该字段，且不中断渲染

#### Scenario: topologyKey 标签键语法

- **WHEN** `topologyKey` 不满足 Kubernetes 标签键语法，例如包含两个以上 `/`、name 段非法或 prefix 段非法
- **THEN** 渲染中断，失败消息携带本模板名与字段路径

#### Scenario: topologyKey 带 prefix

- **WHEN** `topologyKey` 形如 `topology.kubernetes.io/zone`
- **THEN** 校验通过并原样输出该取值

#### Scenario: 字符串字段类型非法

- **WHEN** `whenUnsatisfiable`、`topologyKey`、`nodeAffinityPolicy` 或 `nodeTaintsPolicy` 为 map、list、布尔或数值
- **THEN** 渲染中断，不做类型归一化

#### Scenario: 未知字段

- **WHEN** 上下文包含上述八个字段以外的键
- **THEN** 该键被忽略，不参与输出

### Requirement: maxSkew 与 minDomains 数值边界

系统 MUST 将 `maxSkew` 与 `minDomains` 按整数处理，并拒绝非正取值。

#### Scenario: maxSkew 为正整数

- **WHEN** `maxSkew` 为大于 `0` 的整数
- **THEN** 输出该字段，取值为 YAML 整数

#### Scenario: maxSkew 为 0

- **WHEN** `maxSkew` 为 `0`，无论写作原生整数还是带引号字符串
- **THEN** 渲染中断

#### Scenario: maxSkew 类型非法

- **WHEN** `maxSkew` 为布尔、map、list 或非整数文本
- **THEN** 渲染中断，不做类型归一化

#### Scenario: minDomains 为正整数

- **WHEN** `minDomains` 为大于 `0` 的整数
- **THEN** 输出该字段，取值为 YAML 整数

#### Scenario: minDomains 为 0 或负数

- **WHEN** `minDomains` 为 `0` 或负数
- **THEN** 渲染中断

#### Scenario: minDomains 缺省

- **WHEN** `minDomains` 未提供、为 null 或为空字符串
- **THEN** 不输出该字段，且不中断渲染

#### Scenario: minDomains 类型非法

- **WHEN** `minDomains` 为布尔、map、list 或非整数文本
- **THEN** 渲染中断，不做类型归一化

### Requirement: matchLabelKeys 与 labelSelector 的依赖关系

系统 MUST 在 `labelSelector` 未设置时拒绝非空的 `matchLabelKeys`，并对 `matchLabelKeys` 逐项执行字符串类型校验、剔除空项后去重。

#### Scenario: 有 labelSelector 时允许 matchLabelKeys

- **WHEN** `labelSelector` 已设置且 `matchLabelKeys` 为非空字符串数组
- **THEN** 输出 `matchLabelKeys`，元素顺序与输入一致，重复项只保留首次出现的位置

#### Scenario: 无 labelSelector 时的 matchLabelKeys

- **WHEN** `labelSelector` 未设置、为 null 或为空字符串，且 `matchLabelKeys` 非空
- **THEN** 渲染中断

#### Scenario: matchLabelKeys 缺省

- **WHEN** `matchLabelKeys` 未提供、为 null 或为空数组
- **THEN** 不输出该字段，且不中断渲染

#### Scenario: 剔除空项

- **WHEN** `matchLabelKeys` 包含空字符串或仅含空白的元素
- **THEN** 这些元素被剔除；剔除后为空时不输出该字段

#### Scenario: 元素类型非法

- **WHEN** `matchLabelKeys` 包含布尔、数值、map 或 list 元素
- **THEN** 渲染中断

#### Scenario: matchLabelKeys 非数组

- **WHEN** `matchLabelKeys` 为 map、字符串或数值
- **THEN** 渲染中断

## 非目标

- 不处理 Schema。
- 不处理其他 PodSpec 字段，也不组合多个资源。
- 不解析 `labelSelector` 内部结构，其行为由 `definitions.labelSelector` 定义。
- 不校验 `minDomains` 与 `whenUnsatisfiable` 的配合关系；官方说明要求 `minDomains` 非空时 `whenUnsatisfiable` 为 `DoNotSchedule`，由集群校验。
