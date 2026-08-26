# `/sdd-plan`

## 职责

接受 `draft` 或 `planned`。先解析并校验当前 change 的技术目标，再从 `draft.md` 生成批准前草稿；不修改正式代码，不批准，不创建阶段记录。

## 读取

- `AGENTS.md`、`openspec/workflow.md`、本文件
- 当前 change 的 `draft.md` 和既有 `plan/`
- 为解析 capability、artifact-type、template-name 和 target-path 所需的当前规格、候选目标代码和目录结构
- 仅为检查技术目标冲突读取其他活动 change 的 draft frontmatter，不读取其正文、plan 或 records
- [`../rules/change-documents.md`](../rules/change-documents.md)、[`../rules/specifications.md`](../rules/specifications.md)
- 仅按变更范围追加读取 `AGENTS.md` 路由的实现规则
- [`../checks/plan.md`](../checks/plan.md)

不得读取其他 change 的正文、plan、records、归档记录、verification 或无关能力。

## 输出

- 先把本轮用户已确认的意图修改写回 draft；`planned` 的 draft 发生变化时先退回 `draft`。若已经批准，则停止 plan 并输出明确修订建议，要求执行 `/sdd-revise`。
- 在创建或刷新任何 plan 文件前执行技术目标预检：根据用户意图、当前规格、候选代码和适用工程规则解析并校验 capability、artifact-type、template-name 和 target-path，同时检查命名、路径、define 重名和活动 change 冲突。
- 技术目标唯一且合法时，将其写入 AI 维护的 draft frontmatter 并向用户报告；技术目标无法唯一确定、非法或存在冲突时保持 `draft`，报告候选项、证据和待确认问题，不创建或刷新 plan。
- `plan/spec.md`：记录 `draft-content-sha256`、可观察行为与 Scenario 草稿。
- `plan/design.md`：仅在存在重要技术决策、跨层上下文或需 Review 的取舍时创建；不需要时删除旧文件。
- `plan/tasks.md`：只列实施顺序和必要门禁。
- draft frontmatter：存在 `[AI 推断]`、`[待补充]`、未决设计选择或验收缺口时保持 `draft`；没有阻塞项时更新为 `planned`。
- 会话中输出简短检查结果和必须由用户确认的问题；新推断必须作为 `[AI 推断]` 修订建议，不得直接形成 MUST 或 SHALL。

通过技术目标预检后，意图内容仍有阻塞项时可以生成轻量草稿并输出修订建议，但不得进入 `planned`。再次执行本命令时覆盖刷新 AI 草稿，不叠加历史说明。项目规则、代码与当前规格只用于解析技术目标、校验和发现冲突，不得补全 draft 未表达的需求。
