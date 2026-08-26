# `/sdd-approve`

## 职责

只审查和冻结批准前契约；除确认时更新 draft frontmatter 状态外，不修改 draft 正文、plan 或正式代码。

```text
/sdd-approve <change-id>
/sdd-approve <change-id> confirm
```

首次执行检查并输出报告，状态保持 `planned`。用户检查报告后可回复“确认”或显式执行带 `confirm` 的命令，AI 才写入批准记录并变为 `approved`。确认不得由 AI 代替，也不为等待确认创建中间状态。

初次检查只接受 `status: planned`；即使 plan 文件已经存在，`status: draft` 也表示仍有阻塞项，必须返回 `/sdd-plan`。

## 读取

- `AGENTS.md`、`openspec/workflow.md`、本文件
- `draft.md`、全部 `plan/`
- 仅为复查目标冲突读取其他活动 change 的 draft frontmatter 和 `plan/spec.md` 的 `## 技术目标`
- [`../rules/change-documents.md`](../rules/change-documents.md)、[`../rules/specifications.md`](../rules/specifications.md)

不读取正式实现、归档历史或验证资料。

## 输出

- 检查阶段：审查 draft、技术目标、spec、可选 design 和 tasks 的一致性与完整性，并输出简短报告；状态保持 `planned`。
- 确认阶段：按变更文档规则创建 `records/approval.md` 并进入 `approved`。

任何待确认问题、目标冲突或草稿不一致均阻止批准。
