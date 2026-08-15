# 需求规格：Deployment 资源模板正式化

## 背景与目标

- 背景或问题：已实现的 Deployment 调用链缺少按新 SDD 模板组织的需求、设计、任务、证据与契约快照。
- 目标：如实整理 `apps.deployment`、`apps.deploymentSpec`、`apps.deploymentStrategy` 与 `apps.rollingUpdateDeployment` 的当前行为和限制。
- 成功标准：过程文档可通过 `R-* → D-* → P-* → T-* → AC-*` 追溯，且不将静态审阅结论误写为已执行验证。

## 范围

- 包含：顶层 Deployment 身份与委托、DeploymentSpec 标量字段、selector、strategy、RollingUpdate 约束和验证门禁。
- 不包含：修改模板实现；伪造完整 PodTemplateSpec 输出；将本归档材料作为正式规范或用户指南。

## 需求

- R-01：记录资源入口固定输出 `apps/v1` 与 `Deployment`，以及 metadata/spec 的委托输出校验。
  - 优先级：必须。
  - 验收 ID：AC-01。
- R-02：记录 DeploymentSpec 的字段省略和零值行为。
  - 优先级：必须。
  - 验收 ID：AC-02。
- R-03：记录 selector、strategy 与 RollingUpdate 的真实类型分支和失败条件。
  - 优先级：必须。
  - 验收 ID：AC-03。
- R-04：记录当前实现限制与未完成验证，不将文档快照视为正式化结果。
  - 优先级：必须。
  - 验收 ID：AC-04。

## 验收标准

- AC-01：
  - 前置条件与输入要点：审阅 `apps.deployment`。
  - 期望可观察结果：确认顶层资源身份固定，metadata/spec 的委托结果必须为非空有效 map。
- AC-02：
  - 前置条件与输入要点：审阅 DeploymentSpec 标量字段。
  - 期望可观察结果：`minReadySeconds`、`progressDeadlineSeconds` 仅在大于 `0` 时输出；`paused` 仅在 `true` 时输出；`replicas`、`revisionHistoryLimit` 保留 `0`。
- AC-03：
  - 前置条件与输入要点：审阅 selector、strategy 与 rollingUpdate 分支。
  - 期望可观察结果：selector 必须为 map；Recreate 跳过 rollingUpdate；双零失败；不匹配的 strategy 简写静默省略。
- AC-04：
  - 前置条件与输入要点：审阅调用链与现有证据。
  - 期望可观察结果：明确 `deployment.template` 未被独立消费、顶层写入 `_kind`，且所有端到端验证仍为待验证。

## 假设与依赖

- 假设：静态代码审阅可用于记录实现事实，但不能替代 Helm 渲染证据。
- 外部依赖或约束：父 Chart、已接入的下层模板和 `/opt/homebrew/bin/helm`。
- 参考资料：Kubernetes Deployment API、Helm 模板函数文档及 Apps 目录中的 Deployment 调用链。
