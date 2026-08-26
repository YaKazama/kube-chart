# Verify 执行提示

本文件只提示 `/sdd-verify` 必须实际执行和记录的场景，本身不是验证证据。

- [ ] 当前阶段为 `applied` 或 `verified`，批准有效且冻结摘要匹配。
- [ ] 以冻结 spec 和 draft 验收为预期，以当前正式实现为实际。
- [ ] 所有结论都来自仓库真实存在且在本轮实际执行的项目命令；checklist、静态推断、预期描述和旧结果未被当作证据。
- [ ] Helm lint、最小有效、较完整有效、关键失败输入和受影响回归均有本轮真实命令结果。
- [ ] 临时同名 `define` 只作为 `/tmp/` 中的 fixture；验证记录明确其内容、隔离范围和限制，完成后已清理，且未声称真实子模板集成。
- [ ] `records/verification.md` 使用人类可读 Markdown，包含环境、完整命令、输入、退出码、预期、实际摘要和逐场景结论，不使用 YAML 保存证据。
- [ ] 验证阶段未修改正式代码、draft 正文、plan 或当前规格；只写入 `records/verification.md` 并按结果更新 frontmatter 状态。
- [ ] 全部通过后进入 `verified`；任一失败、未执行或偏差时保持 `applied`。
