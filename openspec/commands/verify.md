# `/sdd-verify`

## 职责

独立对当前正式实现执行完整的真实验证，生成或覆盖统一的人类可读记录并更新状态；不生成或修复代码，不更新任务、规格或用户文档。

## 读取

- `draft.md` frontmatter、`records/approval.md`、`plan/spec.md`
- 按批准记录检查 `plan/design.md` 是否存在并计算普通 SHA-256；只核对摘要，不读取正文
- 正式实现、直接依赖的当前规格
- [`../rules/change-documents.md`](../rules/change-documents.md)
- 仅按验证场景读取必要实现规则

不读取其他 change 或归档历史。

执行前必须确认状态为 `approved`、`applied` 或 `verified`，且批准有效、冻结摘要匹配。本命令不读取或依赖 `/sdd-apply` 的会话输出、摘要或命令结果；既有验证记录也不得替代本轮执行。

## 输出

- 只执行仓库真实存在的项目命令；模板验证矩阵遵循适用工程规则，不得引用旧结果代替本轮执行。
- 按变更文档规则创建或覆盖人类可读的 `records/verification.md`，记录实际命令、环境、输入、退出码、预期、实际输出摘要和结论。
- 全部真实命令与冻结 Scenario 通过后将状态更新为 `verified`。存在失败、未执行场景或契约偏差时记录失败结论；原 `verified` 重置为 `applied`，原 `approved` 或 `applied` 保持不变。

隔离验证父模板时，可在 `/tmp/` 测试 Chart 提供同名最小 `define` fixture，但须在记录中写明 fixture、隔离范围和未覆盖限制，不得宣称真实子模板集成。契约要求真实集成时，fixture 结果不能判为通过；完成后清理。
