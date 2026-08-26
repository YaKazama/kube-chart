# `/sdd-revise`

## 职责

只使现有批准失效并受控更新用户 draft，不重新生成 plan，不修改正式代码。

## 读取

- `AGENTS.md`、`openspec/workflow.md`、本文件
- `draft.md`、`records/approval.md`
- [`../rules/change-documents.md`](../rules/change-documents.md)
- 用户本次明确提供的修订内容

## 输出

- 按变更文档规则将本轮修订写入 `draft.md`，并将 `status` 改为 `draft`，使既有批准立即失效。
- 既有 approval、plan 和 verification 保留为待刷新或历史 AI 产物，不改写验证证据。
- 报告受影响的 draft 条目并提示执行 `/sdd-plan`。

既有 plan 不能继续作为实施依据。仍有歧义而无法写回时，按变更文档规则输出修订建议。
