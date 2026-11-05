---
updated_at: "2026-11-05T15:45:35Z"
---

# core.podTemplateSpec 规格

## Purpose

为工作负载资源提供统一的 `PodTemplateSpec` 字段片段构造能力，使 Deployment、StatefulSet、DaemonSet 等资源复用同一条 Pod 模板渲染路径。

## ADDED Requirements

### Requirement: PodTemplateSpec 结构渲染

系统 MUST 以父级模板通过 `include` 透传的 map 上下文 `.` 作为唯一调用上下文，MUST NOT 要求 `dict` 等额外包装。

系统 MUST 将资源身份设置为 `PodTemplateSpec`，并把同一上下文透传给 `metadata` 与 `spec` 两个委托子模板。

系统 MUST 只输出 `metadata` 与 `spec` 两个字段，字段顺序 MUST 为 `metadata` 在前、`spec` 在后；MUST NOT 输出文档分隔符、`_kind`、`_pkind` 或本规格未列出的其他字段。

`metadata` MUST 来自既有 `ObjectMeta` 共享结构的委托渲染结果。

`spec` MUST 来自 `core.podSpec` 的委托渲染结果。

系统 MUST 只设置在自身所有权范围内的 `_kind`；对 `_pkind` MUST NOT 设置或覆盖，其取值 MUST 原样透传给子模板并 MUST NOT 进入输出。

#### Scenario: 正常渲染

- **WHEN** 上下文包含 `metadata` 与 `spec` 所需的全部有效数据
- **THEN** 输出包含 `metadata` 与 `spec` 两个字段，且 `metadata` 在前、`spec` 在后

#### Scenario: 资源身份传递

- **WHEN** 父级上下文未包含 `_kind`
- **THEN** `metadata` 子模板收到的上下文中 `_kind` 为 `PodTemplateSpec`

#### Scenario: 父级已含 `_pkind`

- **WHEN** 父级上下文包含非空 `_pkind`
- **THEN** `_pkind` 取值保持原样并透传给子模板，既不被设置也不被覆盖

#### Scenario: 控制字段不进入输出

- **WHEN** 渲染结果包含 `metadata` 与 `spec`
- **THEN** 输出不包含 `_kind` 与 `_pkind` 键

### Requirement: 子模板无有效输出时省略字段

系统 MUST 在 `metadata` 或 `spec` 的委托输出为空、无有效 YAML 或无法恢复为有效值时省略该字段，MUST NOT 因此中断渲染。

系统 MUST NOT 在模板自身承担 `metadata` 或 `spec` 的必填性判断；必填性 MUST 由父级调用方自行负责。

系统 MUST 把委托输出中无法恢复为有效 map 的内容按无效输出处理并省略该字段；此类内容 MUST NOT 导致渲染中断。

`core.podSpec` 自身触发的渲染失败及必填校验 MUST 由该子模板自行承担；本模板 MUST NOT 捕获、包装或将此类失败降级为字段省略。

#### Scenario: 单个字段为空

- **WHEN** 只有 `metadata` 子模板输出非空，`spec` 子模板输出为空
- **THEN** 只渲染 `metadata`，省略 `spec`，不中断渲染

#### Scenario: 非法 YAML 输出

- **WHEN** `metadata` 子模板输出无法解析为 YAML
- **THEN** 省略 `metadata`，不中断渲染

#### Scenario: 两个字段均无有效输出

- **WHEN** `metadata` 与 `spec` 子模板均输出空
- **THEN** 返回空输出，不中断渲染

#### Scenario: 输出无法恢复为 map

- **WHEN** `spec` 子模板输出的是数组、标量等非 map 内容
- **THEN** 省略 `spec` 且不中断渲染

#### Scenario: 子模板自身失败

- **WHEN** `core.podSpec` 在自身内部判定必填缺失或其他非法输入而失败
- **THEN** 渲染中断，该失败原样向上传播，不降级为省略 `spec`

## 非目标

- 不在本 change 实现 `core.podSpec`。
- 不在本 change 修改既有调用方的必填判断，也不改造现有工作负载模板的调用方式。
- 不渲染 `PodTemplateSpec` 之外的字段，不输出 `status`。
