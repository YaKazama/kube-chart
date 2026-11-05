---
updated_at: "2026-11-05T06:01:46Z"
---

# apps.rollingUpdateDeployment 规格

## Purpose

为 Deployment 的 `strategy.rollingUpdate` 提供 `RollingUpdateDeployment` 字段片段，校验滚动更新参数，并规避 Kubernetes API 对 `maxSurge`、`maxUnavailable` 的联动约束。

## ADDED Requirements

### Requirement: 滚动更新参数渲染

系统 MUST 把入参 `maxSurge`、`maxUnavailable` 渲染为 `rollingUpdate` 下的同名字段，字段顺序 MUST 为 `maxSurge` 在前、`maxUnavailable` 在后。

每个字段 MUST 在自身取值为非空时渲染，MUST 在其缺失或为空时省略该字段。

显式 `null`（含 `~` 与空值键）MUST 按空值处理，与缺失等价，MUST NOT 参与形态校验，MUST NOT 渲染该字段。

系统 MUST NOT 渲染 `status` 或其他字段，MUST NOT 为缺失字段补充 `25%` 等 API 默认值。

两字段 MUST 支持同级 `<字段>Alias` 键名，且其值优先于同名字段。

百分比取值 MUST 以不带引号的字符串形式输出，例如 `maxSurge: 25%`。

#### Scenario: 两个字段均提供

- **WHEN** 入参为 `{maxSurge: 1, maxUnavailable: "30%"}`
- **THEN** 渲染 `maxSurge` 与 `maxUnavailable` 两个字段，且 `maxSurge` 在前

#### Scenario: 只提供一个字段

- **WHEN** 入参只包含 `maxSurge`
- **THEN** 只渲染 `maxSurge`，不渲染 `maxUnavailable`，也不补充任何默认值

#### Scenario: 两个字段均缺失

- **WHEN** 入参为空 map
- **THEN** 返回空输出，不渲染任何字段，不中断渲染

#### Scenario: 使用 Alias 键

- **WHEN** 入参为 `{maxSurgeAlias: 2, maxSurge: 5}`
- **THEN** 渲染 `maxSurge: 2`

#### Scenario: 显式 null 取值

- **WHEN** 入参为 `{maxSurge: null}`、`{maxSurge: ~}` 或含空值键 `maxSurge:` 的等价写法
- **THEN** 不渲染该字段，不中断渲染

#### Scenario: 空别名回退规范键

- **WHEN** 入参为 `{maxSurgeAlias: null, maxSurge: 5}`
- **THEN** 渲染 `maxSurge: 5`

### Requirement: 取值形态校验

系统 MUST 只接受非负整数与非负百分比两种取值形态。

`maxSurge` MUST 接受任意非负整数与任意非负百分比，百分比 MUST NOT 设置上限。

`maxUnavailable` MUST 接受任意非负整数；百分比 MUST 限定在 `0%` 至 `100%`，超过 `100%` MUST 失败。

小数（例如 `1.5` 等小数部分非零的写法）、负数、带符号值与其他形态 MUST 失败并中断渲染。

系统 MUST NOT 为小数形态承担额外判定：YAML 原生浮点 `1.0` 归一化后与整数 `1` 等价，MUST 按整数渲染。

系统 MUST 为 `maxSurge`、`maxUnavailable` 分别使用独立表达式校验，MUST 在最终字段渲染时再次经既有 IntOrString 校验确认形态。

#### Scenario: 整数与百分比形态

- **WHEN** 入参为 `{maxSurge: 3, maxUnavailable: "25%"}`
- **THEN** 渲染 `maxSurge: 3` 与 `maxUnavailable: 25%`

#### Scenario: maxSurge 百分比超过 100%

- **WHEN** 入参为 `{maxSurge: "150%"}`
- **THEN** 正常渲染 `maxSurge`

#### Scenario: maxUnavailable 百分比超过 100%

- **WHEN** 入参为 `{maxUnavailable: "101%"}`
- **THEN** 中断渲染

#### Scenario: maxUnavailable 整数不受百分比上限约束

- **WHEN** 入参为 `{maxUnavailable: 150}`
- **THEN** 正常渲染 `maxUnavailable`

#### Scenario: 小数部分非零的小数

- **WHEN** 入参为 `{maxSurge: 1.5}`
- **THEN** 中断渲染

#### Scenario: 小数部分为 0 的浮点

- **WHEN** 入参为 `{maxSurge: 1.0}`
- **THEN** 按整数渲染 `maxSurge: 1`

#### Scenario: 非法取值

- **WHEN** 入参为 `{maxUnavailable: "-1"}` 或 `{maxSurge: "abc"}`
- **THEN** 中断渲染

### Requirement: 两个字段同时为 0 时省略

`maxSurge` 与 `maxUnavailable` 同时按数值等价于 0（`0`、`00`、`0%`、`00%` 等写法）时，系统 MUST 不渲染任何字段并返回空输出，由 Kubernetes API 采用隐式默认值。

只有一侧等价于 0 时，该字段 MUST 正常渲染，不得省略。

#### Scenario: 两个字段同时为整数 0

- **WHEN** 入参为 `{maxSurge: 0, maxUnavailable: 0}`
- **THEN** 返回空输出，不渲染任何字段，不中断渲染

#### Scenario: 两个字段同时为百分比 0%

- **WHEN** 入参为 `{maxSurge: "0%", maxUnavailable: "0%"}`
- **THEN** 返回空输出，不渲染任何字段，不中断渲染

#### Scenario: 整数 0 与百分比 0% 混合

- **WHEN** 入参为 `{maxSurge: 0, maxUnavailable: "0%"}`
- **THEN** 返回空输出，不渲染任何字段，不中断渲染

#### Scenario: 只有一侧为 0

- **WHEN** 入参为 `{maxSurge: 0}` 或 `{maxSurge: 0, maxUnavailable: "30%"}`
- **THEN** 为 0 的 `maxSurge` 照常渲染，不省略该字段

## 非目标

- 不解析 `strategy` 的字符串简写，该归一化属于 `apps.deploymentSpec`。
- 不校验整数形态的取值上限。
- 不校验两个字段同时为 0 之外的其他联动约束，例如百分比换算后的副本数关系。
- 不修改 `apps.deploymentStrategy` 的委托契约、`type` 处理与字段生效条件。
