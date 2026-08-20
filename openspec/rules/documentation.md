# 规格与文档规则

## 规范来源

- [`openspec/workflow.md`](../workflow.md) 是流程与快捷命令的唯一来源。
- [`openspec/specs/`](../specs/) 是当前行为契约；只能由通过门禁的 `/sdd-spec` 创建或更新。
- [`openspec/changes/<change-id>/specs/`](../changes/) 是变更规格；批准前为草案，批准后受 `approval.md` 冻结。
- [`openspec/rules/`](./) 是工程实现规则，不得在能力规格中复制正文。
- [`openspec/changes/archive/`](../changes/archive/) 只保存历史，不参与当前实现的规范性引用。

批准后，当前规格和变更规格共同定义目标行为。代码不一致时修复代码；只有用户明确执行 `/sdd-revise` 后才能修改被冻结的行为契约。

## 当前规格

- 当前规格只描述已实现、已验证、已 Review 的可观察行为。
- 每个能力目录只保存一个 `spec.md`，包含 `## Purpose` 和 `## Requirements`。
- 每个 `### Requirement:` 至少包含一个 `#### Scenario:`。
- Requirement 使用 MUST 或 SHALL；Scenario 使用 WHEN/THEN 描述可复现输入与结果。
- 不写任务、命令记录、临时假设、被否决方案或逐行实现步骤。
- `/sdd-rewrite` 只能整理结构和表达，必须保留仍有效的 Requirement、Scenario、默认值、边界与参考资料；发现与实现或验证证据不一致时停止。

## 变更规格

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
