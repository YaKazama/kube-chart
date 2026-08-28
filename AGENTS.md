# kube-chart AI 开发入口

## 项目基线

- Kubernetes API `>= v1.36.0`；Helm `>= 4.0.0`，推荐 `4.2.2`。
- Chart：library Chart，[`Chart.yaml`](Chart.yaml) 必须声明 `kubeVersion: ">=1.36.0"`。
- 仅使用 Helm 内置函数、Go Template、Sprig 与 Helm 特有函数；严禁臆造。
- 角色：资深 DevOps、云原生架构师

## 工作原则

- 保持标准化、低幻觉、类型稳定和代码 DRY，并遵循 Helm 与 Kubernetes 最佳实践。
- 使用中文；数字、英文与中文混排保留必要空格；文件引用使用工作区相对路径。
- 变更文档的入口、归属和推断保护统一遵循 [`openspec/rules/change-documents.md`](openspec/rules/change-documents.md)，不得在其他层复述为第二套规则。
- 文件末尾有且仅有一个换行符。

## 上下文访问

- 文件路径必须来自已读文档的明确链接、本文映射或已授权目录的文件清单。AI 会话命令名与文件名属于不同命名空间；不得通过增删或替换命令前后缀猜测文件名。缺少映射时，先查询真实文件列表，再读取已确认的路径。
- 命令只读取完成当前职责所需的当前文件；事实一经用户输入、当前规格或适用规则确认即停止扩张上下文。正式代码只说明实现现状，不能反向生成需求。
- 搜索只用于确认真实文件名或在已授权文件中定位标识符；不得借此通读调用方、相邻能力、其他 change 或归档内容。
- 本地参考统一从 [`openspec/references/README.md`](openspec/references/README.md) 路由；版本特定事实必须先在其映射的本地镜像或快照中定位精确片段。本地内容足以确认事实时禁止发起 URL 请求，不得仅为刷新、复核或获取更完整上下文访问在线资源。
- 仅当缺少会改变契约的版本特定事实，且本地参考缺失、不可读或精确片段仍不足时，才查询对应的精确官方资源；已由用户输入、当前规格、适用规则或本地参考确认的事实不得重复查询。参考资料不得扩张需求。

## 命令入口

本项目采用精简 OPSX 动作模型，以 `draft.md` 和 `spec.md` 两个制品驱动实施。状态只表示最近完成的稳定动作；`/opsx-fix` 可以重复执行，契约确需同步时由用户决定是否执行 `/opsx-spec-rewrite`。

```text
/opsx-draft
  → /opsx-spec
  → /opsx-code
  ↔ /opsx-fix
      └─ 用户确认回写时 → /opsx-spec-rewrite
  → /opsx-review

/docs-usage

/ck-deploy
```

| 命令 | 唯一定义文件 | 唯一主要职责 |
|---|---|---|
| `/opsx-draft` | [`openspec/commands/draft.md`](openspec/commands/draft.md) | 新建或继续只表达意图的轻量 `draft.md`。 |
| `/opsx-spec` | [`openspec/commands/spec.md`](openspec/commands/spec.md) | 从 draft 生成带精确代码锚点的 `spec.md`。 |
| `/opsx-code` | [`openspec/commands/code.md`](openspec/commands/code.md) | 按已锁定规格和锚点生成代码。 |
| `/opsx-fix` | [`openspec/commands/fix.md`](openspec/commands/fix.md) | 在 `code` 状态下局部调整代码，并给出回写判定与建议。 |
| `/opsx-spec-rewrite` | [`openspec/commands/spec-rewrite.md`](openspec/commands/spec-rewrite.md) | 按用户在当前命令中确认的内容回写规格。 |
| `/opsx-review` | [`openspec/commands/review.md`](openspec/commands/review.md) | 轻量核对当前变更、总结并归档。 |
| `/docs-usage` | [`openspec/commands/docs-usage.md`](openspec/commands/docs-usage.md) | 独立生成 `docs/` 最终用户文档并更新根 `README.md`。 |
| `/ck-deploy` | [`openspec/commands/ck-deploy.md`](openspec/commands/ck-deploy.md) | 对整个 Chart 执行发布检查。 |

收到任一命令时，先读取精简工作流 [`openspec/workflow.md`](openspec/workflow.md)，再读取上表映射的唯一命令文件，并在其上下文边界内完成职责。命令是 AI 会话触发命令，不是 shell 命令。

## 规则路由

仅按当前动作和修改范围读取：

- 用户入口保护、frontmatter、代码锚点与归档：[`openspec/rules/change-documents.md`](openspec/rules/change-documents.md)
- 规格语法或受控回写：[`openspec/rules/specifications.md`](openspec/rules/specifications.md)
- Helm 模板：[`openspec/rules/helm-templates.md`](openspec/rules/helm-templates.md)
- 核心命名模板调用：[`openspec/rules/core-capabilities.md`](openspec/rules/core-capabilities.md)
- values、Schema 或用户配置：[`openspec/rules/values-schema.md`](openspec/rules/values-schema.md)
- README、`docs/` 或样例：[`openspec/rules/documentation.md`](openspec/rules/documentation.md)
