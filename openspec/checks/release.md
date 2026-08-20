# 发布检查

- [ ] Chart 类型、Kubernetes 与 Helm 版本基线满足声明要求。
- [ ] 所有发布相关变更均已批准、验证、Review 并归档。
- [ ] 当前规格、实现、样例和用户可见行为一致。
- [ ] 通用规则位于 [`openspec/rules/`](../rules/)，能力专属行为位于当前规格，无重复规范来源。
- [ ] 核心样例可渲染，关键异常输入按规格失败。
- [ ] 无敏感信息硬编码，安全默认值符合项目规则。
- [ ] 发布涉及 values 时，[`values.yaml`](../../values.yaml)、Schema、[`docs/`](../../docs/) 和当前规格一致。
- [ ] [`openspec/changes/`](../changes/) 中不存在会影响本次发布但尚未归档的变更。
