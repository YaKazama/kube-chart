# `/sdd-plan`

## 职责

接受 `draft` 或 `planned`。从 `draft.md` 生成包含技术目标的批准前草稿；不修改正式代码，不批准，不创建阶段记录。

## 读取

- `AGENTS.md`、`openspec/workflow.md`、本文件
- 当前 change 的 `draft.md` 和既有 `plan/`
- 为解析能力与目标产物所需的当前规格、候选目标代码和目录结构
- 仅为检查目标冲突读取其他活动 change 的 draft frontmatter 和 `plan/spec.md` 的 `## 技术目标`，不读取其余正文、plan 或 records
- [`../rules/change-documents.md`](../rules/change-documents.md)、[`../rules/specifications.md`](../rules/specifications.md)
- 仅按变更范围追加读取 `AGENTS.md` 路由的实现规则

不得读取其他 change 的正文、plan、records、归档记录、verification 或无关能力。

## 输出

- 先按变更文档规则写回本轮确认的意图；`planned` 的 draft 发生变化时先退回 `draft`。已经批准时停止并要求执行 `/sdd-revise`。
- 按变更文档规则解析并写入 `plan/spec.md` 的 `## 技术目标`；用户已写明的目标优先，但仍需按适用工程规则校验。目标不唯一、非法或冲突不阻塞 plan 草稿生成，但必须记录候选项和待确认问题。
- `plan/spec.md`：记录技术目标、可观察行为与 Scenario 草稿。
- `plan/design.md`：仅在存在重要技术决策、跨层上下文或需取舍时创建；不需要时删除旧文件。
- `plan/tasks.md`：只列实施顺序和必要门禁。
- 任何技术目标、用户意图、设计选择或验收问题仍待确认时保持 `draft`；全部解决后进入 `planned`。
- 会话中只报告技术目标、草稿产物和待确认问题。

再次执行本命令时覆盖刷新 AI 草稿，不叠加历史说明。需求派生遵循 [`../rules/change-documents.md`](../rules/change-documents.md)。
