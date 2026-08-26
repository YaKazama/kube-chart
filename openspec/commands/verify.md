# `/sdd-verify`

## 职责

可选地独立验证正式实现与冻结契约是否一致，只补充统一验证记录，不修代码、不改规格。

## 读取

- `AGENTS.md`、`openspec/workflow.md`、本文件
- `draft.md`、`records/approval.md`、`records/verification.md`、`plan/spec.md`
- 存在并被批准摘要冻结时，只为核对摘要读取 `plan/design.md`
- 正式实现、直接依赖的当前规格
- [`../checks/verification.md`](../checks/verification.md)
- 仅按验证场景读取必要实现规则

不读取其他 change 或归档历史。

执行前必须确认“实施检查（必须）”为通过，且其中的冻结摘要和实现文件摘要与当前内容一致。

## 输出

- 更新 `records/verification.md` 的“独立验证（可选）”，记录环境、场景、预期、实际和结论；不得覆盖实施检查。
- 只用 draft frontmatter `status` 记录验证状态；通过后阶段为 `verified`，失败时保持 `implemented`。

未实现子模板视为满足冻结的最小正确返回契约。需要时在 `/tmp/` 提供同名最小 `define`，只验证当前目标，不验证该子模板，也不得宣称真实集成；完成后清理。
