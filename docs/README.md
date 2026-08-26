# 用户文档

本目录只保存稳定、已实现且已验证的最终用户文档。

- 开发入口：[`AGENTS.md`](../AGENTS.md)
- 规格与变更：[`openspec/README.md`](../openspec/README.md)
- 开发工作流：[`openspec/workflow.md`](../openspec/workflow.md)

用户文档只能依据 [`openspec/specs/`](../openspec/specs/) 中的当前规格和已验证样例编写，不得把活动 change、临时实验或静态代码推断描述为已支持行为。

## 当前能力

- `apps.deployment`：用户入口见 [`README.md`](../README.md)，行为契约见 [`openspec/specs/apps-deployment/spec.md`](../openspec/specs/apps-deployment/spec.md)。该父模板已通过隔离验证，但直接依赖 `definitions.objectMeta` 与 `apps.deploymentSpec` 尚未实现，不宣称真实子模板集成可用。
