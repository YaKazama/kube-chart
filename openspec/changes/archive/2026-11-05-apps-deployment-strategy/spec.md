---
updated_at: "2026-11-04T15:58:01Z"
---

# Deployment 部署策略规格

## Purpose

提供 `apps.deploymentStrategy` 模板，把父级模板已清洗的策略 map 渲染为 apps/v1 DeploymentStrategy 字段片段。

## ADDED Requirements

### Requirement: 空入参不渲染

系统 MUST 在 `type` 为空且 `rollingUpdate` 为空内容时返回空输出，不渲染任何字段，且 MUST NOT 中断渲染。`type` 为空指缺失、`null` 或空字符串；`rollingUpdate` 为空内容指缺失或空 map。

系统 MUST NOT 在入参中解析字符串简写，也 MUST NOT 为本能力增加 `*Alias` 键的专有处理逻辑。除 `type` 与 `rollingUpdate` 之外，本能力 MUST NOT 渲染任何其他入参键。

#### Scenario: 空 map 入参

- **WHEN** 入参为空 map
- **THEN** 返回空输出，不渲染 `type` 或 `rollingUpdate`，不失败

#### Scenario: 未提供入参

- **WHEN** 调用方未提供任何策略字段
- **THEN** 返回空输出，不失败

#### Scenario: type 为 null 且无 rollingUpdate

- **WHEN** 入参为 `{type: null}`
- **THEN** 返回空输出，不渲染 `type`，不失败

#### Scenario: type 为空字符串且无 rollingUpdate

- **WHEN** 入参为 `{type: ""}`
- **THEN** 返回空输出，不渲染 `type`，不失败

#### Scenario: rollingUpdate 为空 map 且无 type

- **WHEN** 入参为 `{rollingUpdate: {}}`
- **THEN** 返回空输出，不渲染 `rollingUpdate`，不失败

#### Scenario: 未定义字段不渲染

- **WHEN** 入参为 `{type: "Recreate", unknown: "x"}`
- **THEN** 只渲染 `type: Recreate`，不输出 `unknown`，不失败

### Requirement: type 不带隐式默认值

系统 MUST NOT 在 `type` 为空时渲染 `type` 字段，也 MUST NOT 用任何取值替代输出；省略 `type` 时由 Kubernetes API 采用 `RollingUpdate`。

`type` 非空时系统 MUST 原样渲染。系统 MUST 只接受 `Recreate` 与 `RollingUpdate` 两个取值，大小写敏感；其他取值 MUST 失败并中断渲染，失败消息 MUST 给出该合法范围。本校验 MUST 独立于父级的归一化结果再次执行。

#### Scenario: type 缺失且存在 rollingUpdate

- **WHEN** 入参为 `{rollingUpdate: {maxSurge: 1}}`
- **THEN** 不渲染 `type`，不输出任何替代值

#### Scenario: type 为 null 且存在 rollingUpdate

- **WHEN** 入参为 `{type: null, rollingUpdate: {maxSurge: 1}}`
- **THEN** 不渲染 `type`，不输出任何替代值

#### Scenario: type 为空字符串且存在 rollingUpdate

- **WHEN** 入参为 `{type: "", rollingUpdate: {maxSurge: 1}}`
- **THEN** 不渲染 `type`，不输出任何替代值

#### Scenario: 合法取值原样渲染

- **WHEN** `type` 为 `Recreate` 或 `RollingUpdate`
- **THEN** 分别渲染 `type: Recreate`、`type: RollingUpdate`

#### Scenario: 大小写不匹配失败

- **WHEN** `type` 为 `rollingupdate` 或 `recreate`
- **THEN** 失败并中断渲染，失败消息包含 `Recreate`、`RollingUpdate`

#### Scenario: 未知取值失败

- **WHEN** `type` 为 `BlueGreen` 或其他非枚举值
- **THEN** 失败并中断渲染，失败消息包含 `Recreate`、`RollingUpdate`

### Requirement: rollingUpdate 渲染条件

`type` 为 `Recreate` 时，系统 MUST NOT 读取或渲染 `rollingUpdate`；入参中存在的 `rollingUpdate` MUST 静默忽略且 MUST NOT 视为非法。

`type` 不为 `Recreate` 时，系统 MUST 只在入参 `rollingUpdate` 非空时渲染该字段；`type` 为空时 MUST 按隐式默认值 `RollingUpdate` 采用同一条件，因此 `type` 为空且 `rollingUpdate` 非空时 MUST 渲染 `rollingUpdate`，同时 MUST NOT 渲染 `type`。`rollingUpdate` 缺失或为空 map 时 MUST NOT 渲染该字段，也 MUST NOT 补充 `maxSurge`、`maxUnavailable` 或任何其他内部默认值。

#### Scenario: type 为空且 rollingUpdate 非空

- **WHEN** 入参为 `{rollingUpdate: {maxSurge: 1}}`
- **THEN** 只渲染 `rollingUpdate`，不渲染 `type`

#### Scenario: Recreate 忽略 rollingUpdate

- **WHEN** 入参为 `{type: "Recreate", rollingUpdate: {maxSurge: 1}}`
- **THEN** 只渲染 `type: Recreate`，不渲染 `rollingUpdate`，不失败

#### Scenario: Recreate 忽略非 map rollingUpdate

- **WHEN** 入参为 `{type: "Recreate", rollingUpdate: "invalid"}`
- **THEN** 只渲染 `type: Recreate`，不渲染 `rollingUpdate`，不失败

#### Scenario: RollingUpdate 渲染 rollingUpdate

- **WHEN** 入参为 `{type: "RollingUpdate", rollingUpdate: {maxSurge: 1}}`
- **THEN** 渲染 `type: RollingUpdate` 与 `rollingUpdate`

#### Scenario: rollingUpdate 缺失

- **WHEN** 入参为 `{type: "RollingUpdate"}`
- **THEN** 只渲染 `type: RollingUpdate`，不渲染 `rollingUpdate`，不补充默认值

#### Scenario: rollingUpdate 为空 map

- **WHEN** 入参为 `{type: "RollingUpdate", rollingUpdate: {}}`
- **THEN** 只渲染 `type: RollingUpdate`，不渲染 `rollingUpdate`

### Requirement: rollingUpdate 委托渲染

系统 MUST 把入参 `rollingUpdate` 原样交给 `apps.rollingUpdateDeployment` 渲染，并 MUST 把其返回的 map 渲染在 `rollingUpdate` 字段下；该子模板 MUST NOT 在本能力中实现，其内部字段不在本能力校验范围。

子模板返回空输出时系统 MUST NOT 渲染 `rollingUpdate`，且 MUST NOT 中断渲染。子模板返回无效 YAML 或非 map 时系统 MUST 失败并中断渲染。

#### Scenario: 委托子模板渲染

- **WHEN** 入参为 `{type: "RollingUpdate", rollingUpdate: {maxSurge: 1, maxUnavailable: "30%"}}`
- **THEN** `rollingUpdate` 下的内容完全由 `apps.rollingUpdateDeployment` 决定，本能力不校验其内部字段

#### Scenario: 子模板返回空输出

- **WHEN** `apps.rollingUpdateDeployment` 返回空输出
- **THEN** 不渲染 `rollingUpdate`，不失败；`type` 非空时仍渲染 `type`

#### Scenario: 子模板返回无效 YAML

- **WHEN** `apps.rollingUpdateDeployment` 返回无效 YAML
- **THEN** 失败并中断渲染

#### Scenario: 子模板返回非 map

- **WHEN** `apps.rollingUpdateDeployment` 返回 YAML 标量或数组
- **THEN** 失败并中断渲染

## 非目标

- 不实现 `apps.rollingUpdateDeployment`；该子模板本 change 只占位。
- 不解析 `type` 的字符串简写形态，不做大小写归一。
- 不为 `*Alias` 键定义专有行为：别名键是否参与取值沿用既有取值能力的默认语义，不在本能力契约范围。
- 不校验入参形态：调用方未按契约传入 map 或清洗后数据时不在本能力处理范围。
- 不校验 `maxSurge`、`maxUnavailable` 的形态、上限或二者联动约束。
- 不涉及 Deployment 的状态管理、扩缩容控制器（HPA）或滚动发布期间的探针行为变更。
- Schema 校验和示例文档暂不处理，待开发完成后再另行处理。
