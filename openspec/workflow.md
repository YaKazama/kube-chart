# kube-chart SDD 状态机

本文件是阶段、状态转换和共享门禁的唯一来源。命令职责与读取范围位于 [`commands/`](commands/)，变更文档规则位于 [`rules/change-documents.md`](rules/change-documents.md)。

## 共享边界

- `draft.md` frontmatter 的 `status` 是当前阶段的唯一状态源；不得根据其他文件是否存在猜测阶段。
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
| `approved` | 契约已冻结 | `/sdd-apply`，或对已就绪的当前实现独立执行 `/sdd-verify` |
| `applied` | 正式代码已处于可验证状态，但尚无有效的通过证据 | 可重复执行 `/sdd-apply`，或执行 `/sdd-verify` |
| `verified` | 真实项目命令验证通过并已记录证据 | 人工 Review 后 `/sdd-merge` |
| `merged` | 当前规格和用户文档已同步，change 已归档 | 无 |

允许的转换：

```text
draft ──/sdd-plan（有阻塞项）──→ draft
draft ──/sdd-plan（无阻塞项）──→ planned → approved → applied → verified → merged
applied ──/sdd-apply（重复执行）──→ applied
approved ──/sdd-verify（独立验证通过）──→ verified
任一未合并状态 ──/sdd-revise──→ draft
```

## 通用门禁

- `/sdd-plan` 可在技术目标、用户意图、设计选择或验收待确认时生成草稿；全部解决后才能进入 `planned`。
- 未批准不得执行 `/sdd-apply`。该命令从 `approved` 首次执行或从 `applied` 以当前正式代码、冻结契约和任务状态为基础幂等续作；代码或实施任务未完成时状态不变。它只生成代码、更新实施任务并输出摘要，不执行验证。
- `approved`、`applied` 和 `verified` 必须保持批准记录有效；有效性按 [`rules/change-documents.md`](rules/change-documents.md) 的冻结摘要规则判断。
- `/sdd-verify` 可从上述三种状态独立执行，不依赖 `/sdd-apply` 的会话或输出。通过时进入或保持 `verified`；失败时不得保留本轮通过结论，原 `verified` 重置为 `applied`，其他状态不变。
- `/sdd-merge` 只接受 `verified`；用户执行即确认已完成人工 Review。该命令只检查既有证据，不重跑完整验证。
- `/sdd-revise` 不检查原状态或 approval，将状态重置为 `draft`，移除当前 change 的 `plan/` 与 `records/`，但不修改 draft 正文、正式代码或 change 外文件。冻结后需求变化必须先执行该命令，不得直接修改 plan 绕过重新批准。
- 只有一个活动 change 时可省略 change-id；存在多个时必须显式指定，AI 不得猜测。
