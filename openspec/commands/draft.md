# `/sdd-draft`

## 职责

只新建或继续表达用户意图的 `draft.md`，不要求用户提供技术目标，不读取目标代码，不生成 spec、design 或 tasks。

```text
/sdd-draft <change-id>
```

新建时只校验 change-id 为 kebab-case 且没有同名活动 change 冲突；继续时只读取该 change 的 `draft.md`。主要能力、artifact 类型、define 名称和目标路径由 AI 维护，不作为本命令的必填参数；参数非法时不写文件。

## 读取

- `AGENTS.md`
- `openspec/workflow.md`
- 本文件
- [`../rules/change-documents.md`](../rules/change-documents.md)
- 继续草案时的 `draft.md`

## 输出

- 创建或更新 `draft.md` 的最小 frontmatter 和正文；用户明确内容不得被 AI 草稿覆盖。
- 新建时 frontmatter 只要求 `status` 和 `change-id`。如果用户已经明确技术目标，可以原样记录；不得读取代码自行推导，缺失字段留给 `/sdd-plan` 预检。
- AI 草拟内容逐项标记 `[AI 推断]`，frontmatter `status` 设为 `draft`。
- 不创建 `plan/` 或 `records/`；结束时提示用户只需编辑 draft 正文，然后执行 `/sdd-plan`，由后者提前检查技术目标。
