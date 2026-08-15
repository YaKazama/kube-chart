# patterns

本目录保存当前有效且可复用的文档资产，是通用契约的唯一来源。

```text
patterns/
  rules/          核心设计原则、全局实现、边界、架构、核心能力、values 与正式 SDD 规则
  templates/      SDD 过程与正式文档模板
  checklists/     开发与交付检查清单
  workflows/      文档生命周期、开发模式与正式化流程
  examples/       已验证的 values、渲染 YAML 与调用样例
  references/     Kubernetes、Helm 等权威资料索引
```

- 规则文件定义“必须如何做”。
- 检查清单定义“如何确认已做到”，不重复规则正文。
- 示例仅提供已验证参考，不覆盖规则。
- 正式 SDD 可引用本目录，不能复制通用规则正文。
