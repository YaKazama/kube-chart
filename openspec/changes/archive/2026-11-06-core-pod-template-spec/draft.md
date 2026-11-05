---
change-id: core-pod-template-spec
updated_at: "2026-11-05T15:46:15Z"
---

# 新增 core.podTemplateSpec 命名模板

## 目标

- 新增命名模板 `core.podTemplateSpec`，为工作负载资源提供统一的 PodTemplateSpec 构造能力。

## 需求

- 模板名称为 `core.podTemplateSpec`。
- 接收的数据是父级模板透传的上下文 `.`，不使用 `dict` 重新包装。
- 模板内设置 `_kind = PodTemplateSpec`。
- 仅设置 `_kind`，不设置也不覆盖 `_pkind`；调用本模板的父模板与前置模板均未设置 `_pkind`。
- `metadata` 委托子模板 `definitions.objectMeta`，继续透传包含 `_kind` 的同一上下文 `.`。
- `spec` 委托子模板 `core.podSpec`，同样透传同一上下文 `.`。
- `metadata` 与 `spec` 子模板无有效输出时不渲染对应字段，仅有值时才渲染。
- 子模板输出为数组、标量等无法恢复为有效 map 的内容时，同样按无效输出省略，不中断渲染。
- 输出符合 Kubernetes `PodTemplateSpec` 结构（API 字段顺序为 `metadata`、`spec`）。

## 期望输入格式

- 父级模板通过 `include` 传入的上下文 map，字段由 `definitions.objectMeta` 与 `core.podSpec` 各自消费。

## 约束

- 模板位于 `templates/api-resources/Core/`，命名空间维持 `core.*`。
- `core.podSpec` 在本 change 仅作占位引用，不创建实现，也不创建占位 `define`。
- `core.podSpec` 的失败行为由它自行管理，本 change 不做任何处理；既不在 `core.podTemplateSpec` 收束校验，也不向调用父级扩散。
- 既有调用方 `templates/api-resources/Apps/_DeploymentSpec.tpl` 保持父级自身判断（`template` 必填、空输出失败），本 change 不修改该判断。
- 验收阶段假设 `core.podSpec` 行为正确；如需隔离验证，使用 `/tmp/` 测试 Chart 中的同名最小 fixture，结论不表述为真实依赖集成通过。

## 非目标

- 不在本 change 实现 `core.podSpec`。
- 不在本 change 改造 `apps.deploymentSpec` 等现有工作负载模板的调用方式；现有工作负载模板后续改用 `core.podTemplateSpec`。

## 验收

- 调用 `core.podTemplateSpec` 渲染出同时包含 `metadata` 与 `spec` 的 `PodTemplateSpec` 结构。
- `metadata` 内容来自 `definitions.objectMeta`，且该子模板收到的上下文中 `_kind` 为 `PodTemplateSpec`。
- `spec` 内容来自 `core.podSpec` 的返回值。
- 子模板无有效输出时省略对应字段，不因空值或无效输出中断渲染。
- 模板自身不因 `metadata` 或 `spec` 为空而失败；必填性判断由父级调用方负责。
- 最小有效输入可成功渲染；`core.podSpec` 以最小 fixture 提供，验收不检验其内部实现。
