# `/sdd-revise`

## 职责

只使现有批准失效并受控更新用户 draft，不重新生成 plan，不修改正式代码。

## 读取

- `AGENTS.md`、`openspec/workflow.md`、本文件
- `draft.md`、`records/approval.md`
- 用户本次明确提供的修订内容

## 输出

- 将用户确认的修订合并进 `draft.md`；AI 草拟但未确认的内容逐项标记 `[AI 推断]`。
- 将批准记录和既有验证记录标记为失效，draft frontmatter `status` 改为 `revision`。
- 报告受影响的 draft 编号并提示执行 `/sdd-plan`。

既有 plan 保留为待刷新 AI 产物，不能继续作为实施依据。仍有歧义而无法写回的内容必须按保护规则输出明确修订建议。
