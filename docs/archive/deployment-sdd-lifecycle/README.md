# Deployment SDD 生命周期示例

本目录以 `apps.deployment` 为对象，展示按当前列表模板填写的过程文档快照。

- 定位：历史过程示例，不具规范效力，正式 SDD 与实现不得引用本目录。
- 当前状态：文档结构已重写；`helm lint`、父 Chart 渲染和人工 Review 尚未完成，不能视为已正式化或已验证的闭环。
- 基线：Kubernetes API `>= v1.36.0`、Helm `>= 4.0.0`、library Chart、`apps/v1` `Deployment`。

## 文档链路

- `spec.md`：需求 `R-*` 与验收 `AC-*`。
- `design-plan.md`：低风险场景合并的设计决策 `D-*` 与计划 `P-*`。
- `tasks.md`：可执行任务 `T-*`。
- `evidence.md`：各验收项的实际证据与状态。
- `sdd.md`：待正式化的稳定行为契约快照。
- `guide.md`：未验证的用户说明草案。

## 调用边界

`apps.deployment` 是 library Chart 命名模板，父 Chart 负责构造局部上下文并调用：

```gotemplate
{{- $ctx := mustMergeOverwrite (mustDeepCopy .) (dict "Context" .Values.deployment) -}}
{{- include "apps.deployment" $ctx }}
```

当前 `apps.deploymentSpec` 将完整根上下文传给 `core.podTemplateSpec`；它不会独立读取或传递 `deployment.template` 子字段。该限制在本示例中作为待解决偏差记录。
