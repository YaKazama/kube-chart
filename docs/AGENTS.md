# docs SDD 工作流入口

继承工作区根 `AGENTS.md` 的适配基线、角色、目标和工程规则。本文件只补充 docs 域的工作流与命令路由。

## 文档域目标

- 当前以 `spec-code-plan` 收敛公共约束；公共契约稳定后以 `spec-plan-code` 开发后续模板。
- 按单模板或单功能闭环；人工 Review 通过后再开始下一项。

## 默认规则入口

任何涉及模板、正式 SDD、样例或文档的修改，必须先读取：

- `docs/patterns/rules/const-general.md`
- `docs/patterns/rules/design-principles.md`
- `docs/patterns/rules/const-boundary.md`
- `docs/patterns/rules/core-capabilities.md`
- `docs/patterns/workflows/document-lifecycle.md`
- `docs/patterns/workflows/development-mode.md`

按修改范围追加读取：

- 修改 values、Schema 或最终用户配置：`docs/patterns/rules/values-rules.md`
- 修改模板分层、上下文或依赖：`docs/patterns/rules/template-architecture.md`
- 更新正式 SDD：`docs/patterns/rules/spec-rules.md`
- 处理 Helm、YAML 或 Kubernetes 版本差异：`docs/patterns/rules/const-boundary.md`

## 命令执行

- Helm CLI 固定使用 `/opt/homebrew/bin/helm`，禁止通过 `PATH`、`which`、`command -v`、`find` 或全盘遍历定位可执行文件。
- 所有 Helm 检查、渲染与调试均直接调用该绝对路径。

## 触发命令

| 命令 | 目的与产物 | 必须读取 |
|---|---|---|
| `/sdd-new` | 初始化 `changes/<change-id>/spec.md`，记录需求目标、范围、输入、期望行为与验收约束；不产出技术方案。 | `patterns/templates/spec-template.md`、`patterns/workflows/sdd-workflow.md` |
| `/sdd-design-plan` | 以已明确的 `spec.md` 为输入，在 `design-plan.md` 先确定设计、规则归属与决策，再确定影响范围、实施顺序与验证策略。 | `patterns/templates/design-plan-template.md`、当前正式 SDD、适用规则、`patterns/references/`、`patterns/workflows/sdd-workflow.md` |
| `/sdd-design-plan --split` | 高风险时将同一工作流拆为 `design.md` 与 `plan.md`；前者的设计决策经确认后，后者才能排定实施与验证。 | `patterns/templates/design-template.md`、`patterns/templates/plan-template.md`、当前正式 SDD、适用规则、`patterns/references/`、`patterns/workflows/sdd-workflow.md` |
| `/sdd-tasks` | 将已确认的实施计划细化为文件级、可验证、可勾选的原子任务；不重新讨论或改变设计决策。 | `patterns/templates/tasks-template.md` |
| `/sdd-apply` | 按 `tasks.md` 实现模板、必要示例与验证资产，并将命令、输入和结果记录到 `evidence.md`。 | 当前 changes 文档、当前正式 SDD、`patterns/templates/evidence-template.md`、`patterns/checklists/dev.checklist` |
| `/sdd-spec` | 在代码、验证证据与 Review 完成后，固化正式 SDD、沉淀通用规则并归档过程材料。 | `patterns/templates/sdd-template.md`、`patterns/workflows/formalization.md`、`patterns/checklists/deployment.checklist` |
| `/sdd-guide` | 在用户可见行为稳定后，依据正式 SDD 与已验证样例生成或更新最终用户文档。 | 正式 SDD、已验证样例、`patterns/rules/values-rules.md`、`patterns/readme-rules.md` |
| `/sdd-rewrite` | 按统一结构重写既有正式 SDD，不改变已确认的技术契约。 | `patterns/specs-ai-rewrite.md` |
| `/ck-dev` | 对当前开发变更执行开发检查。 | `patterns/checklists/dev.checklist` |
| `/ck-deploy` | 对可发布产物执行部署与发布检查。 | `patterns/checklists/deployment.checklist` |
| `/helm-lint` | 对当前 Chart 和本次变更的已验证样例执行 Helm 静态检查。 | 当前 Chart 与本次变更的已验证样例 |

## 命令调用顺序与适用模式

`触发命令`表只说明每个命令的目的、产物与必读文档，不规定调用顺序与适用模式。`spec-code-plan` / `spec-plan-code` 两种模式下的命令序列、阶段映射、模式过渡与局部回退规则，见 `patterns/workflows/command-sequence.md`。

## `/sdd-design-plan` 合并与拆分

- `/sdd-design-plan` 是默认入口；`design-plan.md` 不是把设计与计划混为同一语义，而是在同一文档中按“设计决策在前、实施计划在后”的顺序记录两个相邻阶段。
- 设计回答“为什么这样做、输入和边界是什么、采用哪些公共规则”；计划回答“改哪些位置、按什么顺序实施、如何验证”。`/sdd-tasks` 只把已确认计划拆成原子任务，不承载设计决策。
- 单模板或单功能闭环默认合并，减少设计与计划之间的同步成本；需求信息不足时先补充 `spec.md`，不得由设计计划替代需求澄清。
- 设计结论需要独立 Review 或冻结后才能安排实施时，使用 `/sdd-design-plan --split`。公共能力变更、跨多个模板层级联动、Helm 或 Kubernetes 兼容性存在不确定性、需比较备选方案或分阶段协作，均应优先拆分。
- 拆分后保持单向依赖：`plan.md` 仅引用已确认的 `design.md` 决策，`tasks.md` 仅引用已确认的计划；过程文档完成后归档，正式 SDD 不依赖过程材料。
