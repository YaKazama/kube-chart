# `/sdd-apply`

## 职责

只按已冻结契约实施正式代码，并运行必要的真实项目命令获得开发反馈；不创建验证记录，不进入验证结论，不合并当前规格。

## 读取

- `AGENTS.md`、`openspec/workflow.md`、本文件
- `draft.md`、`records/approval.md` 和全部 `plan/`
- 当前状态为 `applied` 时，只读既有 `records/verification.md` 以定位上次验证失败；不得改写或把旧结果当作当前反馈
- 目标代码和直接依赖的当前规格
- [`../rules/change-documents.md`](../rules/change-documents.md)
- 仅按修改范围读取 `AGENTS.md` 路由的实现规则

只接受 `approved` 或 `applied`。不读取其他 change、归档记录或无关验证资料。

## 输出

- 只修改冻结目标授权的正式代码、必要样例或测试资产。
- 运行仓库真实存在且与修改直接相关的最短反馈命令；具体工程门禁由适用规则定义。
- 不创建或更新 `records/verification.md`；正式验证必须由后续 `/sdd-verify` 基于当前实现重新执行并记录。
- 不改写已冻结 plan。全部实现和必要开发反馈完成后进入或保持 `applied`；否则按状态机保持进入命令前的状态并报告实际失败和剩余项。

先按变更文档规则核对批准有效性。批准失效、发现契约缺陷或出现新增需求时停止并要求 `/sdd-revise`；不得按代码反写 plan。
