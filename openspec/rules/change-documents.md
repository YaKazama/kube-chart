# 变更文档规则

## 意图入口与所有权

1. `draft.md` 是用户意图、已形成共识和开放问题的入口；用户和 `/opsx:explore`、`/opsx:sync` 维护正文，frontmatter 由 AI 维护。
2. AI 可以生成、整理或按已授权动作直接改写草稿，但不得删除、弱化或反向覆盖用户已确认的意图。
3. 用户明确写出或通过 `/opsx:explore`、`/opsx:sync` 确认的内容优先于 AI 推断。
4. 用户明确提出或在 `/opsx:explore` 中确认的期望输入格式、输入形态和输入约束，属于用户意图，必须写入 `draft.md` 的“需求”或“约束”；未确认的候选格式只能记录为开放问题或 change 内笔记。
5. AI 推断内容必须标记 `[AI 推断]`；不得伪装成用户需求、既定约束或已形成共识。
6. 未经用户确认，`[AI 推断]` 不得派生 Requirement、设计决策或 task。执行 `/opsx:sync` 即视为该轮代码与测试事实已获授权，写入的条目不使用 `[AI 推断]` 标记。
7. 已形成的共识必须在同一动作写回 `draft.md` 或用户当前命令指定的 change 内笔记文件；未形成共识时必须记录为开放问题。
8. `spec.md` 是行为契约，`design.md` 是技术设计契约，`tasks.md` 是实施与验证契约；三者共同构成当前 change 的执行契约。
9. draft 在 change 活动期间可以继续澄清；draft 变化导致执行契约失去闭包时，必须重新执行 `/opsx:spec`，不得凭旧制品继续实施。`/opsx:sync` 同一动作内写入并与 spec 对齐的 draft 条目不触发该要求。

用户确认 `[AI 推断]` 后，AI 在同一动作将其改为普通条目；用户否决时删除该条目。需要保留讨论过程时写入用户指定的 change 内笔记文件，不在正式制品中混入会话流水。

## draft.md 格式

```markdown
---
change-id: <kebab-case>
updated_at: "<UTC RFC 3339 时间>"
---

# <变更名称>

## 目标

- <要解决的问题或预期结果>

## 需求

- <输入、输出、默认值或失败行为>
- `[AI 推断]` <待确认的建议>

## 期望输入格式

<!-- 只填写用户明确指定的本次特殊限制。 -->

## 约束

<!-- 只填写用户明确指定的本次特殊限制。 -->

## 非目标

- <本次明确不处理的内容>

## 验收

- <可观察且可判定的结果>

## 开放问题

- <尚未形成共识且会影响后续制品的事项>
```

- 上述章节可以按实际意图增删或重排，但必须清楚区分已确认内容、`[AI 推断]` 和开放问题。
- frontmatter 只含 `change-id` 和 `updated_at`；不得写入状态字段。
- change-id 取自 `openspec/changes/<change-id>/` 目录名，两者必须完全一致。
- `updated_at` 只在 draft 正文实际变化时更新。
- 条目不强制编号；需要引用时使用章节名加条目原文。
- 项目基线、通用规则、代码事实或历史决定不得伪装为用户意图写入；AI 建议只能标记 `[AI 推断]`。
- draft 保持轻量，不写精确实现步骤、代码边界、任务进度或验证结论。

## 执行制品归属与回写授权

- `spec.md`、`design.md` 和 `tasks.md` 位于 change 根目录。`/opsx:spec` 负责创建、校对、更新和闭包；`/opsx:sync` 可以按代码与测试事实同步三者，并在同一动作内维护 `draft.md` 保持意图与行为对齐。
- `/opsx:code` 只修改正式代码和已真实完成的实施 task checkbox；`/opsx:verify` 只修改已真实通过的验证 task checkbox；二者不得改写 task 文本。
- `spec.md` frontmatter 只包含 `updated_at`：

```yaml
updated_at: "<UTC RFC 3339 时间>"
```

- `design.md` 和 `tasks.md` 不使用 frontmatter。
- `/opsx:spec` 和 `/opsx:sync` 只在正文实际变化时更新 `updated_at`。
- `spec.md` 正文归属和语法遵循 [`specifications.md`](specifications.md)，`design.md` 遵循 [`designs.md`](designs.md)，`tasks.md` 遵循 [`tasks.md`](tasks.md)。

## 同步保护

- 代码和测试可以证明当前实现事实，不能独自证明用户原始意图。可观察行为变化必须在 `/opsx:sync` 报告中标列为行为变化项。
- `draft.md` 与 `spec.md` 必须始终对齐：spec 的每项 Requirement、Scenario、失败边界和非目标都必须在 draft 的“目标”“需求”“验收”或“非目标”中有对应条目。`/opsx:sync` 写入新的可观察行为时，必须同一动作补充对应 draft 条目。
- `/opsx:sync` 只能向 draft 追加条目或更新本轮差异直接对应的条目，不得删除、弱化或改写其他既有意图；无法确定条目归属或代码事实与既有意图冲突时不写 spec，并报告需补齐的缺口。draft 正文变化时同步更新其 `updated_at`。
- 执行 `/opsx:sync` 即代表本轮回写已获授权，在同一个动作内完成报告、回写和闭包；缺少本次授权的其他动作不得改写 draft 或执行制品。
- 同步只更新差异直接涉及的 spec、design、tasks 和保持对齐所需的 draft 条目，不整理无关内容，不修改正式代码或用户文档。
- 无法从当前文件和同步说明唯一确定的行为、设计或任务保持不变，并作为疑似冲突或缺口报告。

## 归档

- `/opsx:archive` 轻量核对通过后，把完整 change 目录移动到 `openspec/changes/archive/YYYY-MM-DD-<change-id>/`，不通过状态字段表示归档。
- 归档目标已存在时停止，不覆盖既有归档。
- 归档摘要输出到会话；除非当前 change 的正式制品明确要求，否则不创建额外 verification、sync 或 summary 记录。
- 历史归档可以保留旧工作流结构和 frontmatter，但不能替代当前活动 change 的意图或执行契约。
