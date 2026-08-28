# `/opsx-spec`

## 职责

从完整、无阻塞的 `draft.md` 一次性生成当前 change 的 `spec.md`、`design.md` 和 `tasks.md`，完成行为、设计与任务闭包检查后锁定执行契约；不生成代码。

```text
/opsx-spec <change-id>
```

## 门禁

- `draft.md` 不存在时中断并警告：必须先执行 `/opsx-draft <change-id>`。
- spec、design 或 tasks 任一文件已存在时停止，不覆盖、刷新、补齐或从 draft 重新推理。
- draft 中存在影响行为、验收、技术目标、依赖、代码边界或任务的未确认 `[AI 推断]`、歧义或缺失事实时停止。
- 候选三制品未通过 [`../workflow.md`](../workflow.md) 的三类闭包时停止，不创建部分制品。

## 上下文

读取当前 `draft.md`、[`../rules/change-documents.md`](../rules/change-documents.md)、[`../rules/specifications.md`](../rules/specifications.md)、[`../rules/designs.md`](../rules/designs.md) 和 [`../rules/tasks.md`](../rules/tasks.md)。

只按 draft 明确涉及的产物读取精确当前能力规格和适用工程规则；为确认真实文件路径、当前符号、技术目标或直接依赖，可以读取已授权目录的文件清单和精确目标代码。依赖解析只到当前能力的直接依赖为止，不递归读取依赖自身的调用链，不读取其他 change、归档或无关实现。

正式代码和参考资料只提供当前实现事实、版本事实和设计约束，不得反向生成 Requirement、默认值、失败边界或验收。

## 输出

- 先在内存中生成三份候选制品并交叉检查；全部通过后在 change 根目录一次性创建 `spec.md`、`design.md` 和 `tasks.md`。
- `spec.md` frontmatter 写入 `status: spec` 和当前 UTC RFC 3339 `updated_at`，正文只记录可观察行为、失败边界和非目标。
- `design.md` 记录技术目标、设计决策、依赖契约、精确代码边界和验证设计，不复制 Requirement 正文。
- `tasks.md` 记录映射到 design 的实施与验证 checkbox，不增加行为或设计选择。
- 不修改 draft、正式代码、用户文档或既有稳定能力规格。
- 会话报告行为契约、关键设计、read/write 代码边界、任务数量和三类闭包结论。
