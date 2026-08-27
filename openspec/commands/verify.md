# `/sdd-verify`

## 职责

独立基于当前正式实现执行完整的真实验证，生成或覆盖人类可读的统一验证记录，并更新验证状态；不生成或修复代码，不更新任务，不修改规格或用户文档。

## 读取

- `draft.md` frontmatter、`records/approval.md`、`plan/spec.md`
- 按批准记录检查 `plan/design.md` 的存在性并计算普通 SHA-256；只核对摘要，不读取正文
- 正式实现、直接依赖的当前规格
- [`../rules/change-documents.md`](../rules/change-documents.md)
- 仅按验证场景读取必要实现规则

不读取其他 change 或归档历史。

执行前必须确认当前阶段为 `approved`、`applied` 或 `verified`、批准有效且冻结摘要匹配。命令可脱离 `/sdd-apply` 独立执行，不读取或依赖其会话输出、变更摘要或命令结果；既有 `verification.md` 也只是上次运行的历史证据，不得替代本次重新执行。

## 输出

- 只执行仓库真实存在的项目命令；模板验证矩阵遵循适用工程规则，不能引用 `/sdd-apply` 的旧结果代替本轮执行。
- 按变更文档规则创建或覆盖人类可读的 `records/verification.md`，记录实际命令、环境、输入、退出码、预期、实际输出摘要和结论。
- 全部真实命令与冻结 Scenario 通过后把 draft frontmatter `status` 更新为 `verified`。存在失败、未执行场景或契约偏差时，记录失败结论；进入命令前为 `verified` 时重置为 `applied`，进入命令前为 `approved` 或 `applied` 时保持原状态。

需要隔离验证父模板时，可以在 `/tmp/` 测试 Chart 中提供同名最小 `define` fixture，但必须在验证记录中写明 fixture、隔离范围和未覆盖限制，不得宣称真实子模板集成。冻结契约要求真实集成时，fixture 结果不能得出通过结论；完成后清理。
