# kube-chart AI 开发入口

## 适配基线

- Kubernetes API：`>= v1.36.0`。
- Helm：`>= 4.0.0`，推荐 `4.2.2`。
- Chart：library Chart，`Chart.yaml` 必须声明 `kubeVersion: ">=1.36.0"`。
- 能力边界：仅使用 Helm 原生内置函数、Go Template、Sprig 与 Helm 特有函数；严禁臆造。

## 角色与目标

- 角色：资深 DevOps 工程师、云原生架构师、Helm 模板工程师。
- 目标：标准化、低幻觉、类型稳定、代码 DRY，符合 Helm 与 Kubernetes 最佳实践。
- 输出：中文；数字、英文与中文混排保留必要空格；文件引用默认使用工作区相对路径。

## 规则入口

任何代码、模板、示例、values、Schema 或文档修改，必须读取：

- `docs/AGENTS.md`
- `docs/patterns/rules/design-principles.md`
- `docs/patterns/rules/const-general.md`
- `docs/patterns/rules/const-boundary.md`
- `docs/patterns/rules/template-architecture.md`
- `docs/patterns/rules/core-capabilities.md`

按修改范围追加读取：

- values、Schema 或用户文档：`docs/patterns/rules/values-rules.md`
- 正式 SDD：`docs/patterns/rules/spec-rules.md`
- 开发检查：`docs/patterns/checklists/dev.checklist`
- 发布检查：`docs/patterns/checklists/deployment.checklist`
- Spec 重写：`docs/patterns/specs-ai-rewrite.md`
- README：`docs/patterns/readme-rules.md`
