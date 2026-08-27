# `/sdd-plan`

## 职责

只接受 `draft`，从 `draft.md` 生成 `plan/spec.md`；有阻塞项时保持草稿，无阻塞项时进入 `planned`。不修改正式代码或创建阶段记录。

```text
/sdd-plan <change-id>
```

## 上下文

读取当前 `draft.md`、已有 `plan/spec.md`、[`../rules/change-documents.md`](../rules/change-documents.md) 与 [`../rules/specifications.md`](../rules/specifications.md)。按 draft 涉及的产物读取确切当前规格和适用工程规则；只有解析技术目标或契约仍需要实现事实时，才检查确切目标或直接依赖。其他活动 change 只比较技术目标，重叠时阻止进入 `planned`；不得读取其余内容、归档、调用链或相邻能力，也不得用正式代码扩张用户需求。版本特定事实确有缺口时才使用精确的官方资料。

## 输出

- 状态不是 `draft` 时停止并要求 `/sdd-revise`；当前消息确认了意图变化时，先按变更文档规则写回 `draft.md`。
- `plan/spec.md` 只记录技术目标、可观察行为、失败边界、非目标和 Scenario；工程规则直接约束后续实现，不复制成计划说明。
- 技术目标、用户意图、契约选择或验收存在未决项时，在 spec 中记录问题并保持 `draft`；否则进入 `planned`。
- 会话报告生成的契约和阻塞项。
