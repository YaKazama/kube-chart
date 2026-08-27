# `/sdd-revise`

## 职责

将当前未合并 change 退回 `draft`，保留可继续修订的契约，并使既有验证证据失效。

```text
/sdd-revise <change-id>
```

## 上下文

遵循 [`../rules/change-documents.md`](../rules/change-documents.md)，只读取当前 change 的 `draft.md` frontmatter，并检查确切的 `records/verification.md` 是否存在；不读取正文、契约、规格或正式代码。

## 输出

- 将 `draft.md` frontmatter 的 `status` 改为 `draft`，保留正文和 `plan/spec.md`。
- 删除确切的 `records/verification.md`；不存在时继续，不扩展删除范围。
- 报告当前状态和失效的验证证据。
