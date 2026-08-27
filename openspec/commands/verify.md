# `/sdd-verify`

## 职责

独立对当前正式实现执行完整的真实验证，生成或覆盖人类可读记录并更新状态；不生成或修复代码，不更新契约或用户文档。

```text
/sdd-verify <change-id>
```

## 上下文

读取 `draft.md` frontmatter、`plan/spec.md`、确切目标实现、直接依赖当前规格、[`../rules/change-documents.md`](../rules/change-documents.md)、适用验证规则和仓库已有的真实命令入口。不读取非目标实现，不复用既有验证结果；失败只记录证据，不在本命令中诊断或修复。

执行前必须确认状态为 `planned`、`applied` 或 `verified`。本命令不读取或依赖 `/sdd-apply` 的会话输出、摘要或命令结果；既有验证记录也不得替代本轮执行。

## 输出

- 只执行仓库真实存在的项目命令；模板验证矩阵遵循适用工程规则，不得引用旧结果代替本轮执行。
- 按变更文档规则创建或覆盖 `records/verification.md`，记录契约、正式实现与直接依赖的 SHA-256，以及真实命令和结论。
- 全部 Scenario 通过后将状态更新为 `verified`。存在失败、未执行场景或契约偏差时记录失败结论；原 `verified` 重置为 `applied`，原 `planned` 或 `applied` 保持不变。

隔离验证父模板时，可在 `/tmp/` 测试 Chart 提供同名最小 `define` fixture，但须在记录中写明 fixture、隔离范围和未覆盖限制，不得宣称真实子模板集成。契约要求真实集成时，fixture 结果不能判为通过；完成后清理。
