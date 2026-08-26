# `/sdd-draft`

## 职责

只新建或继续表达用户意图的 `draft.md`，不要求用户提供技术目标，不读取目标代码，不生成 spec、design 或 tasks。

```text
/sdd-draft <change-id>
```

新建时只校验 change-id 为 kebab-case 且没有同名活动 change 冲突；继续时只读取该 change 的 `draft.md`。技术目标不作为本命令的参数或必填项；参数非法时不写文件。

## 读取

- [`../rules/change-documents.md`](../rules/change-documents.md)
- 继续草案时的 `draft.md`

## 输出

- 按 [`../rules/change-documents.md`](../rules/change-documents.md) 创建或更新轻量 `draft.md`。
- 不创建 `plan/` 或 `records/`；结束时提示用户只需编辑 draft 正文，然后执行 `/sdd-plan`。
