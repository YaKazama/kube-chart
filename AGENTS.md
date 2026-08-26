# kube-chart AI 开发入口

## 项目基线

- Kubernetes API：`>= v1.36.0`。
- Helm：`>= 4.0.0`，推荐 `4.2.2`。
- Chart：library Chart，[`Chart.yaml`](Chart.yaml) 必须声明 `kubeVersion: ">=1.36.0"`。
- 仅使用 Helm 内置函数、Go Template、Sprig 与 Helm 特有函数；严禁臆造。

## 工作原则

- 以资深 DevOps 工程师、云原生架构师和 Helm 模板工程师的标准实施变更。
- 目标是标准化、低幻觉、类型稳定、代码 DRY，并符合 Helm 与 Kubernetes 最佳实践。
- 使用中文；数字、英文与中文混排保留必要空格；文件引用使用工作区相对路径。
- 变更文档的入口、归属和推断保护统一遵循 [`openspec/rules/change-documents.md`](openspec/rules/change-documents.md)，不得在其他层复述为第二套规则。
- 文件末尾有且仅有一个换行符。

## 命令入口

```text
/sdd-draft → /sdd-plan → /sdd-approve → /sdd-apply
                                            ↓
                                      /sdd-verify
                                            ↓
                                       人工 Review
                                            ↓
                                       /sdd-merge
```

| 命令 | 唯一主要职责 |
|---|---|
| `/sdd-draft` | 新建或继续只表达意图的轻量 `draft.md`。 |
| `/sdd-plan` | 从 draft 生成或刷新包含技术目标的 `plan/` 草稿。 |
| `/sdd-approve` | 审查并在用户确认后冻结变更契约。 |
| `/sdd-apply` | 按冻结契约修改正式代码，并通过真实项目命令获得开发反馈。 |
| `/sdd-verify` | 执行真实项目命令并将结果写入人类可读的验证记录。 |
| `/sdd-revise` | 使批准失效，直接返回 `draft` 阶段受控修订。 |
| `/sdd-merge` | 合并规格、同步用户文档并归档。 |
| `/ck-deploy` | 对整个 Chart 执行发布检查。 |

收到任一命令时，先读取精简状态机 [`openspec/workflow.md`](openspec/workflow.md)，再只读取 [`openspec/commands/`](openspec/commands/) 中对应命令文件列出的上下文。命令是 AI 会话触发命令，不是 shell 命令。

## 规则路由

仅按当前阶段和修改范围读取：

- 用户入口保护、frontmatter 与变更记录：[`openspec/rules/change-documents.md`](openspec/rules/change-documents.md)
- 规格语法、合并或整理：[`openspec/rules/specifications.md`](openspec/rules/specifications.md)
- Helm 模板：[`openspec/rules/helm-templates.md`](openspec/rules/helm-templates.md)
- 核心命名模板调用：[`openspec/rules/core-capabilities.md`](openspec/rules/core-capabilities.md)
- values、Schema 或用户配置：[`openspec/rules/values-schema.md`](openspec/rules/values-schema.md)
- README、`docs/` 或样例：[`openspec/rules/documentation.md`](openspec/rules/documentation.md)
