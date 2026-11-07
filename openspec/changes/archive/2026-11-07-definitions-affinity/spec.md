---
updated_at: "2026-11-07T15:00:30Z"
---

# Affinity 共享结构规格

## Purpose

为 Kubernetes `Affinity` 对象提供统一的共享结构渲染入口，使上层资源把已合并的 `nodeAffinity`、`podAffinity`、`podAntiAffinity` 交给单一模板完成子结构取值、短键归一化与子模板委托。

## ADDED Requirements

### Requirement: 子结构取值与规范键输出

系统 MUST 从入参 map 读取 `nodeAffinity`、`podAffinity`、`podAntiAffinity` 三类子结构。

系统 MUST 只把归一化后仍有内容的子结构委托给对应子模板：`nodeAffinity` 委托 `definitions.nodeAffinity`，`podAffinity` 委托 `definitions.podAffinity`，`podAntiAffinity` 委托 `definitions.podAntiAffinity`。

系统 MUST 以与入参同名的规范键（`nodeAffinity`、`podAffinity`、`podAntiAffinity`）输出子模板结果，MUST NOT 改名、MUST NOT 新增其他顶层键。

系统 MUST 输出可被 `fromYaml` 解析的单个 map YAML；三类子结构均无有效内容时 MUST 输出空结果，MUST NOT 输出空 map 或占位结构。

#### Scenario: 三类子结构分别委托

- **WHEN** 入参同时包含 `nodeAffinity`、`podAffinity`、`podAntiAffinity`
- **THEN** 输出包含同名三个键，各键内容来自对应子模板的返回值

#### Scenario: 仅提供的子结构被委托

- **WHEN** 入参只包含 `podAffinity`
- **THEN** 输出只包含 `podAffinity`，不出现 `nodeAffinity` 与 `podAntiAffinity`

#### Scenario: 子结构无有效内容时不输出

- **WHEN** 入参包含 `podAffinity: {}`
- **THEN** 输出不包含 `podAffinity`

#### Scenario: 全部子结构缺失

- **WHEN** 入参不含三类子结构中任意一类，或全部无有效内容
- **THEN** 系统输出空结果

### Requirement: 规范长键输出与短键归一化

系统 MUST 在每个子结构内部识别 `preferred` 与 `required` 两个显式短键，并把它们归一化为 `preferredDuringSchedulingIgnoredDuringExecution` 与 `requiredDuringSchedulingIgnoredDuringExecution`。

系统 MUST 以长键名作为向下传递 map 的规范键名，向下传递的 map MUST NOT 包含 `preferred`、`required` 等短键名。

同一子结构内，短键取值非空时 MUST 以短键取值为最终值；短键缺失或为空时 MUST 退化使用对应规范长键的原值；短键与规范长键均为空时该字段 MUST NOT 向下传递。

`preferred` / `required` 与对应规范长键 MUST NOT 互斥，同时提供时 MUST 按优先级链取值而不是中断渲染。

系统 MUST 识别短键与规范长键各自的同级 `<叶子>Alias`；短键作为长键的显式别名，同时 MUST 继承自身叶子的 `*Alias`。整体取值优先级 MUST 为：短键的同级 `*Alias` > 短键 > 长键的同级 `*Alias` > 长键。

子结构内不属于上述两个映射的其余字段 MUST 丢弃，MUST NOT 向下传递。

#### Scenario: 短键归一化为规范长键

- **WHEN** `podAffinity` 只提供 `preferred` 与 `required`
- **THEN** 传给 `definitions.podAffinity` 的 map 只包含 `preferredDuringSchedulingIgnoredDuringExecution` 与 `requiredDuringSchedulingIgnoredDuringExecution`

#### Scenario: 短键优先于规范长键

- **WHEN** `nodeAffinity` 同时提供 `preferred` 与 `preferredDuringSchedulingIgnoredDuringExecution`，且取值不同
- **THEN** 传给 `definitions.nodeAffinity` 的 `preferredDuringSchedulingIgnoredDuringExecution` 取值来自 `preferred`

#### Scenario: 空短键回退规范长键

- **WHEN** `podAntiAffinity` 的 `preferred` 为空集合，同时提供非空的 `preferredDuringSchedulingIgnoredDuringExecution`
- **THEN** 传给 `definitions.podAntiAffinity` 的 `preferredDuringSchedulingIgnoredDuringExecution` 取值来自规范长键

#### Scenario: 短键与规范长键都为空

- **WHEN** `podAffinity` 的 `required` 与 `requiredDuringSchedulingIgnoredDuringExecution` 都为空集合
- **THEN** 传给 `definitions.podAffinity` 的 map 不包含 `requiredDuringSchedulingIgnoredDuringExecution`

#### Scenario: 短键与其同级别名共存

- **WHEN** `podAffinity` 同时提供 `preferred` 与 `preferredAlias`
- **THEN** 传给 `definitions.podAffinity` 的 `preferredDuringSchedulingIgnoredDuringExecution` 取值来自 `preferredAlias`

#### Scenario: 短键优先于长键同级别名

- **WHEN** `podAffinity` 提供非空 `preferred`，且只提供 `preferredDuringSchedulingIgnoredDuringExecutionAlias`
- **THEN** 传给 `definitions.podAffinity` 的 `preferredDuringSchedulingIgnoredDuringExecution` 取值来自 `preferred`

#### Scenario: 长键同级别名生效

- **WHEN** `nodeAffinity` 同时提供 `requiredDuringSchedulingIgnoredDuringExecutionAlias` 与非空规范长键，且未提供 `required`
- **THEN** 传给 `definitions.nodeAffinity` 的 `requiredDuringSchedulingIgnoredDuringExecution` 取值来自该别名

#### Scenario: 短键与长键同时提供不中断

- **WHEN** `podAntiAffinity` 同时提供非空 `preferred` 与非空 `preferredDuringSchedulingIgnoredDuringExecution`
- **THEN** 渲染继续，取值按短键优先，MUST NOT 中断渲染

#### Scenario: 其余字段丢弃

- **WHEN** `podAffinity` 除 `preferred` 外还包含 `mismatchLabelKeys` 等未被本规格定义的字段
- **THEN** 传给 `definitions.podAffinity` 的 map 不包含这些字段

### Requirement: Affinity 输入失败边界

`nodeAffinity`、`podAffinity`、`podAntiAffinity` 的取值 MUST 为 map；取值存在且不是 map 时 MUST 中断渲染，错误信息 MUST 包含 `[definitions.affinity]` 前缀与对应字段名以便定位。

`preferred`、`required` 与对应规范长键的取值 MUST 为 array；取值存在且不是 array 时 MUST 中断渲染，错误信息 MUST 包含 `[definitions.affinity]` 前缀与对应字段路径。

子模板返回值无法解析为 YAML 时 MUST 中断渲染，错误信息 MUST 包含 `[definitions.affinity]` 前缀与对应字段名。

系统 MUST NOT 校验子模板返回值的内部字段与结构。

#### Scenario: 子结构不是 map

- **WHEN** `podAntiAffinity` 取值为字符串
- **THEN** 渲染中断，错误信息包含 `[definitions.affinity]` 与 `podAntiAffinity`

#### Scenario: 短键不是 array

- **WHEN** `podAffinity.preferred` 取值为 map
- **THEN** 渲染中断，错误信息包含 `[definitions.affinity]` 与 `podAffinity.preferred`

#### Scenario: 规范长键不是 array

- **WHEN** `nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution` 取值为字符串
- **THEN** 渲染中断，错误信息包含 `[definitions.affinity]` 与 `nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution`

#### Scenario: 子模板返回不可解析内容

- **WHEN** 被委托的子模板返回文本不是合法 YAML
- **THEN** 渲染中断，错误信息包含 `[definitions.affinity]` 与对应字段名

## 非目标

- 不定义 `nodeAffinity`、`podAffinity`、`podAntiAffinity` 内部字段的渲染结构、字段顺序与校验规则。
- 不实现 `definitions.nodeAffinity`、`definitions.podAffinity`、`definitions.podAntiAffinity` 及任何 `PodAffinityTerm`、`WeightedPodAffinityTerm`、`PreferredSchedulingTerm`、`NodeSelector`、`NodeSelectorTerm`、`NodeSelectorRequirement` 独立模板。
- 不为 `preferredDuringSchedulingIgnoredDuringExecution`、`requiredDuringSchedulingIgnoredDuringExecution` 的元素构造、派生或补齐任何数据形态。
- 不将 `preferred` / `required` 与对应规范长键设为互斥，也不在两者同时提供时中断渲染。
- 不处理 `mismatchLabelKeys`、`weight` 取值范围、`topologyKey` 非空等字段语义。
- 不修改 `templates/api-resources/Core/_PodSpec.tpl` 的既有调用方式与合并逻辑。
