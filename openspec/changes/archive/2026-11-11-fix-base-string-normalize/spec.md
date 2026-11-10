---
updated_at: "2026-11-10T16:23:55Z"
---

# base.string.normalize 存量调用点改造规格

## MODIFIED Requirements

### Requirement: 字符串字段按 YAML 标量语义解码

系统 MUST 把既有 string 字段的 YAML 序列化文本按单个 YAML 标量解码后使用，MUST NOT 输出 YAML 引号、引号内转义序列或块标量指示符。

解码结果 MUST 去除首尾空白；去除后为空的内容 MUST 视为未设置，可选字段 MUST NOT 输出，必填字段 MUST 中断渲染。

带引号的内容 MUST 解码为其字面值：`"on"`、`'yes'`、`"a: b"` MUST 分别解码为 `on`、`yes`、`a: b`。`"007"` MUST 解码为 `007`。

解码结果交给字段既有的渲染器输出；该渲染器的零折叠规则仍然生效，因此 `"007"` 最终输出为 `07`，与改造前一致，本 change 不改变该行为。

引号内的转义与单引号双写 MUST 按 YAML 语义解码：`"\n"` MUST 输出换行符，`'it''s'` MUST 输出 `it's`。

多行标量 MUST 输出解码后的多行内容，MUST NOT 出现 `|` 或 `>` 指示符。

解码结果为 `null` 或空内容时 MUST 视为未设置。

本行为适用于以下字段：

- `apps.deploymentSpec` 的 `strategy` 以及 `strategy.type`
- `core.podSpec` 的 `os` 字符串简写、`hostnameOverride`、`dnsPolicy`、`hostname`、`nodeName`、`preemptionPolicy`、`priorityClassName`、`restartPolicy`、`runtimeClassName`、`schedulerName`、`serviceAccountName`、`subdomain`
- `apps.deploymentStrategy` 的 `type`
- `definitions.podOS` 的 `name`
- `definitions.hostAlias` 的 `ip`
- `definitions.localObjectReference` 的 `name`
- `definitions.podReadinessGate` 的 `conditionType`
- `definitions.podResourceClaim` 的 `name`、`resourceClaimName`、`resourceClaimTemplateName`
- `definitions.labelSelector` 的 `matchExpressions` 条目 `key` 与 `operator`
- `definitions.labelSelectorRequirement` 的 `key` 与 `operator`
- `definitions.nodeSelectorTerm` 的 `key` 与 `operator`
- `definitions.nodeSelectorRequirement` 的 `key` 与 `operator`
- `definitions.podAffinityTerm` 的 `topologyKey`

系统 MUST 在上述字段的输入解码为布尔、数值、map 或 list 时中断渲染，MUST NOT 把这类取值转为字符串输出。

失败消息 MUST 以 `[base.string.normalize]` 开头并指明实际类型，MUST NOT 携带调用方模板名或字段路径。字段自身的必填、语法与枚举校验 MUST 保持原有失败位置与触发条件。

#### Scenario: 带引号的标量解码为字面值

- **WHEN** 任一上述字段的取值为 `"on"`、`'yes'` 或 `"a: b"`
- **THEN** 该字段由 `on`、`yes`、`a: b` 渲染输出

#### Scenario: 引号数字零折叠沿用渲染器规则

- **WHEN** `nodeName: "007"`
- **THEN** 解码结果为 `007`，最终输出 `nodeName: "07"`，与改造前一致

#### Scenario: 引号内转义被解码

- **WHEN** `conditionType` 取值为 `"a\nb"`（引号内含转义序列）
- **THEN** 输出值为包含实际换行的两行内容

#### Scenario: 单引号双写被解码

- **WHEN** `nodeName` 取值为 `'it''s'`
- **THEN** 输出值为 `it's`

#### Scenario: 多行标量被解码

- **WHEN** `subdomain` 取值为块标量形态的多行内容
- **THEN** 输出值为解码后的多行内容，不含 `|` 或 `>` 指示符

#### Scenario: 首尾空白被去除

- **WHEN** 可选字段取值为 `'  spaced  '`
- **THEN** 输出值为 `spaced`

#### Scenario: 仅空白视为未设置

- **WHEN** 可选字段取值为 `'   '`，或必填字段取值为 `'   '`
- **THEN** 可选字段不输出，必填字段中断渲染并提示字段为空

#### Scenario: null 与空值视为未设置

- **WHEN** 可选字段取值为 YAML `null`、`~` 或空字符串
- **THEN** 不输出该字段，渲染不中断

#### Scenario: 取值不是字符串

- **WHEN** 任一上述字段的取值为原生布尔、数值、map 或 list
- **THEN** 渲染中断，失败消息以 `[base.string.normalize]` 开头并指明实际类型

### Requirement: 渲染 DeploymentSpec 整数字段

`apps.deploymentSpec` MUST 按十进制整数处理 `minReadySeconds`、`progressDeadlineSeconds`、`replicas`、`revisionHistoryLimit` 四个字段。

系统 MUST 只接受序列化后为十进制整数形态的取值，包括原生整数与整数值浮点。带引号的纯数字字符串（如 `"3"`）MUST 视为非法并中断渲染。

四个字段缺失或为空时 MUST NOT 输出该字段，MUST NOT 由模板提供任何默认值，由 Kubernetes API 自身默认值生效。

字段取值为 `0` 时：`minReadySeconds`、`progressDeadlineSeconds`、`revisionHistoryLimit` MUST NOT 输出该字段；`replicas` MUST 输出 `0`。

字段取值为正整数时 MUST 输出该整数。YAML 中带正号的整数与同值整数等价，`+5` MUST 与 `5` 输出相同结果。整数值浮点与同值整数等价，`3.0` MUST 与 `3` 输出相同结果。

字段取值为负数、带非零小数部分的浮点数、非数字文本、布尔值、map 或 list 时 MUST 中断渲染。

字段取值在传入后 MUST 序列化为不带符号、不带小数点的十进制整数字符串。`values.yaml` 来源的数值由 Helm 解析为浮点数，在 7 位及以上整数时会以科学计数法序列化，因此从其来源的取值上限为 `999999`，`1000000` 及以上 MUST 中断渲染。直接以原生整数传入时不受该限制，上限为 `2147483647`，超过时 MUST 中断渲染。

#### Scenario: 渲染原生整数

- **WHEN** `replicas: 3`
- **THEN** 输出 `replicas: 3`

#### Scenario: 带引号的纯数字字符串中断

- **WHEN** `replicas: "3"`、`minReadySeconds: "0"` 或 `progressDeadlineSeconds: "600"`
- **THEN** 渲染中断，渲染不产生该 Deployment

#### Scenario: 带正号整数与同值整数一致

- **WHEN** `minReadySeconds: +5`
- **THEN** 输出 `minReadySeconds: 5`

#### Scenario: 整数值浮点与同值整数一致

- **WHEN** `replicas: 3.0`
- **THEN** 输出 `replicas: 3`

#### Scenario: 零值按字段语义处理

- **WHEN** `replicas: 0`、`minReadySeconds: 0`、`progressDeadlineSeconds: 0`、`revisionHistoryLimit: 0`
- **THEN** 输出 `replicas: 0`，且不输出 `minReadySeconds`、`progressDeadlineSeconds`、`revisionHistoryLimit`

#### Scenario: 缺失时不输出

- **WHEN** `replicas`、`progressDeadlineSeconds`、`revisionHistoryLimit` 或 `minReadySeconds` 未提供
- **THEN** 均不输出对应字段，渲染不中断，由 Kubernetes API 采用自身默认值

#### Scenario: 空字符串不输出

- **WHEN** `replicas: ""` 或 `revisionHistoryLimit: ""`
- **THEN** 不输出对应字段，渲染不中断

#### Scenario: 负数中断

- **WHEN** `replicas: -1`
- **THEN** 渲染中断，渲染不产生该 Deployment

#### Scenario: 非整数中断

- **WHEN** `replicas: 1.5`、`replicas: abc`、`replicas: true`
- **THEN** 渲染中断，渲染不产生该 Deployment

#### Scenario: 超出 int32 上限中断

- **WHEN** `progressDeadlineSeconds: 3147483648`
- **THEN** 渲染中断，渲染不产生该 Deployment

#### Scenario: int32 上限边界通过

- **WHEN** 以原生整数传入 `progressDeadlineSeconds: 2147483647`
- **THEN** 输出 `progressDeadlineSeconds: 2147483647`

#### Scenario: values.yaml 来源的大整数因科学计数法中断

- **WHEN** `values.yaml` 中声明 `progressDeadlineSeconds: 2147483647`
- **THEN** 渲染中断，渲染不产生该 Deployment

#### Scenario: values.yaml 来源的有效上限

- **WHEN** `values.yaml` 中声明 `replicas: 999999`
- **THEN** 输出 `replicas: 999999`

#### Scenario: values.yaml 来源超出有效上限中断

- **WHEN** `values.yaml` 中声明 `replicas: 1000000`
- **THEN** 渲染中断，渲染不产生该 Deployment

### Requirement: 渲染 PodSpec 整数字段

`core.podSpec` MUST 按十进制整数处理 `activeDeadlineSeconds` 与 `terminationGracePeriodSeconds`。

系统 MUST 只接受序列化后为十进制整数形态的取值，包括原生整数与整数值浮点。带引号的纯数字字符串 MUST 视为非法并中断渲染。

`activeDeadlineSeconds` 取值大于 0 时 MUST 输出该字段；取值为 `0` 时 MUST NOT 输出该字段。

`terminationGracePeriodSeconds` 取值大于等于 0 时 MUST 输出该字段，包含 `0`。

上述两个字段取值为负数、带非零小数部分的浮点数、非数字文本、布尔值、map 或 list 时 MUST 中断渲染。整数值浮点与同值整数等价，`30.0` MUST 与 `30` 输出相同结果。

与 `apps.deploymentSpec` 的整数字段相同，取值在传入后 MUST 序列化为十进制整数字符串；`values.yaml` 来源的取值上限为 `999999`，`1000000` 及以上 MUST 中断渲染。

#### Scenario: activeDeadlineSeconds 正值输出

- **WHEN** `activeDeadlineSeconds: 30`
- **THEN** 输出 `activeDeadlineSeconds: 30`

#### Scenario: activeDeadlineSeconds 零值不输出

- **WHEN** `activeDeadlineSeconds: 0`
- **THEN** 不输出 `activeDeadlineSeconds`

#### Scenario: terminationGracePeriodSeconds 零值输出

- **WHEN** `terminationGracePeriodSeconds: 0`
- **THEN** 输出 `terminationGracePeriodSeconds: 0`

#### Scenario: 带引号的纯数字字符串中断

- **WHEN** `terminationGracePeriodSeconds: "30"` 或 `activeDeadlineSeconds: "0"`
- **THEN** 渲染中断，渲染不产生该 Pod 模板

#### Scenario: 负数中断

- **WHEN** `activeDeadlineSeconds: -1` 或 `terminationGracePeriodSeconds: -1`
- **THEN** 渲染中断，渲染不产生该 Pod 模板

#### Scenario: 非整数中断

- **WHEN** `terminationGracePeriodSeconds: 1.5` 或 `activeDeadlineSeconds: abc`
- **THEN** 渲染中断，渲染不产生该 Pod 模板

#### Scenario: values.yaml 来源的大整数因科学计数法中断

- **WHEN** `values.yaml` 中声明 `terminationGracePeriodSeconds: 1000000`
- **THEN** 渲染中断，渲染不产生该 Pod 模板

### Requirement: 渲染 DeploymentStrategy type 字段

`apps.deploymentStrategy` MUST 只接受 `Recreate` 与 `RollingUpdate` 两个 `type` 取值。

`type` 缺失、为 YAML `null` 或为空字符串时 MUST 视为未设置，MUST NOT 输出 `type`，并按隐式默认值 `RollingUpdate` 决定 `rollingUpdate` 是否渲染。

`type` 为字面字符串 `null` 或其他不在枚举内的取值时 MUST 中断渲染。

#### Scenario: 合法枚举值

- **WHEN** `type: Recreate` 或 `type: RollingUpdate`
- **THEN** 输出对应的 `type`

#### Scenario: 缺失或 YAML null

- **WHEN** `type` 未提供、为 YAML `null` 或为空字符串
- **THEN** 不输出 `type`，且按 `RollingUpdate` 语义处理 `rollingUpdate`

#### Scenario: 字面字符串 null 中断

- **WHEN** `type: "null"`
- **THEN** 渲染中断，渲染不产生该 Deployment

#### Scenario: 枚举外取值中断

- **WHEN** `type: "recreate2"` 或其他不在枚举内的取值
- **THEN** 渲染中断，渲染不产生该 Deployment

### Requirement: 渲染 DeploymentSpec selector 与 strategy

`apps.deploymentSpec` 的 `selector` 为必填字段。`selector` 缺失、为 YAML `null`、为空字符串或无法恢复为 map 时 MUST 中断渲染。`selector` 为空 map 时 MUST 正常合入基础标签并输出 `matchLabels`。

`selector` 中的 `matchExpressions` 与 `matchLabels` MUST 原样交由 `definitions.labelSelector` 渲染，本层 MUST NOT 自行解析其内部结构。

`apps.deploymentSpec` 的 `strategy` 为可选字段。`strategy` 为 YAML `null` 时 MUST 视为未设置。

`strategy` 为 map 时，`type` 按大小写不敏感匹配 `recreate`、`rollingupdate` 归一化为规范枚举；`type` 缺失、为 YAML `null` 或为空字符串时使用 `RollingUpdate`；其他取值 MUST 交由 `apps.deploymentStrategy` 做枚举校验，不在枚举内时中断渲染。

`strategy` 为字符串简写时，MUST 按 `类型 [maxSurge] [maxUnavailable]` 解析，三个位置的空引号占位符 MUST 视为未设置该位置。

`strategy` 为原生数值时 MUST 中断渲染。

`strategy` 归一化结果为空时 MUST NOT 输出该字段；子模板返回空内容或非法内容时 MUST 中断渲染。

#### Scenario: selector 只含基础标签

- **WHEN** `selector: {}`
- **THEN** 输出仅含基础标签的 `matchLabels`

#### Scenario: selector 缺失或为 null

- **WHEN** `selector` 未提供、为 YAML `null` 或为空字符串
- **THEN** 渲染中断，渲染不产生该 Deployment

#### Scenario: selector 不是 map

- **WHEN** `selector: "null"`、`selector: 5` 或 `selector: []`
- **THEN** 渲染中断，渲染不产生该 Deployment

#### Scenario: strategy 为 map

- **WHEN** `strategy` 为包含 `type: recreate` 的 map
- **THEN** 输出 `type: Recreate`

#### Scenario: strategy map 的 type 不在枚举内

- **WHEN** `strategy` 为包含 `type: "recreate2"` 的 map
- **THEN** 渲染中断，渲染不产生该 Deployment

#### Scenario: strategy 为简写

- **WHEN** `strategy: "RollingUpdate 25% 10%"`
- **THEN** 输出 `type: RollingUpdate`、`maxSurge: 25%`、`maxUnavailable: 10%`

#### Scenario: 简写中的空占位符

- **WHEN** `strategy: "RollingUpdate \"\" 10%"` 或 `strategy: "RollingUpdate '' 10%"`
- **THEN** 输出 `type: RollingUpdate` 与 `maxUnavailable: 10%`，不输出 `maxSurge`

#### Scenario: 简写只含空占位符

- **WHEN** `strategy: "\"\""` 或 `strategy: "''"`
- **THEN** 不输出 `strategy`，渲染不中断

#### Scenario: strategy 为 null

- **WHEN** `strategy` 为 YAML `null`
- **THEN** 不输出 `strategy`，渲染不中断

#### Scenario: strategy 为原生数值

- **WHEN** `strategy: 5`
- **THEN** 渲染中断，渲染不产生该 Deployment

## 非目标

- 不修改 `base.string.normalize`、`base.int`、`base.int.range`、`base.get`、`base.field` 的实现与失败边界。
- 不把 bool 字段（`core.podSpec` 的 7 个开关）改用 `base.string.normalize`；其现有接受范围与失败行为保持不变。
- 不把 `IntOrString` 字段（`apps.rollingUpdateDeployment` 的 `maxSurge`、`maxUnavailable`）改用 `base.string.normalize` 或整数字段链路；其现有接受范围与失败行为保持不变。
- 不改变 `definitions.preferredSchedulingTerm` 与 `definitions.weightedPodAffinityTerm` 的 `weight` 行为。
- 不改变 `definitions.nodeAffinity` 对 `preferredDuringSchedulingIgnoredDuringExecution` 条目 `weight` 的父级标量门禁；该处需同时接受原生数值，与字符串解码语义不同，不在本次改造范围。
- 不处理 `base.slice.cleanup` 的整数溢出与 affinity map 兼容问题。
- 不消除 `IntOrString` 与 `weight` 字段链路中的 YAML 引号剥离处理。
- 不改变 `base.string` 的零折叠规则；引号数字经字段渲染器输出为零折叠后的结果，不因本次解码改造而变化。
- 不修改 `base.get` 的标量序列化方式；`values.yaml` 来源的大整数因科学计数法而不可用的限制由该能力决定，本 change 仅按事实记录其边界。
- 不新增或重命名任何命名模板。
