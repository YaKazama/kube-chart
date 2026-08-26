# `/sdd-draft`

## 职责

只新建或继续用户入口 `draft.md`，不读取目标代码，不生成 spec、design 或 tasks。

```text
/sdd-draft <change-id> <主要能力> <define名称=tpl路径>
/sdd-draft <change-id>
```

新建时校验 change-id 为 kebab-case、单一主要模板映射格式和活动 change 冲突；继续时只读取该 change 的 `draft.md`。参数非法时不写文件。

## 读取

- `AGENTS.md`
- `openspec/workflow.md`
- 本文件
- [`../rules/change-documents.md`](../rules/change-documents.md)
- 继续草案时的 `draft.md`

## 输出

- 创建或更新 `draft.md` frontmatter 和正文；用户明确内容不得被 AI 草稿覆盖。
- AI 草拟内容逐项标记 `[AI 推断]`，frontmatter `status` 设为 `draft`。
- 不创建 `plan/` 或 `records/`；结束时提示用户只需编辑 draft，然后执行 `/sdd-plan`。
