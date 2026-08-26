# kube-chart SDD 状态机

本文件只定义所有命令共享的状态、目录和边界。命令职责与读取范围位于 [`commands/`](commands/)，不得在此重复。

## 核心边界

- `openspec/changes/<change-id>/draft.md` 是用户唯一输入入口，其 frontmatter 是 change 身份、目标文件和当前阶段的唯一状态源。
- `plan/` 和 `records/` 由 AI 维护；用户不需要跨文件同步修改。
- draft 可以包含 AI 草稿，但必须逐项标记 `[AI 推断]`；未确认推断不得进入 spec 的 MUST 条目。
- 每次会话结束前，本次变更意图的新增、修改或删除必须写回 draft；尚未确认、存在歧义或冻结状态不允许写回时，必须输出明确修订建议。
- 每个命令只产生其命令文件声明的一类主要输出；draft frontmatter、批准记录和验证记录属于对应阶段的门禁记账。
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
    verification.md         实施检查必需、独立验证可选的统一验证记录
```

change 根目录只保留 `draft.md`、`plan/` 和按需创建的 `records/`；不得散放其他阶段产物。

## 状态

| frontmatter `status` | 含义 | 下一步 |
|---|---|---|
| `draft` | 用户正在整理目标 | `/sdd-plan` |
| `planned` | AI 草稿无阻塞项，可以批准 | `/sdd-approve` |
| `approval-pending` | 批准检查通过，等待用户确认 | 用户确认 `/sdd-approve` |
| `approved` | 契约已冻结 | `/sdd-apply` |
| `implementing` | 正在修改正式代码 | 继续 `/sdd-apply` |
| `implemented` | 实现与必需实施检查已完成并记录 | 可选 `/sdd-verify` 或人工 Review |
| `verified` | 可选一致性验证已通过 | 人工 Review 后 `/sdd-merge` |
| `revision` | 原批准已失效 | 修改 draft 后 `/sdd-plan` |

归档后的 `status` 为 `merged`。不得根据文件是否存在猜测阶段；先读取 draft frontmatter，再按命令文件读取必要内容。

允许的主路径：

```text
draft ──/sdd-plan（有阻塞项）──→ draft
draft ──/sdd-plan（无阻塞项）──→ planned → approval-pending → approved
                                                          ↓
                                            implementing → implemented
                                                           ├→ verified → /sdd-merge
                                                           └────────────→ /sdd-merge
任一已批准未归档阶段 → revision → planned
```

## 通用门禁

- 未批准不得执行 `/sdd-apply`。
- 冻结后需求变化必须执行 `/sdd-revise`，不得直接修改 plan 来绕过重新批准。
- 冻结摘要使用忽略 frontmatter 单一 `status:` 行后的 draft 内容；正常阶段更新不得使批准失效。
- plan 阶段发现 `draft-content-sha256` 不匹配时视为 draft 已修改，必须重新 `/sdd-plan`；批准后发现不匹配时立即停止，并要求 `/sdd-revise`。
- `/sdd-plan` 发现 `[AI 推断]`、`[待补充]`、未决设计选择或验收缺口时，仍可刷新轻量 plan，但 `status` 必须保持 `draft`；全部消除后才进入 `planned`。
- `records/verification.md` 是实施后必需的统一验证记录：`/sdd-apply` 写入“实施检查”，可选 `/sdd-verify` 写入“独立验证”。
- `/sdd-verify` 不是 `/sdd-merge` 的硬依赖；但合并前“实施检查”必须通过。已执行独立验证时，其结果也必须通过且与当前冻结摘要一致。
- 未实现的子模板不扩大当前 change 范围。验证父模板时假设该子模板满足冻结的最小返回契约；需要临时同名 `define` 时只能放在 `/tmp/`，并明确不代表真实集成。
- `/sdd-merge` 前必须有有效批准和已完成实现；用户执行该命令即确认人工 Review 已完成。是否跳过独立 verify 必须在最终命令报告中明确。
- 只有一个活动 change 时可省略 change-id；存在多个时必须显式指定，AI 不得猜测。
