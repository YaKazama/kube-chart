# `/sdd-apply`

## 职责

只按已冻结契约实施正式代码，并运行必要的真实项目命令获得开发反馈；不创建验证记录，不进入验证结论，不合并当前规格。

## 读取

- `AGENTS.md`、`openspec/workflow.md`、本文件
- `draft.md`、`records/approval.md` 和全部 `plan/`
- 当前状态为 `applied` 时，只读既有 `records/verification.md` 以定位上次验证失败；不得改写或把旧结果当作当前反馈
- 目标代码和直接依赖的当前规格
- 仅按修改范围读取 `AGENTS.md` 路由的实现规则
- [`../checks/implementation.md`](../checks/implementation.md)

只接受 `approved` 或 `applied`。不读取其他 change、归档记录或无关验证资料。

## 输出

- 只修改冻结目标授权的正式代码、必要样例或测试资产。
- 运行仓库真实存在且与修改直接相关的最短反馈命令；模板变更至少运行真实的 `/opt/homebrew/bin/helm lint`。不得臆造 `make`、Helm、npm 或其他命令，不得把 checklist、静态推断或预期描述当作命令结果。
- 不创建或更新 `records/verification.md`；正式验证必须由后续 `/sdd-verify` 基于当前实现重新执行并记录。
- 不改写已冻结 plan。全部实现和必要开发反馈完成后把 draft frontmatter `status` 更新或保持为 `applied`；未完成或真实命令失败且无法在本轮修复时保持进入命令前的 `approved` 或 `applied`，并报告实际失败和剩余项。

先核对冻结摘要。发现契约缺陷或新增需求时停止，不改 draft，按保护规则输出明确修订建议并要求 `/sdd-revise`；不得按代码反写 plan。
