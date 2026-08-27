# kube-chart AI 开发入口

## 项目基线

- Kubernetes API `>= v1.36.0`；Helm `>= 4.0.0`，推荐 `4.2.2`。
- Chart：library Chart，[`Chart.yaml`](Chart.yaml) 必须声明 `kubeVersion: ">=1.36.0"`。
- 仅使用 Helm 内置函数、Go Template、Sprig 与 Helm 特有函数；严禁臆造。

## 工作原则

- 以资深 DevOps、云原生架构和 Helm 模板工程标准实施变更，保持标准化、低幻觉、类型稳定和代码 DRY，并遵循 Helm 与 Kubernetes 最佳实践。
- 使用中文；数字、英文与中文混排保留必要空格；文件引用使用工作区相对路径。
- 变更文档的入口、归属和推断保护统一遵循 [`openspec/rules/change-documents.md`](openspec/rules/change-documents.md)，不得在其他层复述为第二套规则。
- 文件末尾有且仅有一个换行符。

## 上下文访问

- 文件路径必须来自已读文档的明确链接、本文映射或已授权目录的文件清单。AI 会话命令名与文件名属于不同命名空间；不得通过增删或替换命令前后缀猜测文件名。缺少映射时，先查询真实文件列表，再读取已确认的路径。
- 命令文件中的“固定读取”是必须读取的最小集合，“条件读取”是存在明确未决事实时允许追加的上限，不是逐项读取清单。追加前必须先说明待确认的单一事实、已有上下文为何不足以及拟读取的确切文件或片段；无法说明时不得读取。
- 契约事实只从当前规格、适用规则与用户输入确认；已知且跨版本稳定的基础事实可以用于解释，不得扩张契约。只有仍缺少影响契约的版本特定事实时才进入参考资料层。正式代码属于实现事实，只在命令允许且需要确认现状时读取，不能反向生成需求、设计选择或待确认问题。
- 搜索只用于已授权目录的真实文件清单，或在确切文件范围内定位已知标识符；搜索结果只授权读取当前命令明确允许的路径。不得先全仓搜索、读取调用方或相邻能力，再为既有结论寻找理由。
- 本地上下文仍缺少影响契约的版本特定事实或存在规范冲突时，才最小范围读取精确的本地参考片段；仍不足时才查询精确的官方资源。不得下载无关完整页面、重复查询同一事实或把参考资料扩张为新的需求来源。

## 命令入口

```text
/sdd-draft
  → /sdd-plan
  → /sdd-approve
  → /sdd-apply（可重复执行）
  → /sdd-verify（可独立、可重复执行）
  → 人工 Review
  → /sdd-merge
```

| 命令 | 唯一定义文件 | 唯一主要职责 |
|---|---|---|
| `/sdd-draft` | [`openspec/commands/draft.md`](openspec/commands/draft.md) | 新建或继续只表达意图的轻量 `draft.md`。 |
| `/sdd-plan` | [`openspec/commands/plan.md`](openspec/commands/plan.md) | 从 draft 生成或刷新包含技术目标的 `plan/` 草稿。 |
| `/sdd-approve` | [`openspec/commands/approve.md`](openspec/commands/approve.md) | 单步审查并冻结变更契约；门禁失败时保持 `planned`。 |
| `/sdd-apply` | [`openspec/commands/apply.md`](openspec/commands/apply.md) | 可重复按冻结契约生成代码、更新任务并输出变更摘要。 |
| `/sdd-verify` | [`openspec/commands/verify.md`](openspec/commands/verify.md) | 独立执行真实验证、生成验证记录并更新验证状态。 |
| `/sdd-revise` | [`openspec/commands/revise.md`](openspec/commands/revise.md) | 重置未合并 change，并移除既有 plan 与阶段记录。 |
| `/sdd-merge` | [`openspec/commands/merge.md`](openspec/commands/merge.md) | 检查验证证据、合并规格、同步用户文档并归档。 |
| `/ck-deploy` | [`openspec/commands/ck-deploy.md`](openspec/commands/ck-deploy.md) | 对整个 Chart 执行发布检查。 |

收到任一命令时，先读取精简状态机 [`openspec/workflow.md`](openspec/workflow.md)，再只读取 [`openspec/commands/`](openspec/commands/) 中对应命令文件的“固定读取”，并按其中的“条件读取”逐项证明后追加。命令是 AI 会话触发命令，不是 shell 命令。

## 规则路由

仅按当前阶段和修改范围读取：

- 用户入口保护、frontmatter 与变更记录：[`openspec/rules/change-documents.md`](openspec/rules/change-documents.md)
- 规格语法、合并或整理：[`openspec/rules/specifications.md`](openspec/rules/specifications.md)
- Helm 模板：[`openspec/rules/helm-templates.md`](openspec/rules/helm-templates.md)
- 核心命名模板调用：[`openspec/rules/core-capabilities.md`](openspec/rules/core-capabilities.md)
- values、Schema 或用户配置：[`openspec/rules/values-schema.md`](openspec/rules/values-schema.md)
- README、`docs/` 或样例：[`openspec/rules/documentation.md`](openspec/rules/documentation.md)
