# `/opsx-spec-rewrite`

## 职责

按用户在当前命令中明确确认的内容受控回写现有 `spec.md`；不从代码反推需求，不修改 draft 或正式代码。

```text
/opsx-spec-rewrite <change-id>

确认回写：
- <需要写入 spec.md 的精确契约变化>
```

## 门禁

- 只接受 `status: code`。
- 当前命令必须携带用户确认的精确回写内容；只有命令名、泛化确认、引用上一轮摘要或要求“按代码同步”时停止。
- 回写要求改变技术目标、代码锚点、capability 或 change 基本范围时停止，并建议新建 change。

## 上下文

只读取当前命令中的确认内容、当前 `spec.md`、[`../rules/change-documents.md`](../rules/change-documents.md) 和 [`../rules/specifications.md`](../rules/specifications.md)。

不得读取 draft、正式代码、其他 change、归档、用户文档或历史聊天来补充回写内容。

## 输出

- 只更新用户明确确认所影响的 Requirement、Scenario、失败边界或非目标；不顺带整理或扩张其他内容。
- 保持 `status: code`，将 `updated_at` 更新为当前 UTC RFC 3339 时间。
- 不修改技术目标、代码锚点、draft、正式代码、用户文档或既有稳定能力规格。
- 会话报告实际回写内容，并提示 `/opsx-review` 将依据完整更新后规格重新核对代码。
