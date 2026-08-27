# `/sdd-draft`

## 职责

只新建或继续表达用户意图的 `draft.md`；不要求技术目标，不读取目标代码，不生成 plan 或记录。

```text
/sdd-draft <change-id>
```

新建时只校验 change-id 为 kebab-case 且无同名活动 change；继续时只读取该 change 的 `draft.md`。技术目标不是参数或必填项；参数非法时不写文件。

## 上下文

遵循 [`../rules/change-documents.md`](../rules/change-documents.md)。继续草案时只读取当前 `draft.md`；新建时只检查确切目标路径是否存在。当前规格、正式代码和实现规则不属于本命令范围。

## 输出

- 按变更文档规则创建或更新轻量 `draft.md`。
- 不创建 `plan/` 或 `records/`。
