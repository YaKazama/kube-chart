# 规格与文档规则

## 规范来源

- [`openspec/workflow.md`](../workflow.md) 是流程与快捷命令的唯一来源。
- [`openspec/specs/`](../specs/) 是当前行为契约；只能由通过门禁的 `/sdd-spec` 创建或更新。
- [`openspec/changes/<change-id>/specs/`](../changes/) 是变更规格；批准前为草案，批准后受 `artifacts/approval.md` 冻结。
- [`openspec/rules/`](./) 是工程实现规则，不得在能力规格中复制正文。
- [`openspec/changes/archive/`](../changes/archive/) 只保存历史，不参与当前实现的规范性引用。

批准后，当前规格和变更规格共同定义目标行为。代码不一致时修复代码；只有用户明确执行 `/sdd-revise` 后才能修改被冻结的行为契约。

## 当前规格

- 当前规格只描述已实现、已验证、已 Review 的可观察行为。
- 每个能力目录只保存一个 `spec.md`，包含 `## Purpose` 和 `## Requirements`。
- 每个 `### Requirement:` 至少包含一个 `#### Scenario:`。
- Requirement 使用 MUST 或 SHALL；Scenario 使用 WHEN/THEN 描述可复现输入与结果。
- 不写任务、命令记录、临时假设、被否决方案或逐行实现步骤。
- `/sdd-rewrite` 只能整理结构和表达，必须保留仍有效的 Requirement、Scenario、默认值、边界与参考资料；发现与实现或实际检查结果不一致时停止。

## 变更规格

- `proposal.md` 是唯一用户输入源，正文只使用“目标、需求、约束”三节；用户可直接修改，也可在会话中提供内容由 AI 写入。
- change 根目录只保留 `proposal.md`、`specs/` 和 `artifacts/`；design、tasks、approval 和 verification 全部位于 `artifacts/`，不得与用户入口并列。
- proposal 顶部摘要使用无序列表显示状态、change-id、主要能力，以及按目标顺序成对出现的命名模板和工作区相对存放路径；“目标”节继续保存带稳定编号的完整映射。
- “约束”只原样保存用户明确指定的本次变更特殊限制，允许为空；AI 不得用项目基线、通用规则或推导结论填充该节。
- AI 必须自行读取 `AGENTS.md`、适用规则、当前规格、目标代码和官方资料，不在 proposal 创建“参考”节；用户主动提供的特殊依据写入需求或约束。
- 子模板占位只在 proposal “目标”中维护完整 checkbox 行和稳定编号。变更规格、design 和 tasks 只引用编号，不复制占位表。
- 变更规格是 AI 同步产物，文件顶部必须指向 proposal 的“需求”作为修改入口。父能力规格可以描述真实的委托和返回校验，但不得替未知子模板编写假的 Requirement。
- AI 从项目上下文取得的版本、分层、类型、安全、兼容性和验证约束写入适用的 spec、design 或 tasks，不反向污染 proposal。
- `/sdd-new`、批准前探索和 `/sdd-apply` 不创建 `artifacts/verification.md`。只有正式目标全部实现且真实依赖可用后，`/sdd-verify` 才根据实际检查创建该文件；不得记录草案推断、临时候选代码或测试替身结果。
- 顶层行为未知时在 proposal “需求”中留下简短、具体的 `[待补充]` 行；只有子模板缺失时继续编写父能力真实 Requirement 和 Scenario。
- 新行为放入 `## ADDED Requirements`。
- 修改行为放入 `## MODIFIED Requirements`，必须复制并给出完整的新 Requirement 和全部 Scenario。
- 删除行为放入 `## REMOVED Requirements`，记录 `Reason` 和 `Migration`。
- 只改名使用 `## RENAMED Requirements`，以 `FROM:` 和 `TO:` 表达。
- 新能力包含 `## Purpose`；修改已有能力不重复 Purpose。
- 未验证的静态推断只能作为草案或探索结论，不能进入当前规格。

## 批准与修订

- `/sdd-approve` 冻结 proposal 和全部变更规格的 SHA-256 摘要；AI 不得自行批准。
- `/sdd-apply`、`/sdd-verify` 和 `/sdd-spec` 都必须重新计算并核对摘要。
- 新条件、新需求、外部限制或规格缺陷必须通过 `/sdd-revise` 记录原因和影响，并将状态改为“需重新批准”。
- design 和 tasks 可以在行为不变时细化；一旦影响 Requirement 或 Scenario，同样进入修订流程。

## README 与用户文档

- 根 [`README.md`](../../README.md) 至少包含安装或导入方式、核心原则、可用模板清单、最小示例、常见问题和迁移说明。
- [`docs/`](../../docs/) 只描述稳定且已验证的用户可见行为，不记录 AI 命令、过程任务或未确认假设。
- `/sdd-spec` 在合并当前规格后同步受影响的用户文档；文档校验失败时不得归档 change。
- 文件引用使用工作区相对路径，链接目标必须存在。
