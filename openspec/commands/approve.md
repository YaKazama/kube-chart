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
- [`../rules/change-documents.md`](../rules/change-documents.md)、[`../rules/specifications.md`](../rules/specifications.md)
- [`../checks/approval.md`](../checks/approval.md)

不读取正式实现、归档历史或验证资料。

## 输出

- 检查阶段：只输出简短批准检查报告，draft frontmatter `status` 保持 `planned`。
- 确认阶段：创建人类可读的 `records/approval.md`，记录批准范围，并附带 `draft-content-sha256`、`plan/spec.md` 和存在的 `plan/design.md` 的 SHA-256；把 `status` 更新为 `approved`。

待确认问题、`[待补充]`、`[AI 推断]`、来源混淆或草稿不一致均阻止批准。
