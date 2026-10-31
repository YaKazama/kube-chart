---
confirmed: true
updated_at: "2026-08-31T06:37:12Z"
---

# Apps Deployment 规格

## Purpose

提供一个只渲染单个 Kubernetes `apps/v1` Deployment 的 library Chart 命名模板，并将对象元数据与 Deployment 规格委托给对应子模板。

## ADDED Requirements

### Requirement: Deployment 资源输出

`apps.deployment` MUST 按 Kubernetes API 字段顺序输出单个 `apps/v1` Deployment 的 `apiVersion`、`kind`、`metadata` 与 `spec`。模板 MUST NOT 输出 `status`、YAML 文档分隔符或其他独立资源。

#### Scenario: 渲染单个 Deployment

- **WHEN** 调用方以可写 map 作为 `.` 调用 `apps.deployment`，且 metadata 与 spec 子模板返回可恢复为 map 的 YAML
- **THEN** 渲染结果按顺序包含值为 `apps/v1` 的 `apiVersion`、值为 `Deployment` 的 `kind`、`metadata` 与 `spec`
- **AND** 渲染结果只包含这一个 Deployment，不包含 `status` 或 `---`

### Requirement: Deployment 上下文标识

`apps.deployment` MUST 在调用任何字段子模板前，将当前 map 上下文 `.` 的 `_kind` 直接设置为字符串 `Deployment`；已有 `_kind` MUST 被覆盖，以保证两个字段子模板观察到相同的 Deployment 标识。

#### Scenario: 子模板接收同一上下文

- **WHEN** 调用 `apps.deployment` 时传入的 map 不包含 `_kind`，或包含其他 `_kind` 值
- **THEN** metadata 与 spec 子模板均接收父模板当前的同一个上下文 `.`
- **AND** 两次调用观察到的 `._kind` 均为 `Deployment`

### Requirement: metadata 与 spec 委托

`apps.deployment` MUST 将父模板当前上下文的同一个 map 实例直接传给 metadata 与 spec 子模板。子模板返回值恢复为 map 后，MUST 分别输出为 `metadata` 与 `spec`。

#### Scenario: 子模板返回有效 map

- **WHEN** metadata 与 spec 子模板返回可恢复为非空 map 的 YAML
- **THEN** 对应 map 分别渲染为 Deployment 的 `metadata` 与 `spec`

#### Scenario: 子模板返回空输出、null 或空 map

- **WHEN** metadata 或 spec 子模板返回空字符串、`null` 或空 map YAML
- **THEN** 渲染立即失败
- **AND** 错误指出对应必填字段的子模板返回值为空

### Requirement: 子模板失败边界

metadata 与 spec 均必须输出非空 map。对应子模板返回值经解析错误检查后为空，或无法恢复为 map 时，渲染 MUST 立即失败，不得省略字段或继续渲染后续字段；子模板在执行期间直接失败时，Helm MUST 传播该依赖错误。

#### Scenario: 子模板输出无法恢复为 map

- **WHEN** metadata 或 spec 子模板返回无效 YAML、非 mapping YAML 或产生 YAML 解析错误结果
- **THEN** 渲染立即失败
- **AND** 错误指出对应字段的子模板没有返回有效 YAML map

## 非目标

- 不在当前 change 中修改 metadata 与 spec 子模板的字段行为。
