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

- `proposal.md` 是草案阶段唯一的用户输入入口，只使用“目标、需求、约束”三节；用户可以直接修改三节，也可以在会话中描述，由 AI 代为更新。
- proposal 的“约束”只保存用户明确指定的本次变更特殊限制；用户未指定时保持空白。AI 不得把项目基线、通用规则或自行推导的限制写入该节，而应补充到生成后的规格、design 或 tasks。
- 参考资料由 AI 根据本文件、OpenSpec 规则、当前规格、目标代码和官方资料自行读取，不要求用户维护“参考”字段；用户主动提供的特殊依据归入需求或约束。
- 变更规格、`artifacts/design.md` 和 `artifacts/tasks.md` 是批准前的 AI 同步产物，不要求用户跨文件修改；它们只引用 proposal 中的稳定编号，不重复维护完整用户输入。`artifacts/verification.md` 只在正式实现完成后的 `/sdd-verify` 阶段创建。
- 顶层目标明确但子模板尚未定义时，在 proposal 的“目标”中添加带编号的 checkbox 占位，继续自顶向下准备 AI 产物，等待用户确认或修改该行；不得要求用户改走自底向上或原始 map 透传。
- 新建或继续未批准草案：`/sdd-new <change-id> <主要能力名> <define名称=tpl文件>...`。
- 继续其他阶段：读取 `openspec/changes/<change-id>/`，再执行对应快捷命令。

```text
/sdd-new
→ /sdd-approve
→ /sdd-apply
→ /sdd-verify
→ 人工 Review
→ /sdd-spec
```

`/sdd-new` 先校验目标，再把用户明确输入整理到 proposal 的三节中，并由 AI 根据项目上下文自顶向下补全变更规格、按需探索、design 和 tasks。缺失子模板只在 proposal 维护一份占位定义，其他材料引用编号。只有顶层行为本身存在真实未决选择或需要独立设计 Review 时才提前停止。完整流程、文件格式、批准冻结和返工规则只在 [`openspec/workflow.md`](openspec/workflow.md) 定义。收到任一 `/sdd-*` 或 `/ck-deploy` 命令时必须先读取该文件；这些是 AI 会话触发命令，不是 shell 命令。

## 命令入口

| 命令 | 目的 |
|---|---|
| `/sdd-new` | 按主要能力和 `define名称=tpl文件` 目标新建或继续未批准草案，完成批准前准备，不修改正式代码。 |
| `/sdd-approve` | 由用户确认并冻结 proposal 与变更规格。 |
| `/sdd-apply` | 按已批准规格实施。 |
| `/sdd-revise` | 使批准失效，受控修改需求后重新批准。 |
| `/sdd-verify` | 在正式实现完成后验证规格与实现，并创建实际验证记录。 |
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

修改已有能力时读取 [`openspec/specs/<能力名>/spec.md`](openspec/specs/)；继续活动变更时从 [`openspec/changes/<change-id>/`](openspec/changes/) 读取 `proposal.md`、`specs/`，以及 `artifacts/` 下存在的 `design.md`、`tasks.md`、`approval.md` 和实施后 `verification.md`。

Helm CLI 固定使用 `/opt/homebrew/bin/helm`。模板变更至少执行 Helm lint、最小有效输入、较完整有效输入和关键失败输入验证；临时文件只创建于 `/tmp/` 并在完成后清理。
