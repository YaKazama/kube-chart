---
change-id: apps-deployment-strategy
updated_at: "2026-11-04T15:52:35Z"
---

# Deployment 部署策略

## 目标

- 创建 `apps.deploymentStrategy` 模板，让调用方按需选择 `Recreate` 或 `RollingUpdate`，并透传 `rollingUpdate` 的配置。

## 需求

- 入参是父级模板已清洗后的 `strategy`，本模板不再解析字符串简写，也不编写 `*Alias` 处理逻辑，不重复做类型与合法性防御。
- `base.get` 使用默认参数调用，不显式传入 `required` 与 `alias`；不为了关闭别名识别而填充位置占位参数。
- 入参为空时（含空 map）不渲染、不报错，返回空输出；父级收集到空结果时不渲染 `strategy`。
- `type` 在实际渲染时二次校验取值，合法枚举为 `Recreate`、`RollingUpdate`，大小写敏感；不在枚举内则失败。
- `type` 不带入隐式默认值：`type` 为空时不渲染该字段，省略时由 Kubernetes API 采用 `RollingUpdate`。
- `rollingUpdate` 根据 `type` 的生效值决定是否渲染：`type` 为空时按隐式默认值 `RollingUpdate` 判定，因此 `type` 为空且 `rollingUpdate` 非空时渲染 `rollingUpdate`，但仍不渲染 `type`。
- `type = Recreate` 时即使入参带有 `rollingUpdate` 也静默忽略，只输出 `type`。
- `rollingUpdate` 委托子模板 `apps.rollingUpdateDeployment` 渲染；该子模板本 change 只占位、不创建。子模板返回空时不渲染 `rollingUpdate`，不失败，由 API 隐式默认值生效。
- 不引入任何隐式覆盖：不输出 `type` 默认值，也不输出 `rollingUpdate` 的 `maxSurge`、`maxUnavailable` 默认值。
- `base.get` 取不到 `type` 与 `rollingUpdate` 时返回空输出，不失败；空结果符合 Kubernetes API 对该可选字段的定义。

## 期望输入格式

- 入参为 map，可包含 `type`（string）与 `rollingUpdate`（map）；`rollingUpdate` 的内部结构不在本模板解析。
- 父级清洗后不提供 `typeAlias`、`rollingUpdateAlias` 等别名键；本模板不依赖也不承诺别名键的处理结果。
- 入参已由父级清洗，内容合法；父级传入空 map 时本模板返回空输出。
- 不可信或非预期形态不在本模板的处理范围，由父级负责。

## 约束

- 新建模板 `apps.deploymentStrategy`，子模板 `apps.rollingUpdateDeployment` 本 change 不创建。
- 仅使用 Helm 内置函数、Go Template、Sprig 与 Helm 特有函数，遵循现有 `templates/api-resources/Apps/` 模板组织方式。

## 非目标

- 不涉及 Deployment 的状态管理、扩缩容控制器（HPA）或滚动发布期间的探针行为变更。
- Schema 校验和示例文档暂不处理，待开发完成后再另行处理。

## 验收

- 选择 `Recreate` 与 `RollingUpdate`（含自定义 `maxSurge` / `maxUnavailable`）时，`helm template` 渲染结果与 Kubernetes API 接受的形态一致。
- `Recreate` 入参附带 `rollingUpdate` 时，渲染结果只含 `type: Recreate`。
- 空入参返回空输出，非枚举 `type` 中断渲染。
- `type` 为空时不出现 `type` 字段，也不出现任何隐式默认值。
- `type` 为空且 `rollingUpdate` 非空时，输出只含 `rollingUpdate`，不含 `type`。
- 子模板返回空时输出中不含 `rollingUpdate`，且不失败。

## 开放问题

- 无。
