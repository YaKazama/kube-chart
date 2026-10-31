# 变更文档规则

## 意图入口与所有权

1. `draft.md` 是用户意图、已形成共识和开放问题的入口；用户维护正文，frontmatter 由 AI 维护。
2. AI 可以生成或整理草稿，但不得覆盖、弱化或静默改写用户已确认的意图。
3. 用户明确写出或通过 `/opsx:explore` 确认的内容优先于 AI 推断。
4. AI 推断内容必须标记 `[AI 推断]`；不得伪装成用户需求、既定约束或已形成共识。
5. 未经用户确认，`[AI 推断]` 不得派生 Requirement、设计决策或 task。
6. 已形成的共识必须在同一动作写回 `draft.md` 或用户当前命令指定的 change 内笔记文件；未形成共识时必须记录为开放问题。
7. `spec.md` 是行为契约，`design.md` 是技术设计契约，`tasks.md` 是实施与验证契约；三者共同构成当前 change 的执行契约。
8. draft 在 change 活动期间可以继续澄清；draft 变化导致执行契约失去闭包时，必须重新执行 `/opsx:spec`，不得凭旧确认标记继续实施。

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

## 执行制品归属与确认

- `spec.md`、`design.md` 和 `tasks.md` 位于 change 根目录。`/opsx:spec` 负责创建、校对、更新和闭包；`/opsx:sync` 经确认后可以按代码与测试事实同步三者，但禁止修改 draft。
- `/opsx:code` 只修改正式代码和已真实完成的实施 task checkbox；`/opsx:verify` 只修改已真实通过的验证 task checkbox；二者不得改写 task 文本。
- `spec.md` frontmatter 只包含 `confirmed` 和 `updated_at`：

```yaml
confirmed: true | false
updated_at: "<UTC RFC 3339 时间>"
```

- `confirmed: true` 确认同目录当前 spec、design 和 task 文本的组合，不是阶段状态。`design.md` 和 `tasks.md` 不使用 frontmatter。
- `/opsx:spec` 创建、更新或补全任一执行制品正文时写入 `confirmed: false`；用户执行 `/opsx:spec <change-id> --confirm` 后，命令重新完成闭包且内容无待决差异时，才改为 `true`。
- `/opsx:sync <change-id>` 当前命令中的“确认回写”区块表示用户确认本轮按当前文件重新计算出的精确同步项；只有确认覆盖全部实际差异且同步后四向闭包成立时才写入 `confirmed: true`，否则写入 `false`。
- 仅勾选既有 checkbox 不改变 `confirmed`；checkbox 的证据失效时必须取消勾选。
- v0.2.0 动作实际修改仍带旧 `status` frontmatter 的活动 spec 时，应把它迁移为上述 `confirmed` 结构；历史归档不批量改写。
- `spec.md` 正文归属和语法遵循 [`specifications.md`](specifications.md)，`design.md` 遵循 [`designs.md`](designs.md)，`tasks.md` 遵循 [`tasks.md`](tasks.md)。

## 同步保护

- 代码和测试可以证明当前实现事实，不能独自证明用户原始意图。可观察行为变化必须在 `/opsx:sync` 预览中单独列为待确认项。
- `/opsx:sync` 回写前必须先输出代码事实、现有制品差异、建议更新、疑似冲突、待确认项和不建议写入规格项；没有当前输入或代码库变更说明中的精确确认时不得写文件。
- 同步只更新已确认差异直接涉及的 spec、design 和 tasks，不顺带整理无关内容，不修改 `draft.md`、正式代码或用户文档。
- 无法从当前文件和同步说明唯一确定的行为、设计或任务保持不变，并作为疑似冲突或待确认项报告。

## 归档

- `/opsx:archive` 轻量核对通过后，把完整 change 目录移动到 `openspec/changes/archive/YYYY-MM-DD-<change-id>/`，不通过状态字段表示归档。
- 归档目标已存在时停止，不覆盖既有归档。
- 归档摘要输出到会话；除非当前 change 的正式制品明确要求，否则不创建额外 verification、sync 或 summary 记录。
- 历史归档可以保留旧工作流结构和 frontmatter，但不能替代当前活动 change 的意图或执行契约。
