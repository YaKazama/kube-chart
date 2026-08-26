# 开发检查

- [ ] 已读取目标代码、当前规格、活动变更、[`openspec/workflow.md`](../workflow.md) 和适用规则。
- [ ] proposal、变更规格、design 和 tasks 范围一致，无会改变行为的未决问题。
- [ ] 实际创建或修改的 `define` 与 tpl 文件均存在于已批准 proposal 的目标映射中。
- [ ] `approval.md` 状态为“已批准”，proposal 与全部变更规格的 SHA-256 摘要匹配。
- [ ] 代码实现符合已批准 Requirement 和 Scenario；没有按现有代码反向改写规格。
- [ ] 必填、类型、默认行为、零值和互斥关系符合规格。
- [ ] 多层取值、字段渲染和集合解析符合 [`openspec/rules/core-capabilities.md`](../rules/core-capabilities.md)，上下文隔离符合 [`openspec/rules/helm-templates.md`](../rules/helm-templates.md)。
- [ ] 命名、分层、字段顺序和输出结构符合 Kubernetes API 与项目规则。
- [ ] OpenSpec 严格校验通过。
- [ ] 最小有效、较完整有效和关键失败输入已验证。
- [ ] `/opt/homebrew/bin/helm lint` 通过，渲染输出为合法 YAML。
- [ ] `verification.md` 记录环境、输入、命令、预期和实际结果；`/tmp/` 临时文件已清理。
