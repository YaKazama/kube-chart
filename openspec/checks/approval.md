# 批准检查

- [ ] 初次检查时 draft frontmatter `status` 为 `planned`；确认冻结时为 `approval-pending`，且 `draft-content-sha256` 与最近一次 plan 一致。
- [ ] frontmatter 的 change-id、capability、artifact-type、template-name 和 target-path 完整且没有未确认修改。
- [ ] draft 没有 `[待补充]` 或 `[AI 推断]`，目标、非目标和验收可判定。
- [ ] 没有未决设计选择或验收缺口。
- [ ] draft、spec、可选 design 与 tasks 范围一致，无会改变行为的未决问题。
- [ ] 用户输入、项目规则和代码事实来源清楚；没有未确认推断形成 MUST 或 SHALL。
- [ ] 每个 Requirement 都有可复现 Scenario，全部验收项均被覆盖。
- [ ] 依赖占位未成为本 change 的分析或实施授权。
- [ ] 首次检查只进入 `approval-pending`；仅用户显式 `confirm` 后冻结。
- [ ] 批准记录包含 `draft-content-sha256`、`plan/spec.md` 和存在的 `plan/design.md` 的 SHA-256。
