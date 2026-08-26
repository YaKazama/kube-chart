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
- 每个 Requirement 必须引用至少一个已确认 draft 条目。项目规则和代码事实只能作为补充依据，不得独立生成 MUST 或 SHALL；静态代码事实不得表述为已验证行为。
- 标记 `[AI 推断]` 的 draft 条目不得进入 Requirement；用户确认并移除标记后才能派生规范性行为。
- 未实现子模板只描述当前父模板可观察的调用和最小返回契约，不替子模板虚构行为。

## 当前规格

- 只保留已批准、已应用、经真实项目命令验证并完成人工 Review 的行为；`/sdd-verify` 不可跳过。
- 每个能力目录只保存一个 `spec.md`，包含 `## Purpose` 和 `## Requirements`。
- 合并时移除草稿状态、来源提示、任务、临时假设和被否决方案。
- `/sdd-rewrite` 只能整理结构和表达，不得改变 Requirement、Scenario、默认值或边界。
