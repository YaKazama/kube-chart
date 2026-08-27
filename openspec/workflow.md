# kube-chart SDD 状态机

本文件是阶段、状态转换和共享门禁的唯一来源。命令职责与读取范围位于 [`commands/`](commands/)，变更文档规则位于 [`rules/change-documents.md`](rules/change-documents.md)。

## 共享边界

- `draft.md` frontmatter 的 `status` 是当前阶段的唯一状态源；不得根据其他文件是否存在猜测阶段。
- 状态只表示最近完成的稳定门禁。等待确认、执行中、失败或修订不创建额外状态。
- 每个命令只产生其命令文件声明的一类主要输出；状态更新和阶段记录不视为额外主要输出。
- 当前规格与进入 `planned` 后的变更规格优先于实现；契约有误时必须回到 `draft` 修订，不得按现有代码反写需求。
- 任一事实已由较高优先级上下文唯一确认后必须停止，不得继续读取代码、调用链、参考资料或外部页面交叉佐证。

## 目录

```text
openspec/changes/<change-id>/
  draft.md                  用户唯一输入及 frontmatter 状态
  plan/
    spec.md                 /sdd-plan 生成的技术目标与行为契约
  records/                  阶段记录，按需创建
    verification.md         /sdd-verify 生成的人类可读真实命令证据
```

change 根目录只保留 `draft.md`、`plan/` 和按需创建的 `records/`；不得散放其他阶段产物。

## 状态

| frontmatter `status` | 含义 | 下一步 |
|---|---|---|
| `draft` | 用户正在整理目标 | `/sdd-plan` |
| `planned` | 变更契约无阻塞项，可以实施或对已就绪实现直接验证 | `/sdd-apply` 或 `/sdd-verify` |
| `applied` | 正式代码已处于可验证状态，但尚无有效的通过证据 | 可重复执行 `/sdd-apply`，或执行 `/sdd-verify` |
| `verified` | 真实项目命令验证通过并已记录证据 | 人工 Review 后 `/sdd-merge` |
| `merged` | 当前规格和用户文档已同步，change 已归档 | 无 |

允许的转换：

```text
draft ──/sdd-plan（有阻塞项）──→ draft
draft ──/sdd-plan（无阻塞项）──→ planned → applied → verified → merged
applied ──/sdd-apply（重复执行）──→ applied
planned ──/sdd-verify（独立验证通过）──→ verified
任一未合并状态 ──/sdd-revise──→ draft
```

## 通用门禁

- `/sdd-plan` 可在技术目标、用户意图、契约选择或验收待确认时生成草稿并保持 `draft`；全部解决后进入 `planned`。
- `/sdd-apply` 从 `planned` 首次执行或从 `applied` 以当前正式代码和 `plan/spec.md` 为基础幂等续作；实现未满足契约时状态不变。它只生成代码并输出摘要，不执行验证。
- `/sdd-verify` 可从上述三种状态独立执行，不依赖 `/sdd-apply` 的会话或输出。通过时进入或保持 `verified`；失败时不得保留本轮通过结论，原 `verified` 重置为 `applied`，其他状态不变。
- `/sdd-merge` 只接受 `verified`；用户执行即确认已完成人工 Review。该命令只检查既有证据，不重跑完整验证。
- `/sdd-revise` 将任一未合并 change 退回 `draft`，保留 `draft.md` 与 `plan/spec.md` 供修订，并移除失效的验证记录；不修改正式代码或 change 外文件。进入 `planned` 后的需求或契约变化必须先执行该命令。
- change-id 是用户必填参数，必须精确匹配 `openspec/changes/<change-id>/draft.md`；正常执行时直接访问该路径，不得预先扫描活动 change，也不得省略、模糊匹配、自动纠错或根据唯一活动 change 推断。目标不存在时停止执行并提示用户修正 change-id。
