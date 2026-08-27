# 规格规则

## 规范来源

- `openspec/specs/<能力>/spec.md` 是已合并的当前行为契约。
- `openspec/changes/<change-id>/plan/spec.md` 是变更契约；批准前为草稿，批准后由 approval 摘要冻结。
- 当前规格与冻结变更规格共同定义目标行为；实现不一致时修实现，需求有误时执行 `/sdd-revise`。
- `openspec/changes/archive/` 只保存历史，不参与当前契约。

## 变更规格

- 新行为放入 `## ADDED Requirements`。
- 修改行为放入 `## MODIFIED Requirements`，包含完整新 Requirement 和全部 Scenario。
- 删除行为放入 `## REMOVED Requirements`，记录 `Reason` 和 `Migration`。
- 只改名使用 `## RENAMED Requirements`，以 `FROM:` 和 `TO:` 表达。
- 新能力包含 `## Purpose`；修改已有能力不重复 Purpose。
- Requirement 使用 MUST 或 SHALL，且至少包含一个 WHEN/THEN Scenario。
- 只描述可观察的渲染或失败行为，不写实现步骤、任务或方案比较。
- Requirement 的来源遵循 [`openspec/rules/change-documents.md`](change-documents.md) 的 draft 保护规则；项目规则和代码事实不得独立扩张用户需求。该限制不允许忽略适用工程规则：规则对既定需求形成的可观察行为或失败边界必须写入 Requirement，纯实现约束按变更文档规则写入 design 或 tasks。
- 未实现子模板只描述当前父模板可观察的调用和最小返回契约，不替子模板虚构行为。

## 当前规格

- 只保留已批准、正式实现已就绪、经真实项目命令验证并完成人工 Review 的行为；`/sdd-verify` 不可跳过，但可在批准有效时独立执行。
- 每个能力目录只保存一个 `spec.md`，包含 `## Purpose` 和 `## Requirements`。
- 合并时移除草稿状态、任务、临时假设和被否决方案。
- 整理当前规格的结构和表达按普通编辑处理，不得改变 Requirement、Scenario、默认值或边界；发现与实现或验证证据不一致时停止。
