# `/sdd-verify`

## 职责

基于当前正式实现运行完整的真实项目命令矩阵，验证其与冻结契约一致，并创建人类可读的统一验证记录；不修代码、不改规格。

## 读取

- `AGENTS.md`、`openspec/workflow.md`、本文件
- `draft.md`、`records/approval.md`、存在的 `records/verification.md`、`plan/spec.md`
- 存在并被批准摘要冻结时，只为核对摘要读取 `plan/design.md`
- 正式实现、直接依赖的当前规格
- [`../checks/verification.md`](../checks/verification.md)
- 仅按验证场景读取必要实现规则

不读取其他 change 或归档历史。

执行前必须确认当前阶段为 `applied` 或 `verified`、批准有效且冻结摘要匹配。既有 `verification.md` 只是上次运行的历史证据，不得替代本次重新执行。

## 输出

- 只执行仓库真实存在的 `make`、Helm、npm 或其他项目命令，并记录实际命令、环境、输入、退出码、预期、实际输出摘要和结论；不得臆造命令或自定义虚构校验器。
- 模板变更至少重新执行 `/opt/homebrew/bin/helm lint`、最小有效输入、较完整有效输入、关键失败输入和受影响回归；不能引用 `/sdd-apply` 的旧结果代替本轮执行。
- 创建或覆盖 `records/verification.md` 的当前验证结果，使用便于人工 Review 的 Markdown，不使用 YAML 记录证据。checklist、静态推断、预期描述或仅有摘要值均不构成通过证据。
- 全部真实命令与冻结 Scenario 通过后把 draft frontmatter `status` 更新为 `verified`；存在失败、未执行场景或契约偏差时保持 `applied`。

需要隔离验证父模板时，可以在 `/tmp/` 测试 Chart 中提供同名最小 `define` fixture，但必须在验证记录中写明 fixture、隔离范围和未覆盖限制，不得宣称真实子模板集成。冻结契约要求真实集成时，fixture 结果不能得出通过结论；完成后清理。
