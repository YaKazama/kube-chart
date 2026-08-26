# `/sdd-plan`

## 职责

只从当前 `draft.md` 生成批准前草稿，不修改正式代码，不批准，不创建阶段记录。

## 读取

- `AGENTS.md`、`openspec/workflow.md`、本文件
- 当前 change 的 `draft.md` 和既有 `plan/`
- 目标能力的当前规格与目标代码
- [`../rules/change-documents.md`](../rules/change-documents.md)、[`../rules/specifications.md`](../rules/specifications.md)
- 仅按变更范围追加读取 `AGENTS.md` 路由的实现规则
- [`../checks/plan.md`](../checks/plan.md)

不得读取其他 change、归档记录、verification 或无关能力；只有发现明确冲突时才按需读取对应活动 change。

## 输出

- 先把本轮用户已确认的意图修改写回 draft；若当前状态不允许修改，则停止 plan 并输出明确修订建议。
- `plan/spec.md`：记录 `draft-content-sha256`、可观察行为与 Scenario 草稿。
- `plan/design.md`：仅在存在重要技术决策、跨层上下文或需 Review 的取舍时创建；不需要时删除旧文件。
- `plan/tasks.md`：只列实施顺序和必要门禁。
- draft frontmatter：存在 `[AI 推断]`、`[待补充]`、未决设计选择或验收缺口时保持 `draft`；没有阻塞项时更新为 `planned`。
- 会话中输出简短检查结果和必须由用户确认的问题；新推断必须作为 `[AI 推断]` 修订建议，不得直接形成 MUST 或 SHALL。

有阻塞项时仍可生成轻量草稿并输出修订建议，但不得进入 `planned`。再次执行本命令时覆盖刷新 AI 草稿，不叠加历史说明。项目规则、代码与当前规格只用于校验和发现冲突，不得补全 draft 未表达的需求。
