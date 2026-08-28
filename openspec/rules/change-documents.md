# 变更文档规则

## 意图入口与所有权

1. `draft.md` 是执行契约生成前的用户意图入口；用户只维护表达意图的正文，frontmatter 由 AI 维护。
2. AI 可以生成草稿，但不得覆盖、弱化或静默改写用户已确认的意图。
3. 用户明确写出或在当前命令中确认的内容优先于 AI 推断。
4. AI 推断内容必须标记 `[AI 推断]`；这是 draft 中唯一的特殊标记，不得伪装成用户需求或明确约束。
5. 未经用户确认，`[AI 推断]` 条目不得派生 MUST、SHALL、设计决策或 task。
6. 本轮确认的意图变化直接写回 `draft.md`；内容未确认或存在歧义时只输出建议文本、原因和下一步。
7. `/opsx-spec` 一次性创建 spec、design 和 tasks 后冻结 draft；后续代码、Review 或归档不得修改 draft。
8. `spec.md` 是行为契约，`design.md` 是技术设计契约，`tasks.md` 是实施与验证契约；三者共同构成当前 change 的执行契约，任何单一制品不得替代其他职责。

用户确认 `[AI 推断]` 后，AI 在同一轮将其改为普通条目；用户否决时删除该条目，不在正文保留讨论历史。

## OPSX 执行上下文隔离

OPSX 动作只以当前命令输入、命令允许读取的当前工作区文件和当轮职责内的真实工具结果为业务依据。

- 历史聊天、旧摘要和旧工具输出不能替代当前制品、当前命令中的用户确认或本轮重新读取的当前事实。
- `/opsx-fix` 给出的回写建议只是待用户决定的会话输出，不会自动成为契约。
- `/opsx-spec-rewrite` 的当前命令必须携带用户确认的精确回写内容；只有命令名、泛化确认或上一轮摘要引用时停止，不修改规格。
- 读取代码得到的是实现事实或校验证据；不得据此补全 Requirement、默认值、失败边界或验收，只能形成满足既定行为的 design。
- 必要事实缺失时明确报告，不自行补全后宣称完成。

## draft.md 格式

```markdown
---
change-id: <kebab-case>
updated_at: "<UTC RFC 3339 时间>"
---

# <变更名称>

> 用户初始意图入口。
> 只需编辑下面的“目标、需求、约束、非目标、验收”。

## 目标

- <要解决的问题或预期结果>
- 依赖 `<外部能力>`，不属于当前实现范围。

## 需求

- <输入、输出、默认值或失败行为>
- `[AI 推断]` <待确认的建议>

## 约束

<!-- 只填写用户明确指定的本次特殊限制；AI 建议必须保留 [AI 推断]。 -->

## 非目标

- <本次明确不处理的内容>

## 验收

- <可观察且可判定的结果>
```

- frontmatter 只含 `change-id` 和 `updated_at`；不得写入 `status`。
- change-id 取自 `openspec/changes/<change-id>/` 目录名，两者必须完全一致。
- `updated_at` 只在 draft 实际变化时更新。
- 条目不强制编号；需要引用时使用章节名加条目原文。
- “约束”可为空。项目基线、通用规则、代码事实或历史决定不得作为普通条目写入；AI 建议只能标记 `[AI 推断]`。
- draft 保持轻量，不写方案比较、实现步骤、代码边界、验证记录或长篇背景。

## 执行制品归属

- `spec.md`、`design.md` 和 `tasks.md` 位于 change 根目录，只由 `/opsx-spec` 在同一次成功动作中首次创建。存在任一文件时不得覆盖、刷新、补齐或重新生成。
- 三个候选制品必须在内存中通过工作流闭包检查后一次性写入；写入失败造成部分制品时保持无效状态，后续 OPSX 动作停止并报告实际文件，不自动修复。
- `spec.md` frontmatter 只含 `status` 和 `updated_at`；状态取值和转换遵循 [`../workflow.md`](../workflow.md)。`design.md` 和 `tasks.md` 不使用 frontmatter。
- `spec.md` 只拥有 Purpose、Requirement、Scenario、失败边界和非目标，语法遵循 [`specifications.md`](specifications.md)。
- `design.md` 只拥有技术目标、设计决策、依赖契约、代码边界和验证设计，语法遵循 [`designs.md`](designs.md)。
- `tasks.md` 只拥有实施和验证 checkbox，语法遵循 [`tasks.md`](tasks.md)。
- `/opsx-code` 成功进入 `code` 前，spec 和 design 正文及 task 文本已锁定；code 只能更新 task checkbox。进入 `code` 后，design、tasks 和代码边界全部锁定。

## 局部修正与回写

- `/opsx-fix` 只修改 design 中已锁定的 write boundary 和 writable scope，不修改四个 change 制品或用户文档。
- 修正只涉及重构、类型稳定、语法、DRY 或恢复现有 spec/design 行为时，回写结论为 `无需回写`。
- 修正改变输入、输出、默认值、失败边界、可观察行为或验收时，回写结论为 `必须回写`；会话同时给出可供用户确认的精确规格文本。
- 必须回写的代码在 `/opsx-spec-rewrite` 完成前不得通过 `/opsx-review`；回写会使 design 或 tasks 失效时不得执行回写，必须新建 change 或恢复代码。
- 用户拒绝回写时，必须通过新的 `/opsx-fix` 把代码恢复为当前 spec 所定义的行为；不得用 Review 摘要覆盖契约差异。

## 归档

- `/opsx-review` 成功后，将 `spec.md` 状态更新为 `reviewed`，再把包含 draft、spec、design 和 tasks 的 change 目录移动到 `openspec/changes/archive/YYYY-MM-DD-<change-id>/`。
- 归档目标已存在时停止，不覆盖既有归档。
- Review 摘要只输出到会话，不创建 verification、sync 或其他记录文件。
- 历史归档可以保留旧工作流结构，但不能作为当前意图、执行契约或验证结论的来源。
