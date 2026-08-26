# `/sdd-apply`

## 职责

只按已冻结契约实施正式代码、执行必需实施检查并记录结果，不执行独立验证，不合并当前规格。

## 读取

- `AGENTS.md`、`openspec/workflow.md`、本文件
- `draft.md`、`records/approval.md`、全部 `plan/`，以及存在的 `records/verification.md`
- 目标代码和直接依赖的当前规格
- 仅按修改范围读取 `AGENTS.md` 路由的实现规则
- [`../checks/implementation.md`](../checks/implementation.md)

不读取其他 change、归档记录或无关验证资料。

## 输出

- 只修改冻结目标授权的正式代码、必要样例或测试资产。
- 创建或更新 `records/verification.md` 的“契约摘要”和“实施检查（必须）”，记录环境、场景、预期、实际和结论。
- 实现或直接依赖发生变化时，将既有“独立验证（可选）”标记为失效或未执行。
- 只用 draft frontmatter `status` 记录实施进度，不改写已冻结 plan。
- 全部实现和必需实施检查通过并写入记录后阶段为 `implemented`；未完成或检查失败时为 `implementing` 并报告剩余项。

先核对冻结摘要。发现契约缺陷或新增需求时停止，不改 draft，按保护规则输出明确修订建议并要求 `/sdd-revise`；不得按代码反写 plan。
