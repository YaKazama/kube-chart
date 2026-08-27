# kube-chart AI 开发入口

## 项目基线

- Kubernetes API `>= v1.36.0`；Helm `>= 4.0.0`，推荐 `4.2.2`。
- Chart：library Chart，[`Chart.yaml`](Chart.yaml) 必须声明 `kubeVersion: ">=1.36.0"`。
- 仅使用 Helm 内置函数、Go Template、Sprig 与 Helm 特有函数；严禁臆造。
- 角色：资深 DevOps、云原生架构师

## 工作原则

- 保持标准化、低幻觉、类型稳定和代码 DRY，并遵循 Helm 与 Kubernetes 最佳实践。
- 使用中文；数字、英文与中文混排保留必要空格；文件引用使用工作区相对路径。
- 变更文档的入口、归属和推断保护统一遵循 [`openspec/rules/change-documents.md`](openspec/rules/change-documents.md)，不得在其他层复述为第二套规则。
- 文件末尾有且仅有一个换行符。

## 上下文访问

- 文件路径必须来自已读文档的明确链接、本文映射或已授权目录的文件清单。AI 会话命令名与文件名属于不同命名空间；不得通过增删或替换命令前后缀猜测文件名。缺少映射时，先查询真实文件列表，再读取已确认的路径。
- 命令只读取完成当前职责所需的当前文件；事实一经用户输入、当前规格或适用规则确认即停止扩张上下文。正式代码只说明实现现状，不能反向生成需求。
- 搜索只用于确认真实文件名或在已授权文件中定位标识符；不得借此通读调用方、相邻能力、其他 change 或归档内容。
- 仅当缺少会改变契约的版本特定事实时读取精确的本地参考片段；仍不足时查询精确的官方资源。参考资料不得扩张需求。

## 命令入口

```text
/sdd-draft
  → /sdd-plan
  → /sdd-apply（可重复执行）
  → /sdd-verify（可独立、可重复执行）
  → 人工 Review
  → /sdd-merge
```

| 命令 | 唯一定义文件 | 唯一主要职责 |
|---|---|---|
| `/sdd-draft` | [`openspec/commands/draft.md`](openspec/commands/draft.md) | 新建或继续只表达意图的轻量 `draft.md`。 |
| `/sdd-plan` | [`openspec/commands/plan.md`](openspec/commands/plan.md) | 从 draft 生成变更契约；无阻塞项时进入 `planned`。 |
| `/sdd-apply` | [`openspec/commands/apply.md`](openspec/commands/apply.md) | 可重复按变更契约生成代码并输出变更摘要。 |
| `/sdd-verify` | [`openspec/commands/verify.md`](openspec/commands/verify.md) | 独立执行真实验证、生成验证记录并更新验证状态。 |
| `/sdd-revise` | [`openspec/commands/revise.md`](openspec/commands/revise.md) | 将未合并 change 退回 `draft` 并使验证证据失效。 |
| `/sdd-merge` | [`openspec/commands/merge.md`](openspec/commands/merge.md) | 检查验证证据、合并规格、同步用户文档并归档。 |
| `/ck-deploy` | [`openspec/commands/ck-deploy.md`](openspec/commands/ck-deploy.md) | 对整个 Chart 执行发布检查。 |

收到任一命令时，先读取精简状态机 [`openspec/workflow.md`](openspec/workflow.md)，再读取 [`openspec/commands/`](openspec/commands/) 中对应的命令文件，并在其上下文边界内完成职责。命令是 AI 会话触发命令，不是 shell 命令。

## 规则路由

仅按当前阶段和修改范围读取：

- 用户入口保护、frontmatter 与变更记录：[`openspec/rules/change-documents.md`](openspec/rules/change-documents.md)
- 规格语法、合并或整理：[`openspec/rules/specifications.md`](openspec/rules/specifications.md)
- Helm 模板：[`openspec/rules/helm-templates.md`](openspec/rules/helm-templates.md)
- 核心命名模板调用：[`openspec/rules/core-capabilities.md`](openspec/rules/core-capabilities.md)
- values、Schema 或用户配置：[`openspec/rules/values-schema.md`](openspec/rules/values-schema.md)
- README、`docs/` 或样例：[`openspec/rules/documentation.md`](openspec/rules/documentation.md)
