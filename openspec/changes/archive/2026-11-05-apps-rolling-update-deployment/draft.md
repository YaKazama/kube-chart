---
change-id: apps-rolling-update-deployment
updated_at: "2026-11-05T05:53:42Z"
---

# apps.rollingUpdateDeployment 模板

## 目标

- 新建模板 `apps.rollingUpdateDeployment`，渲染 Kubernetes `RollingUpdateDeployment` 结构。
- 补齐 `apps.deploymentStrategy` 已委托但当前尚未实现的子模板，使 `DeploymentStrategy.rollingUpdate` 可以真实渲染。

## 需求

- `apps.rollingUpdateDeployment` 接收父级已清洗的 `rollingUpdate` map 作为上下文，返回可嵌入 `spec.strategy.rollingUpdate` 下的 YAML 字段片段。
- 不解析字符串简写：`strategy` 简写中的 `maxSurge`、`maxUnavailable` 取值由 `apps.deploymentSpec` 归一化后传入。
- 不输出 `status` 或其他字段。
- 只实现 API 定义的 `maxSurge`、`maxUnavailable` 两个字段，字段顺序与 `maxSurge` 在前、`maxUnavailable` 在后一致。
- 两个字段均为可选；缺失或为空时不输出该字段，不补充 `25%` 等 API 默认值，与 `apps.deploymentStrategy` 现有“不引入隐式覆盖”的行为保持一致。
- 显式 `null`（含 `~` 与空值键）按空值处理，与缺失等价，不参与校验也不输出该字段。
- 两字段值均为 `IntOrString`：支持整数与百分比字符串两种形态，不合法形态中断渲染。
- 小数输入中，小数部分非零的写法（例如 `1.5`）一律视为不合法并中断渲染，不得静默截断为整数；小数部分为 0 的原生浮点（`1.0`）经 `base.get` 归一化后与整数 `1` 同形，按整数渲染。
- `maxSurge`、`maxUnavailable` 分别使用独立正则表达式进行校验；两个正则均在 `base.env` 中集中定义，业务模板不得内联。
- `maxSurge` 的百分比上限可以超过 `100%`；`maxUnavailable` 的百分比上限不能超过 `100%`。上限只约束百分比形态，整数形态不设上限。
- `base.field` 最终渲染时仍将取值传入 `base.rollingUpdate` 做二次格式校验。
- `maxSurge`、`maxUnavailable` 同时为 0（整数 `0` 或百分比 `0%`）时整体不渲染 `rollingUpdate`，复用 Kubernetes 隐式默认值，以规避 API 的 `This can not be 0 if MaxUnavailable is 0.` 与 `This can not be 0 if MaxSurge is 0.` 联动约束。
- 只有一侧为 0 时该字段正常渲染，不做省略。
- 百分比值不加引号渲染，与现有 `strategy` map 透传的渲染形态一致。
- 两个字段都为空时返回空输出，由 `apps.deploymentStrategy` 跳过 `rollingUpdate` 字段。
- 支持 `<叶子>Alias` 键名，由 `base.get` 统一识别。

## 期望输入格式

<!-- 只填写用户明确指定的本次特殊限制。 -->

## 约束

<!-- 只填写用户明确指定的本次特殊限制。 -->

## 非目标

- 不修改 `apps.deploymentStrategy` 的委托契约、`type` 处理与字段生效条件。
- 不修改 `apps.deploymentSpec` 中 `strategy` 字符串简写的解析行为。
- 不校验整数形态的上限。

## 验收

- 在 `/tmp/` 最小 application Chart 中加载真实 `apps.rollingUpdateDeployment` 并通过 `apps.deploymentStrategy` 渲染滚动更新参数，`helm template` 输出与 Kubernetes API 接受的 `rollingUpdate` 形态一致。
- `maxSurge`、`maxUnavailable` 均缺失时，`rollingUpdate` 整体不渲染且不失败。
- `maxSurge`、`maxUnavailable` 同时为 0 时，`rollingUpdate` 整体不渲染且不失败；只有一侧为 0 时该字段照常渲染。
- `maxUnavailable: 101%` 中断渲染，`maxSurge: 150%` 正常渲染。
- 小数部分非零的输入中断渲染，`1.0` 按整数 `1` 渲染。
- `maxSurge: null`、空值键与 `~` 均按空值跳过，不中断渲染。
- 非法取值经独立正则与 `base.rollingUpdate` 双重校验中断渲染。

## 开放问题

<!-- 本轮无开放问题。 -->
