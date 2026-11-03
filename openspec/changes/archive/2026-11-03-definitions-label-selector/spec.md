---
updated_at: "2026-11-02T15:49:16Z"
---

# definitions.labelSelector 规格

## Purpose

新增共享结构能力 `definitions.labelSelector`，把 `apps.deploymentSpec` 的 selector 输入归一化为 Kubernetes LabelSelector，支持官方字段类型、字符串简写和内置别名。

## ADDED Requirements

### Requirement: matchLabels 必填与直接渲染

系统 MUST 将 `matchLabels` 作为必填 object 渲染。`matchLabels` 和内置别名 `matchLabelsAlias` 均缺失、为 `null` 或恢复后不是 map 时 MUST 失败并中断渲染。`matchLabels` 为空 object 时 MUST 失败。`matchLabels` 的每个值 MUST 为 string，非 string 值 MUST 失败。`matchLabels` MUST 直接渲染为 LabelSelector 的 `matchLabels` 字段，不做键值改写。

#### Scenario: 直接渲染

- **WHEN** 输入 `matchLabels` 为 `{app: web}`
- **THEN** 输出包含 `matchLabels: {app: web}`

#### Scenario: 缺失中断

- **WHEN** 未提供 `matchLabels` 和 `matchLabelsAlias`
- **THEN** 失败并中断渲染

#### Scenario: 内置别名等价

- **WHEN** 仅提供 `matchLabelsAlias`
- **THEN** 输出与使用 `matchLabels` 相同

#### Scenario: 非 map 中断

- **WHEN** `matchLabels` 为 string 或 array
- **THEN** 失败并中断渲染

#### Scenario: 非 string 值中断

- **WHEN** `matchLabels` 包含非 string 值
- **THEN** 失败并中断渲染

### Requirement: matchExpressions 字符串简写归一化

系统 MUST 接受可选的 `matchExpressions` array；非 array 输入 MUST 失败。`matchExpressions` 为 `null` 时 MUST 按缺失处理并省略该字段。元素允许 string 或 map。string 元素 MUST 按以下完整匹配规则解析：

- 等值/不等值：`<key><空白><操作符><空白><value>`，操作符为 `=`、`==` 或 `!=`；`=` 和 `==` 归一化为 `In`，`!=` 归一化为 `NotIn`，values 为单值列表。
- 集合：`<key><空白><操作符><空白>(<values>)`，操作符为 `in` 或 `notin` 且大小写不敏感；`in` 归一化为 `In`，`notin` 归一化为 `NotIn`。
- 存在性：`<key>` 归一化为 `Exists`；`!<key>` 归一化为 `DoesNotExist`，该形态不输出 values。
- `<key>` 与等值 value 只允许字母、数字、`.`、`_`、`-`；集合 values 允许逗号分隔和两侧空白。

不符合上述任一规则的 string 元素 MUST 失败并中断渲染；`in` 和 `notin` 的列表经清洗后为空时 MUST 同样失败并中断渲染。`In` 和 `NotIn` values MUST 经 `base.slice.cleanup` 清洗后输出为非空 string array；`Exists` 和 `DoesNotExist` MUST 不输出 values 字段。

清洗会把纯数字字符串转换为 int、去重并移除空字符串；输出前 MUST 逐项 `toString`，因此纯数字值以规范化十进制字符串输出，前导零和显式 `+` 不保留。

#### Scenario: 等值

- **WHEN** 字符串为 `environment = production`
- **THEN** 输出 `key: environment`、`operator: In`、`values: [production]`

#### Scenario: 不等值

- **WHEN** 字符串为 `tier != frontend`
- **THEN** 输出 `key: tier`、`operator: NotIn`、`values: [frontend]`

#### Scenario: 集合

- **WHEN** 字符串为 `environment in (production, qa)`
- **THEN** 输出 `key: environment`、`operator: In`、`values: [production, qa]`

#### Scenario: 存在性

- **WHEN** 字符串为 `partition` 或 `!partition1`
- **THEN** 分别输出 `operator: Exists` 和 `operator: DoesNotExist`，且不包含 `values`

#### Scenario: 非法简写中断

- **WHEN** 字符串不匹配等值、集合和存在性任一规则
- **THEN** 失败并中断渲染

#### Scenario: 集合为空中断

- **WHEN** 字符串为 `environment in ()`
- **THEN** 失败并中断渲染

### Requirement: matchExpressions 原生字典与 values 规则

系统 MUST 接受 `matchExpressions` 元素为 map，并只读取 `key`、`operator`、`values`。`key` MUST 为非空 string。`operator` 输入 MUST 大小写不敏感匹配 `In`、`NotIn`、`Exists`、`DoesNotExist`，输出 MUST 使用规范大小写；其他值 MUST 失败。`In` 和 `NotIn` MUST 要求非空 string array 的 `values`；`Exists` 和 `DoesNotExist` MUST 要求 `values` 缺失或为空，非空 `values` MUST 失败，且输出不包含 `values` 字段。所有传入 values MUST 经 `base.slice.cleanup` 清洗后以 string array 输出，纯数字值遵循前述规范化规则。

#### Scenario: 原生 In

- **WHEN** 元素为 `{key: key, operator: In, values: [value1, value2]}`
- **THEN** 输出包含对应 `key`、`In` 和清洗后的 `values` 列表

#### Scenario: 原生 operator 大小写不敏感

- **WHEN** `operator` 为 `in`、`NOTIN` 或其他大小写变体
- **THEN** 输出分别为 `In`、`NotIn` 的规范大小写

#### Scenario: 原生 Exists

- **WHEN** 元素为 `{key: key2, operator: Exists}`
- **THEN** 输出包含 `key: key2`、`operator: Exists`，不包含 `values`

#### Scenario: 未知 operator 中断

- **WHEN** `operator` 不属于四个合法值的大小写变体
- **THEN** 失败并中断渲染

#### Scenario: In 缺少 values 中断

- **WHEN** `operator` 为 `In` 或 `NotIn`，且 `values` 缺失、为空或非 array
- **THEN** 失败并中断渲染

#### Scenario: Exists 携带非空 values 中断

- **WHEN** `operator` 为 `Exists` 或 `DoesNotExist`，且 `values` 非空
- **THEN** 失败并中断渲染

#### Scenario: 元素类型非法中断

- **WHEN** `matchExpressions` 元素既不是 string 也不是 map
- **THEN** 失败并中断渲染

### Requirement: 内置别名解析

系统 MUST 依赖 `base.get` 的内置 `*Alias` 能力解析 `matchExpressionsAlias`、`matchLabelsAlias`；别名非空时优先于对应规范键，缺失、`null` 或为空时回退规范键。系统 MUST NOT 识别显式别名 `mExprs`、`mLabels`。

#### Scenario: 内置别名等价

- **WHEN** 仅提供 `matchExpressionsAlias` 或 `matchLabelsAlias`
- **THEN** 行为分别与 `matchExpressions`、`matchLabels` 相同

#### Scenario: 内置别名优先

- **WHEN** 同时提供 `matchLabelsAlias` 和 `matchLabels`，且取值不同
- **THEN** `matchLabelsAlias` 生效

#### Scenario: 显式别名不生效

- **WHEN** 仅提供 `mExprs` 或 `mLabels`
- **THEN** 不读取这些字段，并按缺失处理

### Requirement: LabelSelector 渲染顺序与占位边界

系统 MUST 输出 LabelSelector map：`matchExpressions` 在非空时先渲染，`matchLabels` 必须随后渲染。`matchExpressions` 缺失或为空时 MUST 省略该字段。每个归一化后的 `matchExpressions` 项 MUST 传给 `definitions.labelSelectorRequirement`，其返回 MUST 为非空 map 并进入最终列表；返回为空、无效 YAML 或非 map 时 MUST 失败并中断渲染。本 change MUST NOT 创建该占位模板、文件或 `define`，MUST NOT 输出 `status` 或其他非 LabelSelector 字段。

#### Scenario: 最小输出

- **WHEN** 仅提供 `matchLabels`
- **THEN** 输出只包含 `matchLabels`

#### Scenario: 完整输出

- **WHEN** 同时提供 `matchLabels` 和 `matchExpressions`
- **THEN** 输出先包含 `matchExpressions`，再包含 `matchLabels`

#### Scenario: 空表达式省略

- **WHEN** `matchExpressions` 为空 array
- **THEN** 输出不包含 `matchExpressions`

#### Scenario: 占位模板委托

- **WHEN** 归一化项为 `{key: key, operator: In, values: [value]}`
- **THEN** 该项传给 `definitions.labelSelectorRequirement`，其返回 map 进入 `matchExpressions`

#### Scenario: 占位返回非法

- **WHEN** `definitions.labelSelectorRequirement` 返回空、无效 YAML 或非 map
- **THEN** 失败并中断渲染

### Requirement: apps.deploymentSpec 内置别名透传

`apps.deploymentSpec` MUST 在其 selector `pick` 结果中保留 `matchExpressionsAlias`、`matchLabelsAlias` 并原样传给 `definitions.labelSelector`；别名优先和缺失回退由 `base.get` 处理。`pick` 结果不含这两个字段时 MUST 不额外处理且不影响后续行为。现有 `matchLabels` 与 `base.labels` 合并逻辑 MUST 保持不变。

#### Scenario: 内置别名透传

- **WHEN** selector 提供 `matchLabelsAlias` 和 `matchExpressionsAlias`
- **THEN** 两个字段均保留在传给 `definitions.labelSelector` 的 map 中

#### Scenario: 内置别名缺失不影响

- **WHEN** selector 仅提供 `matchLabels`
- **THEN** 行为与未引入别名透传时相同

## 非目标

- 不支持 `gt`、`lt`、`>`、`<` 等数值比较选择器。
- 不支持显式别名 `mExprs`、`mLabels`。
- 不创建 `definitions.labelSelectorRequirement` 的模板、文件或 `define`；其调用契约由本 change 预留。
- 不扩展 LabelSelector 之外的字段，不输出 `status`。
