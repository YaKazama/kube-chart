# `/sdd-plan`

## 职责

接受 `draft` 或 `planned`。从 `draft.md` 生成包含技术目标的批准前草稿；不修改正式代码，不批准，不创建阶段记录。

## 读取

- 当前 change 的 `draft.md` 和既有 `plan/`
- 为解析能力与目标产物所需的当前规格、候选目标代码和目录结构
- 仅为检查目标冲突读取其他活动 change 的 draft frontmatter 和 `plan/spec.md` 的 `## 技术目标`，不读取其余正文、plan 或 records
- [`../rules/change-documents.md`](../rules/change-documents.md)、[`../rules/specifications.md`](../rules/specifications.md)
- 仅按变更范围追加读取 `AGENTS.md` 路由的实现规则
- 仅在当前规格、适用规则、候选目标代码和目录结构仍不足以确认影响契约的目标事实时，读取 [`../references/README.md`](../references/README.md) 作为路由，并只读取其中与未决事实直接相关的本地参考资料；本地上下文仍不足时，才按需查阅精确的外部官方资料

不得读取其他 change 的正文、plan、records、归档记录、verification 或无关能力。

## 输出

- 先按变更文档规则写回本轮确认的意图；`planned` 的 draft 发生变化时先退回 `draft`。已经批准时停止并要求执行 `/sdd-revise`。
- 按变更文档规则解析并写入 `plan/spec.md` 的 `## 技术目标`；用户已写明的目标优先，但仍需按适用工程规则校验。目标不唯一、非法或冲突不阻塞 plan 草稿生成，但必须记录候选项和待确认问题。
- 按变更文档规则补齐 plan：从目标 API 或产物结构、当前规格、适用规则、相关参考资料和真实现有能力推导当前目标必须遵守的工程细节，不要求用户在 `draft.md` 中复述通用规则，也不得借此扩张用户需求。
- `plan/spec.md`：记录技术目标、可观察行为、失败边界与 Scenario 草稿。
- `plan/design.md`：记录适用规则在当前目标上的具体落实，包括重要技术决策、直接依赖、调用位置、传入上下文、处理顺序、类型与隔离边界；存在这些内容时必须创建，不需要时删除旧文件。
- `plan/tasks.md`：使用 Markdown 任务列表，只列 `/sdd-apply` 的实施顺序，不承载新的需求、设计约束或验证步骤；完成状态由 `/sdd-apply` 更新。
- 写入完成后逐条复核本轮已读取的适用规范性规则；不得用“遵循项目规则”代替具体落实。任何适用规则遗漏、规则冲突、技术目标、用户意图、设计选择或验收问题仍待解决时保持 `draft`；全部落实且无待确认项后才进入 `planned`。
- 会话中只报告技术目标、草稿产物和待确认问题。

再次执行本命令时覆盖刷新 AI 草稿，不叠加历史说明。需求派生遵循 [`../rules/change-documents.md`](../rules/change-documents.md)。
