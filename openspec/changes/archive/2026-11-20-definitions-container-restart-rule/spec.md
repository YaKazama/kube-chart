---
updated_at: "2026-11-19T17:41:46Z"
---

# definitions.containerRestartRule 规格

## Purpose

按 Kubernetes `ContainerRestartRule` 结构渲染单个容器重启规则字段片段，供 `Container.restartPolicyRules` 数组逐项复用。

## ADDED Requirements

### Requirement: 重启规则字段片段渲染

系统 MUST 以单个 `restartPolicyRules` 元素作为上下文，接受 string 或 map，按官方字段顺序输出 `action` 与 `exitCodes`，并返回可解析为 map 的 YAML 内容；其他上下文类型 MUST 中断渲染。

`action` MUST 由本模板负责：缺失、为 `null`、为空字符串或取值不是 `restart`（大小写不敏感）时 MUST 中断渲染；合法时 MUST 归一化输出为 `Restart`。

`exitCodes` MUST 由 `definitions.containerRestartRuleOnExitCodes` 渲染。本模板 MUST 只负责确定其上下文、调用委托以及以 `exitCodes` 为父键输出，MUST NOT 输出 `exitCodes` 内部字段。`exitCodes` 缺失、为 `null`、为空对象或不是对象时 MUST 中断渲染；委托结果为非法 YAML 或空内容时 MUST 中断渲染。

对 map 上下文，本模板 MUST NOT 校验 `exitCodes.values` 的元素数量上限，也 MUST NOT 校验 `exitCodes.operator` 的枚举取值、大小写或内容合法性；这些职责由 `definitions.containerRestartRuleOnExitCodes` 承担。map 上下文除 `action`、`exitCodes` 外的键 MUST 被静默忽略。

#### Scenario: map 上下文渲染

- **WHEN** 上下文为 `{action: restart, exitCodes: {operator: in, values: [1, 2]}}`
- **THEN** 输出包含 `action: "Restart"` 与 `exitCodes`，且 `action` 位于 `exitCodes` 之前

#### Scenario: action 大小写不敏感归一化

- **WHEN** map 上下文的 `action` 为 `RESTART` 或 `Restart`
- **THEN** 输出为 `action: "Restart"`

#### Scenario: action 缺失

- **WHEN** map 上下文未提供 `action`，或其值为 `null` 或空字符串
- **THEN** 渲染中断

#### Scenario: action 取值非法

- **WHEN** map 上下文的 `action` 为 `stop`
- **THEN** 渲染中断

#### Scenario: exitCodes 缺失或类型非法

- **WHEN** map 上下文未提供 `exitCodes`，或其值为 `null`、空对象或非对象类型
- **THEN** 渲染中断

#### Scenario: exitCodes 原样下传

- **WHEN** map 上下文的 `exitCodes` 为 `{operator: notin, values: [0, 200]}`
- **THEN** `definitions.containerRestartRuleOnExitCodes` 收到的上下文与 `exitCodes` 取值等价，未增删键

#### Scenario: 子模板返回空内容

- **WHEN** `definitions.containerRestartRuleOnExitCodes` 返回空内容
- **THEN** 渲染中断，不输出缺少 `exitCodes` 的字段片段

#### Scenario: 未声明的键被忽略

- **WHEN** map 上下文包含 `action`、`exitCodes` 之外的键
- **THEN** 这些键不参与输出，也不导致中断

### Requirement: string 简写解析

string 上下文 MUST 按 `<action> <operator> (<int>, <int>, ...)` 完整匹配解析，所有段必填。`action` 与 `operator` 之间、`operator` 与括号之间的分隔符 MUST 为空白或逗号；括号内 values 之间 MUST 以逗号分隔。

`action` MUST 大小写不敏感匹配 `restart`。`operator` MUST 作为不含空白、逗号与括号的非空 token 捕获，并按原样传给 `definitions.containerRestartRuleOnExitCodes`，不做大小写归一化；本模板 MUST NOT 校验其枚举或内容合法性。

括号内 values MUST 转换为 integer array，显式 `0` MUST 保留；元素不是整数时 MUST 中断渲染。

括号内为空、整个 string 不匹配上述规则或 `action` 不是 `restart` 时 MUST 中断渲染。

清洗后传给 `definitions.containerRestartRuleOnExitCodes` 的上下文 MUST 只包含 `operator` 与 `values`，MUST NOT 包含 `action`。

#### Scenario: 标准形式

- **WHEN** string 为 `restart in (1, 2, 3)`
- **THEN** 输出 `action: "Restart"`，且 `exitCodes` 上下文为 `{operator: in, values: [1, 2, 3]}`

#### Scenario: 大小写不敏感

- **WHEN** string 为 `RESTART NotIn (7)`
- **THEN** 输出 `action: "Restart"`，且 `exitCodes` 上下文为 `{operator: NotIn, values: [7]}`

#### Scenario: operator 内容不由本模板校验

- **WHEN** string 为 `restart Once (1)`
- **THEN** 输出 `action: "Restart"`，且 `exitCodes` 上下文为 `{operator: Once, values: [1]}`

#### Scenario: 显式零保留

- **WHEN** string 为 `restart in (0, 1)`
- **THEN** `exitCodes.values` 为 `[0, 1]`

#### Scenario: 空 values

- **WHEN** string 为 `restart in ()`
- **THEN** 渲染中断

#### Scenario: 缺少括号

- **WHEN** string 为 `restart notin 1, 2`
- **THEN** 渲染中断

#### Scenario: values 非整数

- **WHEN** string 为 `restart in (a, 1)`
- **THEN** 渲染中断

#### Scenario: action 取值非法

- **WHEN** string 为 `stop in (1)`
- **THEN** 渲染中断

#### Scenario: 空内容

- **WHEN** string 为 `""` 或只含空白
- **THEN** 渲染中断

## MODIFIED Requirements

### Requirement: Container 字段片段渲染

系统 MUST 以单个 map 作为上下文，按官方字段顺序渲染 Container 字段片段，并返回可解析为 map 的 YAML 内容。

字段顺序固定为 `args`、`command`、`env`、`envFrom`、`image`、`imagePullPolicy`、`lifecycle`、`livenessProbe`、`name`、`ports`、`readinessProbe`、`resizePolicy`、`resources`、`restartPolicy`、`restartPolicyRules`、`securityContext`、`startupProbe`、`stdin`、`stdinOnce`、`terminationMessagePath`、`terminationMessagePolicy`、`tty`、`volumeDevices`、`volumeMounts`、`workingDir`。

`name` 与 `image` 必填，其余字段可选。`name` MUST 按 DNS_LABEL 校验。`env`、`envFrom`、`lifecycle`、`livenessProbe`、`ports`、`readinessProbe`、`resizePolicy`、`resources`、`restartPolicyRules`、`securityContext`、`startupProbe`、`volumeDevices`、`volumeMounts` MUST 委托同域子模板渲染；其余字段由本模板直接渲染。

`restartPolicyRules` 的数组元素 MUST 允许 string 简写或 map，其他类型 MUST 中断渲染。

#### Scenario: 渲染最简容器

- **WHEN** 上下文只提供 `name` 与 `image`
- **THEN** 输出包含 `image` 与 `name`，且 `image` 排在 `name` 之前

#### Scenario: 渲染完整结构

- **WHEN** 上下文提供全部 25 个字段且取值合法
- **THEN** 输出按固定顺序包含 25 个字段，字段间无缺失或错位

#### Scenario: name 缺失

- **WHEN** `name` 未提供、为 null、为空字符串或仅含空白
- **THEN** 渲染中断

#### Scenario: name 符合 DNS_LABEL

- **WHEN** `name` 为仅含小写字母、数字与 `-` 且首尾为字母或数字的字符串，长度不超过 63 字符
- **THEN** 校验通过并输出该 `name`

#### Scenario: name 不符合 DNS_LABEL

- **WHEN** `name` 含大写字母、下划线、点号或以 `-` 开头结尾，或长度超过 63 字符
- **THEN** 渲染中断，失败消息给出校验规则

#### Scenario: 委托字段

- **WHEN** `env`、`envFrom`、`lifecycle`、`livenessProbe`、`ports`、`readinessProbe`、`resizePolicy`、`resources`、`restartPolicyRules`、`securityContext`、`startupProbe`、`volumeDevices` 或 `volumeMounts` 非空
- **THEN** 该字段内容完全由对应子模板决定，本模板只传递上下文、回收结果并以该字段名为父键输出

#### Scenario: 委托结果为空

- **WHEN** 某个委托字段的上下文非空，但子模板返回空内容
- **THEN** 不输出该字段，且不中断渲染

#### Scenario: restartPolicyRules 接受 string 元素

- **WHEN** `restartPolicyRules` 的元素为 string，如 `restart in (1, 2)`
- **THEN** 该元素被交给 `definitions.containerRestartRule` 渲染，不因非 map 而中断

#### Scenario: restartPolicyRules 元素类型非法

- **WHEN** `restartPolicyRules` 的元素既不是 string 也不是 map
- **THEN** 渲染中断

#### Scenario: 布尔字段

- **WHEN** `stdin`、`stdinOnce` 或 `tty` 为布尔值
- **THEN** 输出对应的 YAML 布尔值，显式 `false` 同样输出

#### Scenario: 未知字段

- **WHEN** 上下文包含上述 25 个字段与引用字段以外的键
- **THEN** 该键被忽略，不参与输出

#### Scenario: 不输出 status

- **WHEN** 上下文包含 `status`
- **THEN** 该键被忽略

## 非目标

- 不实现 `definitions.containerRestartRuleOnExitCodes`；本 change 只锁定其调用契约。
- 不校验 `exitCodes.values` 的元素数量上限，也不校验 `exitCodes.operator` 的枚举取值、大小写或内容合法性。
- 不把 string 形式捕获到的 `operator` 归一化为固定大小写。
- 不改变 `definitions.container` 其余 24 个字段的既有行为。
- 不改变 `definitions.container.array` 的既有行为。
