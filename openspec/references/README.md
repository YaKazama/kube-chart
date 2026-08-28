# 参考资料

- [`openspec/references/helm.md`](helm.md)：Helm library Chart、模板能力与真实验证命令的必要官方入口。
- [`openspec/references/kubernetes.md`](kubernetes.md)：Kubernetes API、对象约定与安全边界的必要官方入口。
- [`openspec/references/kubernetes-api-v1.36.html`](kubernetes-api-v1.36.html)：Kubernetes API v1.36 版本特定字段、类型与语义的本地镜像。
- [`openspec/references/template-snippets.md`](template-snippets.md)：与当前工程规则和正式基础模板一致的 Helm 实现片段；仅在模板变更涉及相应处理模式时读取。

参考资料用于确认事实和提供实现模式，不独立创建用户需求或工程规则；当前行为由 [specs](../specs/) 定义，工程规则只在 [`openspec/rules/`](../rules/) 定义，实现能力以正式代码为准。参考资料与当前规格、工程规则或正式能力冲突时停止推导并报告冲突，不得自行选择。
