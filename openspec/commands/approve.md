# `/sdd-approve`

## 职责

只审查和冻结批准前契约，不修改 draft、plan 或正式代码。

```text
/sdd-approve <change-id>
/sdd-approve <change-id> confirm
```

首次执行检查并输出报告；通过后阶段变为 `approval-pending`。用户检查报告后可回复“确认”或显式执行带 `confirm` 的命令，AI 才写入批准记录并变为 `approved`。确认不得由 AI 代替。

初次检查只接受 `status: planned`；即使 plan 文件已经存在，`status: draft` 也表示仍有阻塞项，必须返回 `/sdd-plan`。

## 读取

- `AGENTS.md`、`openspec/workflow.md`、本文件
- `draft.md`、全部 `plan/`
- [`../rules/change-documents.md`](../rules/change-documents.md)、[`../rules/specifications.md`](../rules/specifications.md)
- [`../checks/approval.md`](../checks/approval.md)

不读取正式实现、归档历史或验证资料。

## 输出

- 检查阶段：只输出简短批准检查报告，并把 draft frontmatter `status` 更新为 `approval-pending`。
- 确认阶段：创建 `records/approval.md`，冻结 `draft-content-sha256`、`plan/spec.md` 和存在的 `plan/design.md` 的 SHA-256；把 `status` 更新为 `approved`。

待确认问题、`[待补充]`、`[AI 推断]`、来源混淆或草稿不一致均阻止批准。
