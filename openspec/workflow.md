# kube-chart SDD 状态机

本文件只定义所有命令共享的状态、目录和边界。命令职责与读取范围位于 [`commands/`](commands/)，不得在此重复。

## 核心边界

- `openspec/changes/<change-id>/draft.md` 是用户唯一输入入口。用户只表达意图；其 frontmatter 由 AI 维护，是 change 身份、技术目标和当前阶段的唯一状态源。
- `/sdd-draft` 不强制用户提供主要能力、define 名称或目标路径；`/sdd-plan` 必须在生成 plan 前先解析并校验这些技术目标，无法唯一确定时保持 `draft` 并报告待确认项。
- `plan/` 和 `records/` 由 AI 维护；用户不需要跨文件同步修改。
- draft 可以包含 AI 草稿，但必须逐项标记 `[AI 推断]`；未确认推断不得进入 spec 的 MUST 条目。
- 每次会话结束前，本次变更意图的新增、修改或删除必须写回 draft；尚未确认、存在歧义或冻结状态不允许写回时，必须输出明确修订建议。
- 每个命令只产生其命令文件声明的一类主要输出；draft frontmatter、批准记录和验证记录属于对应阶段的门禁记账。
- 状态只表示最近完成的稳定门禁。等待确认、执行中、失败或修订不创建额外状态。
- 检查清单只提示需要执行的场景，不是校验器或通过证据。验证结论必须来自仓库真实存在的项目命令及其实际退出码和输出，不得臆造命令或校验器。
- AI 每次先报告当前阶段，再执行命令；结束时只报告新阶段、主要产物、待确认问题和下一步。
- 当前规格与已冻结的变更规格优先于实现；不得用现有代码或历史决定反向改写当前需求。

## 目录

```text
openspec/changes/<change-id>/
  draft.md                  用户唯一输入及 frontmatter 状态
  plan/                     /sdd-plan 的一类派生产物
    spec.md                 行为契约草稿
    design.md               仅在存在重要技术决策时创建
    tasks.md                简短实施顺序
  records/                  阶段记录，按需创建
    approval.md             /sdd-approve 的检查与冻结记录
    verification.md         /sdd-verify 生成的人类可读真实命令证据
```

change 根目录只保留 `draft.md`、`plan/` 和按需创建的 `records/`；不得散放其他阶段产物。

## 状态

| frontmatter `status` | 含义 | 下一步 |
|---|---|---|
| `draft` | 用户正在整理目标 | `/sdd-plan` |
| `planned` | AI 草稿无阻塞项，可以批准 | `/sdd-approve` |
| `approved` | 契约已冻结 | `/sdd-apply` |
| `applied` | 正式代码已按冻结契约完成修改 | `/sdd-verify` |
| `verified` | 真实项目命令验证通过并已记录证据 | 人工 Review 后 `/sdd-merge` |
| `merged` | 当前规格和用户文档已同步，change 已归档 | 无 |

不得根据文件是否存在猜测阶段；先读取 draft frontmatter，再按命令文件读取必要内容。

允许的主路径：

```text
draft ──/sdd-plan（有阻塞项）──→ draft
draft ──/sdd-plan（无阻塞项）──→ planned → approved → applied → verified → merged
任一已批准未合并阶段的需求修订 ──/sdd-revise──→ draft
```

## 通用门禁

- 未批准不得执行 `/sdd-apply`。
- 冻结后需求变化必须执行 `/sdd-revise`，不得直接修改 plan 来绕过重新批准。
- 冻结摘要使用忽略 frontmatter 单一 `status:` 行后的 draft 内容；正常阶段更新不得使批准失效。
- `/sdd-plan` 必须先解析并校验 capability、artifact-type、template-name 和 target-path。只有技术目标唯一、合法且无活动 change 冲突时才生成或刷新 plan；无法确定时保持 `draft`，报告候选项和需要用户确认的问题。
- plan 阶段发现 `draft-content-sha256` 不匹配时视为 draft 已修改，必须重新 `/sdd-plan`；批准后发现不匹配时立即停止，并要求 `/sdd-revise`。
- `/sdd-plan` 发现 `[AI 推断]`、`[待补充]`、未决设计选择或验收缺口时，仍可刷新轻量 plan，但 `status` 必须保持 `draft`；全部消除后才进入 `planned`。
- `/sdd-apply` 接受 `approved`，也允许在验证失败后从 `applied` 修复实现；只修改正式代码并运行必要的真实项目命令获得开发反馈，不创建验证记录。未完成时保持进入命令前的稳定状态。
- `/sdd-verify` 必须基于当前正式实现重新运行完整真实命令矩阵，并创建或覆盖人类可读的 `records/verification.md`。全部通过后才进入 `verified`，失败时保持 `applied`。
- 临时同名 `define` 只能作为 `/tmp/` 中的测试 fixture，并必须在验证记录中标明范围和限制；它不代表真实子模板集成。冻结契约要求真实集成时，不得使用 fixture 得出通过结论。
- `/sdd-merge` 前必须处于 `verified` 且批准仍然有效；用户执行该命令即确认人工 Review 已完成。
- 只有一个活动 change 时可省略 change-id；存在多个时必须显式指定，AI 不得猜测。
