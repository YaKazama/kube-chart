# `/sdd-verify`

## 职责

基于当前正式实现运行完整的真实项目命令矩阵，验证其与冻结契约一致，并创建人类可读的统一验证记录；不修代码、不改规格。

## 读取

- `draft.md` frontmatter、`records/approval.md`、`plan/spec.md`
- 按批准记录检查 `plan/design.md` 的存在性并计算普通 SHA-256；只核对摘要，不读取正文
- 正式实现、直接依赖的当前规格
- [`../rules/change-documents.md`](../rules/change-documents.md)
- 仅按验证场景读取必要实现规则

不读取其他 change 或归档历史。

执行前必须确认当前阶段为 `applied` 或 `verified`、批准有效且冻结摘要匹配。既有 `verification.md` 只是上次运行的历史证据，不得替代本次重新执行。

## 输出

- 只执行仓库真实存在的项目命令；模板验证矩阵遵循适用工程规则，不能引用 `/sdd-apply` 的旧结果代替本轮执行。
- 按变更文档规则创建或覆盖人类可读的 `records/verification.md`，记录实际命令、环境、输入、退出码、预期、实际输出摘要和结论。
- 全部真实命令与冻结 Scenario 通过后把 draft frontmatter `status` 更新为 `verified`；存在失败、未执行场景或契约偏差时保持 `applied`。

需要隔离验证父模板时，可以在 `/tmp/` 测试 Chart 中提供同名最小 `define` fixture，但必须在验证记录中写明 fixture、隔离范围和未覆盖限制，不得宣称真实子模板集成。冻结契约要求真实集成时，fixture 结果不能得出通过结论；完成后清理。
