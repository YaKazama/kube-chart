# kube-chart SDD 状态机

本文件是阶段、状态转换和共享门禁的唯一来源。命令职责与读取范围位于 [`commands/`](commands/)，变更文档规则位于 [`rules/change-documents.md`](rules/change-documents.md)。

## 共享边界

- draft frontmatter 中的 `status` 是当前阶段的唯一状态源；不得根据其他文件是否存在猜测阶段。
- 状态只表示最近完成的稳定门禁。等待确认、执行中、失败或修订不创建额外状态。
- 每个命令只产生其命令文件声明的一类主要输出；状态更新和阶段记录不视为额外主要输出。
- 当前规格与有效的冻结变更规格优先于实现；契约有误时必须回到 `draft` 修订，不得按现有代码反写需求。

## 目录

```text
openspec/changes/<change-id>/
  draft.md                  用户唯一输入及 frontmatter 状态
  plan/                     /sdd-plan 的一类派生产物
    spec.md                 技术目标与行为契约草稿
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

允许的主路径：

```text
draft ──/sdd-plan（有阻塞项）──→ draft
draft ──/sdd-plan（无阻塞项）──→ planned → approved → applied → verified → merged
任一已批准未合并阶段的需求修订 ──/sdd-revise──→ draft
```

## 通用门禁

- 未批准不得执行 `/sdd-apply`。
- 冻结后需求变化必须执行 `/sdd-revise`，不得直接修改 plan 来绕过重新批准。
- `/sdd-plan` 可以在技术目标、用户意图、设计选择或验收仍待确认时生成草稿，但只有全部解决后才能进入 `planned`。
- `approved`、`applied` 和 `verified` 阶段必须保持批准记录有效；有效性按 [`rules/change-documents.md`](rules/change-documents.md) 的冻结摘要规则判断。
- `/sdd-apply` 未完成或开发反馈失败时保持进入命令前的状态；`/sdd-verify` 失败时保持 `applied`。
- `/sdd-merge` 只接受 `verified`；用户执行该命令即确认人工 Review 已完成。
- 只有一个活动 change 时可省略 change-id；存在多个时必须显式指定，AI 不得猜测。
