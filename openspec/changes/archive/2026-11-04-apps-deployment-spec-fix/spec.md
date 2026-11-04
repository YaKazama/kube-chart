---
updated_at: "2026-11-04T10:52:37Z"
---

# Deployment strategy 解析修复规格

## MODIFIED Requirements

### Requirement: strategy 多类型归一化

系统 MUST 支持 `strategy` 以 string 简写或 map 两种形态提供，二者互斥。原生标量输入 MUST NOT 单独区分，取值结果统一按 string 处理；既不能归一化为有效 map 也不能匹配 string 简写的输入 MUST 失败并中断渲染。`strategy` 缺失、为空字符串，或 string 简写归一化后 `type`、`maxSurge`、`maxUnavailable` 三项均为空时 MUST 不渲染该字段。

归一化结果 MUST 只含 `type` 与可选 `rollingUpdate`，并以 map 形态委托 DeploymentStrategy 子模板渲染。子模板返回空字符串、`null`、无效 YAML 或非 map 时 MUST 失败并中断渲染，返回 map（含空 map）时 MUST 渲染于 `strategy` 字段下。

模板自身产生的失败消息 MUST 使用 `[apps.deploymentSpec]` 前缀。

string 简写形态：

- 输入 MUST 按 `type`、`maxSurge`、`maxUnavailable` 三个位置值一次性全量匹配，不得做部分匹配或分段匹配。
- `type` 位置 MUST 为 `Recreate`、`RollingUpdate`（大小写不敏感）、显式空字符串（`""` 或 `''`）或完全省略；其他取值 MUST 匹配失败。
- `maxSurge`、`maxUnavailable` 位置 MUST 为整数或百分比整数（`<整数>` 或 `<整数>%`）、显式空字符串（`""` 或 `''`）或省略；小数或其他形态 MUST 匹配失败。
- 位置值数量超过 3 个、存在未匹配的剩余输入或整体形态不符时 MUST 匹配失败；匹配失败 MUST 中断渲染。
- 相邻位置值之间的分隔符 MUST 为一个或多个空白、`:`、`,`、`/`、`|`、`*`、`^`、`@`、`#` 字符，其两侧 MAY 含空白；分隔符 MAY 完全省略。
- 每个位置值 MUST 先剔除外层引号并去除首尾空白后再使用，`""` 与 `''` MUST 归一化为空字符串。
- `type` 为空且至少一个滚动参数非空时，MUST 取默认值 `RollingUpdate` 并显式渲染 `type: RollingUpdate`。
- `maxSurge`、`maxUnavailable` 非空时 MUST 依次渲染为 `rollingUpdate` 下的 `maxSurge`、`maxUnavailable`；为空时 MUST 不渲染该字段。
- `type` 归一化后为 `Recreate` 时 MUST 不渲染 `rollingUpdate`，输入中的 `maxSurge`、`maxUnavailable` 静默忽略，不视为非法。

map 形态：

- MUST 只保留 `type`、`rollingUpdate` 两个键，其他键静默忽略。
- `type` 缺失、为 `null` 或为空字符串时 MUST 补充 `RollingUpdate`；非空且大小写不敏感等于 `recreate`、`rollingupdate` 时 MUST 归一化为官方拼写 `Recreate`、`RollingUpdate`；其他非空取值 MUST 原样透传，本层 MUST NOT 判定其合法性。
- `type` 归一化后为 `Recreate` 时 MUST 丢弃 `rollingUpdate`。
- `rollingUpdate` 存在时 MUST 为 map，否则 MUST 中断渲染；为空 map 时 MUST 丢弃该键。
- `rollingUpdate` 内部字段 MUST 原样透传，本层 MUST NOT 归一化、校验或改写其内容，也 MUST NOT 实现 `rollingUpdate` 的字段语义。

#### Scenario: 三段参数齐全

- **WHEN** `strategy` 为 `RollingUpdate 1 30%`
- **THEN** 渲染 `type: RollingUpdate`，`rollingUpdate` 含 `maxSurge` 与 `maxUnavailable`

#### Scenario: 省略 type

- **WHEN** `strategy` 为 `1 30%`
- **THEN** 渲染 `type: RollingUpdate`，`rollingUpdate` 含 `maxSurge` 与 `maxUnavailable`

#### Scenario: 仅提供 maxSurge

- **WHEN** `strategy` 为 `1`
- **THEN** 渲染 `type: RollingUpdate` 与 `rollingUpdate.maxSurge`

#### Scenario: 显式空 type 与空 maxSurge

- **WHEN** `strategy` 为 `RollingUpdate "" 30%` 或 `RollingUpdate '' 30%`
- **THEN** 两者渲染结果一致，均渲染 `type: RollingUpdate` 与 `rollingUpdate.maxUnavailable`

#### Scenario: 首槽为显式空字符串

- **WHEN** `strategy` 为 `"" 30%` 或 `'' 30%`
- **THEN** 两者渲染结果一致，均渲染 `type: RollingUpdate` 与 `rollingUpdate.maxSurge`

#### Scenario: 显式空 type 与两个参数

- **WHEN** `strategy` 为 `"" 1 30%` 或 `'' 1 30%`
- **THEN** 两者渲染结果一致，均渲染 `type: RollingUpdate` 与 `rollingUpdate.maxSurge`、`rollingUpdate.maxUnavailable`

#### Scenario: type 大小写不敏感

- **WHEN** `strategy` 为 `rollingupdate`
- **THEN** 渲染 `type: RollingUpdate`

#### Scenario: 原生标量按 string 处理

- **WHEN** `strategy` 为原生标量 `1`
- **THEN** 按 string 文本处理，渲染结果与 `strategy` 为字符串 `1` 一致

#### Scenario: 分隔符省略

- **WHEN** `strategy` 为 `RollingUpdate1`
- **THEN** 渲染结果与 `RollingUpdate 1` 一致

#### Scenario: 三项全空不渲染

- **WHEN** `strategy` 为 `""`、`''`、`"" ""` 或 `'' ''`
- **THEN** 不渲染 `strategy` 字段，不注入任何默认值

#### Scenario: type 有值但滚动参数全空

- **WHEN** `strategy` 为 `RollingUpdate "" ""`
- **THEN** 只渲染 `type: RollingUpdate`，不渲染 `rollingUpdate`

#### Scenario: Recreate 忽略滚动参数

- **WHEN** `strategy` 为 `Recreate 1 30%`
- **THEN** 只渲染 `type: Recreate`，不渲染 `rollingUpdate`，不报错

#### Scenario: map 输入透传滚动配置

- **WHEN** `strategy` 为 map 且只提供 `rollingUpdate: {maxSurge: 1}`
- **THEN** 渲染 `type: RollingUpdate` 与原样 `rollingUpdate`

#### Scenario: map 输入类型归一化

- **WHEN** `strategy` 为 `{type: recreate}`
- **THEN** 渲染 `type: Recreate`

#### Scenario: map 输入 type 为空

- **WHEN** `strategy` 为 map 且 `type` 缺失、为 `null` 或为空字符串
- **THEN** 渲染 `type: RollingUpdate`

#### Scenario: map 输入未知 type 原样透传

- **WHEN** `strategy` 为 `{type: BlueGreen}`
- **THEN** 向 DeploymentStrategy 子模板传递 `type: BlueGreen`，本层不中断渲染，枚举门禁由子模板执行

#### Scenario: map 输入 rollingUpdate 非 map

- **WHEN** `strategy` 为 `{rollingUpdate: 1}`
- **THEN** 失败并中断渲染，失败消息前缀为 `apps.deploymentSpec`

#### Scenario: map 输入 rollingUpdate 为空 map

- **WHEN** `strategy` 为 `{rollingUpdate: {}}`
- **THEN** 只渲染 `type: RollingUpdate`，不渲染 `rollingUpdate`

#### Scenario: map 输入内部字段不被改写

- **WHEN** `strategy` 为 map 且 `rollingUpdate` 含本层未知字段或非整数形态取值
- **THEN** 该字段原样渲染，本层不中断渲染

#### Scenario: 缺失不渲染

- **WHEN** 上下文未提供 `strategy`
- **THEN** 不渲染 `strategy` 字段

#### Scenario: 空字符串不渲染

- **WHEN** `strategy` 为空字符串
- **THEN** 不渲染 `strategy` 字段

#### Scenario: string 匹配失败中断

- **WHEN** `strategy` 为 `BlueGreen`、`1 30% 5`、`1 30% 5 6`、`1.5` 或 `-1`
- **THEN** 全部失败并中断渲染，失败消息前缀为 `apps.deploymentSpec`

#### Scenario: 非法形态中断

- **WHEN** `strategy` 既非 string 简写也非 map
- **THEN** 失败并中断渲染，失败消息前缀为 `apps.deploymentSpec`

#### Scenario: 合法输入均在 strategy 下渲染 map

- **WHEN** 任一合法输入完成渲染
- **THEN** `strategy` 为 map，且只含 `type` 与可选 `rollingUpdate`

#### Scenario: 子模板空返回中断

- **WHEN** DeploymentStrategy 子模板返回空字符串或 `null`
- **THEN** 失败并中断渲染

#### Scenario: 子模板非法返回中断

- **WHEN** DeploymentStrategy 子模板返回无效 YAML 或非 map
- **THEN** 失败并中断渲染

## 非目标

- 不创建 DeploymentStrategy 子模板与 `rollingUpdate` 子模板；两者为契约引用，由各自 change 实现。
- 不校验 `maxSurge`、`maxUnavailable` 的数值形态、百分比上限或二者联动约束。
- 不涉及 `minReadySeconds`、`progressDeadlineSeconds`、`revisionHistoryLimit`、`paused`、`selector` 与 `template` 的既有行为。
- 不实现 `rollingUpdate` 内部字段的归一化、别名处理与类型判断。
