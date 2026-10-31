---
confirmed: true
updated_at: "2026-10-26T09:30:03Z"
---

# Apps DeploymentSpec 模板规格

## Purpose

为 apps/v1 Deployment 提供 DeploymentSpec 字段片段渲染，供 `apps.deployment` 委托调用。按 Kubernetes API 契约归一化整数字段、布尔字段、`selector`、`strategy` 与 `template`，并委托对应子模板完成嵌套结构渲染。

## ADDED Requirements

### Requirement: integer 字段默认值与范围约束

系统 MUST 对 `minReadySeconds`、`progressDeadlineSeconds`、`replicas`、`revisionHistoryLimit` 四个 integer 字段应用统一约束：缺失时渲染默认值；值为负数时不渲染该字段；值超过上限 `2147483647` 时失败并中断渲染。默认值为建议值，可被用户覆盖：`minReadySeconds` 为 `0`，`progressDeadlineSeconds` 为 `600`，`replicas` 为 `1`，`revisionHistoryLimit` 为 `10`。

#### Scenario: 缺失时渲染默认值

- **WHEN** 上下文未提供任一 integer 字段
- **THEN** 渲染 `minReadySeconds: 0`、`progressDeadlineSeconds: 600`、`replicas: 1`、`revisionHistoryLimit: 10`

#### Scenario: 用户覆盖默认值

- **WHEN** 上下文提供 `replicas: 3`
- **THEN** 渲染 `replicas: 3`，不渲染默认值

#### Scenario: 负数不渲染

- **WHEN** 上下文提供 `replicas: -1`
- **THEN** 不渲染 `replicas` 字段，不报错，其余字段不受影响

#### Scenario: 超过上限中断

- **WHEN** 上下文提供 `minReadySeconds: 2147483648`
- **THEN** 失败并中断渲染

#### Scenario: 上限边界有效

- **WHEN** 上下文提供 `revisionHistoryLimit: 2147483647`
- **THEN** 渲染 `revisionHistoryLimit: 2147483647`

#### Scenario: 非整数类型中断

- **WHEN** 上下文提供非整数且非整数字符串的值，如 `replicas: "abc"`
- **THEN** 失败并中断渲染

### Requirement: paused 默认值

系统 MUST 在 `paused` 缺失时渲染默认值 `false`。`paused` 为 boolean 类型，非法类型失败并中断渲染。

#### Scenario: 缺失时渲染默认值

- **WHEN** 上下文未提供 `paused`
- **THEN** 渲染 `paused: false`

#### Scenario: 布尔值渲染

- **WHEN** 上下文提供 `paused: true`
- **THEN** 渲染 `paused: true`

#### Scenario: 非法类型中断

- **WHEN** 上下文提供非 boolean 类型的 `paused`
- **THEN** 失败并中断渲染

### Requirement: selector 必填与标签合并

系统 MUST 在 `selector` 缺失或为 `nil` 时失败并中断渲染。`selector` 必须为 map 类型，清洗后最多保留 `matchLabels` 与 `matchExpressions` 字段，其余字段静默忽略。`matchLabels` MUST 与 `base.labels`（透传当前上下文 `.`）的输出执行左优合并，`selector.matchLabels` 优先于 `base.labels`。清洗后的 `selector` map 作为上下文传递给 `definitions.labelSelector`，返回值 MUST 为非空 YAML map 并渲染于 `selector` 字段下；返回为空、无效 YAML 或非 map 时失败并中断渲染。

#### Scenario: 缺失中断

- **WHEN** 上下文未提供 `selector` 或其值为 `nil`
- **THEN** 失败并中断渲染

#### Scenario: 左优合并

- **WHEN** `selector.matchLabels` 为 `{app: web}` 且 `base.labels` 输出为 `{app: base, name: my-app}`
- **THEN** 传递给 `definitions.labelSelector` 的 `matchLabels` 为 `{app: web, name: my-app}`

#### Scenario: matchLabels 缺失

- **WHEN** `selector` 仅提供 `matchExpressions`
- **THEN** `matchLabels` 取 `base.labels` 输出，与 `matchExpressions` 一并向下传递

#### Scenario: 冗余字段忽略

- **WHEN** `selector` 包含 `matchLabels`、`matchExpressions` 之外的字段
- **THEN** 静默忽略冗余字段

#### Scenario: 非法类型中断

- **WHEN** `selector` 不是 map 类型
- **THEN** 失败并中断渲染

#### Scenario: 显式空 map 有效

- **WHEN** `selector` 为 `{}`
- **THEN** 不报错，`matchLabels` 取 `base.labels` 输出

#### Scenario: 子模板空返回中断

- **WHEN** `definitions.labelSelector` 返回为空
- **THEN** 失败并中断渲染

#### Scenario: 子模板非法返回中断

- **WHEN** `definitions.labelSelector` 返回无效 YAML 或非 map
- **THEN** 失败并中断渲染

### Requirement: strategy 多类型归一化

系统 MUST 支持 `strategy` 为 string 或 map 类型且二者互斥，其他类型失败并中断渲染；`strategy` 缺失时不渲染该字段。归一化结果作为上下文传递给 `definitions.deploymentStrategy`，返回值 MUST 为 YAML map 并渲染于 `strategy` 字段下；返回为空字符串或 `null`、无效 YAML 或非 map 时失败并中断渲染，返回空 map 时正常渲染。

map 类型：取 `type`、`rollingUpdate` 字段向下传递，其余字段静默忽略；允许空 `strategy` 向下传递。

string 类型正则契约：

- 运行时表达式：`^(Recreate|RollingUpdate)(?:\s+(.*))?$`。
- 匹配语义：全量匹配（`^` 与 `$` 锚定），提取前必须先确认匹配。
- 捕获组：第 1 组归一化为 `type`（string，`Recreate` 或 `RollingUpdate`）；第 2 组归一化为 `rollingUpdate`（string，可选捕获，未命中时为空字符串，提取后去除首尾空白）。
- 不匹配边界：失败并中断渲染。

string 匹配后 MUST 清洗为包含 `type` 与 `rollingUpdate` 字段的 map 向下传递，`rollingUpdate` 保持 string 类型，其内部结构不在本层解析。

#### Scenario: 缺失不渲染

- **WHEN** 上下文未提供 `strategy`
- **THEN** 不渲染 `strategy` 字段

#### Scenario: map 分支

- **WHEN** `strategy` 为 `{type: RollingUpdate, rollingUpdate: {...}, extra: x}`
- **THEN** 向 `definitions.deploymentStrategy` 传递 `{type: RollingUpdate, rollingUpdate: {...}}`，`extra` 静默忽略

#### Scenario: 空 map 向下传递

- **WHEN** `strategy` 为 `{}`
- **THEN** 向 `definitions.deploymentStrategy` 传递空 map

#### Scenario: string 仅类型

- **WHEN** `strategy` 为 `"Recreate"`
- **THEN** 归一化为 `{type: Recreate, rollingUpdate: ""}` 向下传递

#### Scenario: string 带参数

- **WHEN** `strategy` 为 `"RollingUpdate 25% 5"`
- **THEN** 归一化为 `{type: RollingUpdate, rollingUpdate: "25% 5"}` 向下传递

#### Scenario: string 不匹配中断

- **WHEN** `strategy` 为 `"BlueGreen"`
- **THEN** 失败并中断渲染

#### Scenario: 非法类型中断

- **WHEN** `strategy` 既非 string 也非 map
- **THEN** 失败并中断渲染

#### Scenario: 子模板空返回中断

- **WHEN** `definitions.deploymentStrategy` 返回空字符串或 `null`
- **THEN** 失败并中断渲染

#### Scenario: 子模板非法返回中断

- **WHEN** `definitions.deploymentStrategy` 返回无效 YAML 或非 map
- **THEN** 失败并中断渲染

#### Scenario: 子模板空 map 返回

- **WHEN** `definitions.deploymentStrategy` 返回 `{}`
- **THEN** 正常渲染空 `strategy` map

### Requirement: template 必填透传

系统 MUST 将当前上下文 `.` 透传给 `core.podTemplateSpec`，返回值 MUST 为非空 YAML map 并渲染于 `template` 字段下；返回为空、无效 YAML 或非 map 时失败并中断渲染。

#### Scenario: 正常渲染

- **WHEN** `core.podTemplateSpec` 返回非空 YAML map
- **THEN** 渲染于 `template` 字段下

#### Scenario: 空输出中断

- **WHEN** `core.podTemplateSpec` 返回为空
- **THEN** 失败并中断渲染

#### Scenario: 子模板非法返回中断

- **WHEN** `core.podTemplateSpec` 返回无效 YAML 或非 map
- **THEN** 失败并中断渲染

## 非目标

- 不实现 `definitions.labelSelector`、`definitions.deploymentStrategy`、`core.podTemplateSpec`；三者为契约引用，由各自 change 实现。
- 不解析 `rollingUpdate` 字符串的内部结构，由 `definitions.deploymentStrategy` 负责。
- 不渲染本规格未列出的 DeploymentSpec 字段。
