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
- 用户只维护活动变更的 `draft.md` 正文并表达变更意图；AI 维护其 frontmatter、`plan/` 和 `records/`。
- `/sdd-draft` 不强制用户提供主要能力、define 名称或目标路径；`/sdd-plan` 必须先解析并校验这些技术目标，无法唯一确定时保持 `draft` 并报告待确认项。
- 用户明确内容优先于 AI 推断；AI 草拟内容必须标记 `[AI 推断]`，未经用户确认不得进入 spec 的 MUST 条目。
- 每次会话结束前，本次变更意图的新增、修改或删除必须写回 `draft.md`；尚未确认、存在歧义或冻结状态不允许写回时，必须给出包含目标章节和建议文本的明确修订建议。
- 不得把项目背景、代码事实、历史决策或无关上下文补写为本次需求或约束。
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
| `/sdd-plan` | 先检查技术目标，再从 draft 生成或刷新 `plan/` 草稿。 |
| `/sdd-approve` | 审查并在用户确认后冻结变更契约。 |
| `/sdd-apply` | 按冻结契约修改正式代码，并通过真实项目命令获得开发反馈。 |
| `/sdd-verify` | 执行真实项目命令并将结果写入人类可读的验证记录。 |
| `/sdd-revise` | 使批准失效，直接返回 `draft` 阶段受控修订。 |
| `/sdd-merge` | 合并规格、同步用户文档并归档。 |
| `/sdd-rewrite` | 无语义变更地整理当前规格。 |
| `/ck-deploy` | 对整个 Chart 执行发布检查。 |

收到任一命令时，先读取精简状态机 [`openspec/workflow.md`](openspec/workflow.md)，再只读取 [`openspec/commands/`](openspec/commands/) 中对应命令文件列出的上下文。命令是 AI 会话触发命令，不是 shell 命令。

## 规则路由

仅按当前阶段和修改范围读取：

- 用户入口保护、frontmatter 与来源标记：[`openspec/rules/change-documents.md`](openspec/rules/change-documents.md)
- 规格语法、合并或改写：[`openspec/rules/specifications.md`](openspec/rules/specifications.md)
- Helm 模板：[`openspec/rules/helm-templates.md`](openspec/rules/helm-templates.md)
- 核心命名模板调用：[`openspec/rules/core-capabilities.md`](openspec/rules/core-capabilities.md)
- values、Schema 或用户配置：[`openspec/rules/values-schema.md`](openspec/rules/values-schema.md)
- README、`docs/` 或样例：[`openspec/rules/documentation.md`](openspec/rules/documentation.md)

验证只认可仓库真实存在的 `make`、Helm、npm 等项目命令及其实际退出码和输出，不得臆造校验器或用 Markdown checklist 代替执行结果。当前 Helm CLI 固定使用 `/opt/homebrew/bin/helm`；模板变更至少实际执行 Helm lint、最小有效输入、较完整有效输入和关键失败输入验证。验证证据只写入人类可读的 `records/verification.md`，临时文件只创建于 `/tmp/` 并在完成后清理。
