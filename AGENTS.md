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
- 文件末尾有且仅有一个换行符。

## 快速开始

- 需求不明确：先分析代码和选项，不创建占位规格。
- 新建或继续未批准草案：`/sdd-new <change-id> [能力名]`。
- 继续其他阶段：读取 `openspec/changes/<change-id>/`，再执行对应快捷命令。

```text
/sdd-new
→ /sdd-approve
→ /sdd-apply
→ /sdd-verify
→ 人工 Review
→ /sdd-spec
```

`/sdd-new` 在批准前按需完成探索、设计和任务拆分；存在未决用户选择或需要独立设计 Review 时提前停止。完整流程、文件格式、批准冻结和返工规则只在 [`openspec/workflow.md`](openspec/workflow.md) 定义。收到任一 `/sdd-*` 或 `/ck-deploy` 命令时必须先读取该文件；这些是 AI 会话触发命令，不是 shell 命令。

## 命令入口

| 命令 | 目的 |
|---|---|
| `/sdd-new` | 新建或继续未批准草案，完成批准前准备，不修改正式代码。 |
| `/sdd-approve` | 由用户确认并冻结 proposal 与变更规格。 |
| `/sdd-apply` | 按已批准规格实施。 |
| `/sdd-revise` | 使批准失效，受控修改需求后重新批准。 |
| `/sdd-verify` | 验证规格、实现和证据一致。 |
| `/sdd-spec` | 合并当前规格、同步用户文档并归档。 |
| `/sdd-rewrite` | 不改变行为地整理当前规格。 |
| `/ck-deploy` | 对整个 Chart 执行发布检查。 |

## 规则路由

任何修改都读取 [`openspec/workflow.md`](openspec/workflow.md) 的适用章节，再按范围追加读取：

- Helm 模板或样例：[`openspec/rules/helm-templates.md`](openspec/rules/helm-templates.md) 与 [`openspec/rules/core-capabilities.md`](openspec/rules/core-capabilities.md)
- values、Schema 或用户配置：[`openspec/rules/values-schema.md`](openspec/rules/values-schema.md)
- OpenSpec、README 或其他文档：[`openspec/rules/documentation.md`](openspec/rules/documentation.md)
- 开发检查：[`openspec/checks/development.md`](openspec/checks/development.md)
- 发布检查：[`openspec/checks/release.md`](openspec/checks/release.md)

修改已有能力时读取 [`openspec/specs/<能力名>/spec.md`](openspec/specs/)；继续活动变更时从 [`openspec/changes/<change-id>/`](openspec/changes/) 读取 proposal、变更规格、tasks、存在的 design、approval 和 verification。

Helm CLI 固定使用 `/opt/homebrew/bin/helm`。模板变更至少执行 Helm lint、最小有效输入、较完整有效输入和关键失败输入验证；临时文件只创建于 `/tmp/` 并在完成后清理。
