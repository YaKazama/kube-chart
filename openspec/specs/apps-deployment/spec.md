# Apps Deployment 规格

## Purpose

提供一个只渲染单个 Kubernetes `apps/v1` Deployment 的 library Chart 命名模板，并将对象元数据与 Deployment 规格委托给对应子模板。

## Requirements

### Requirement: Deployment 资源输出

`apps.deployment` MUST 在 `templates/api-resources/Apps/_Deployment.tpl` 中定义，并按 Kubernetes API 字段顺序输出单个 `apps/v1` Deployment 的 `apiVersion`、`kind`、`metadata` 与 `spec`。模板 MUST NOT 输出 `status`、YAML 文档分隔符或其他独立资源。

#### Scenario: 渲染单个 Deployment

- **WHEN** 调用方以可写 map 作为 `.` 调用 `apps.deployment`，且 `metadata` 与 `spec` 子模板均返回可解析为 map 的 YAML
- **THEN** 渲染结果按顺序包含值为 `apps/v1` 的 `apiVersion`、值为 `Deployment` 的 `kind`、`metadata` 与 `spec`
- **AND** 渲染结果只包含这一个 Deployment，不包含 `status` 或 `---`

### Requirement: Deployment 上下文标识

`apps.deployment` MUST 在调用任何字段子模板前，将当前 map 上下文 `.` 的 `_kind` 直接设置为字符串 `Deployment`；已有 `_kind` MUST 被覆盖，以保证两个字段子模板观察到相同的 Deployment 标识。

#### Scenario: 子模板接收同一上下文

- **WHEN** 调用 `apps.deployment` 时传入的 map 不包含 `_kind`，或包含其他 `_kind` 值
- **THEN** `metadata` 与 `spec` 子模板均接收父模板当前的同一个上下文 `.`
- **AND** 两次调用观察到的 `._kind` 均为 `Deployment`

### Requirement: metadata 与 spec 委托

`apps.deployment` MUST 将父模板当前上下文 `.` 直接传给 `definitions.objectMeta` 与 `apps.deploymentSpec`，不得对该上下文执行 `mustDeepCopy`。子模板经 `include` 返回的字符串 MUST 恢复为 map 并通过类型检查后，才分别作为 `metadata` 与 `spec` 输出；空 map MUST 按 `base.map` 的既有契约渲染为 `{}`。

#### Scenario: metadata 子模板返回有效 map

- **WHEN** `metadata` 子模板返回非空且可解析为 map 的 YAML
- **THEN** 该 map 通过 `base.field` 与 `base.map` 渲染为 Deployment 的 `metadata`

#### Scenario: spec 子模板返回有效 map

- **WHEN** `spec` 子模板返回非空且可解析为 map 的 YAML
- **THEN** 该 map 通过 `base.field` 与 `base.map` 渲染为 Deployment 的 `spec`

#### Scenario: 子模板返回空 map

- **WHEN** `metadata` 或 `spec` 子模板返回可解析为空 map 的 YAML
- **THEN** 对应字段渲染为 `{}`

### Requirement: 子模板失败边界

`metadata` 与 `spec` 均必须输出。对应子模板成功返回空字符串、无效 YAML、解析错误结果或非 map 时，`apps.deployment` MUST 立即失败，不得省略字段或继续渲染后续字段。由 `apps.deployment` 自身发起的失败消息 MUST 使用 `[apps.deployment] 字段路径: 错误原因` 格式；子模板在执行期间直接失败时，Helm MUST 传播该依赖错误。

#### Scenario: 必填子模板输出为空

- **WHEN** `metadata` 或 `spec` 子模板返回空字符串
- **THEN** 渲染立即失败
- **AND** 错误指出对应字段缺失或为空

#### Scenario: 子模板输出无法解析

- **WHEN** `metadata` 或 `spec` 子模板返回无效 YAML 或产生 `fromYaml` 错误结果
- **THEN** 渲染立即失败
- **AND** 错误指出对应字段的子模板输出不是有效 YAML

#### Scenario: 子模板输出类型非法

- **WHEN** `metadata` 或 `spec` 子模板的输出可解析但不是 map
- **THEN** 渲染立即失败
- **AND** 错误指出对应字段必须为 map 类型
