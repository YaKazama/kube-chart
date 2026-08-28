# `/opsx-spec`

## 职责

从完整、无阻塞的 `draft.md` 一次性生成当前 change 的 `spec.md`，确定技术契约并锁定精确代码锚点；不生成 design、tasks 或代码。

```text
/opsx-spec <change-id>
```

## 门禁

- `draft.md` 不存在时中断并警告：必须先执行 `/opsx-draft <change-id>`。
- `spec.md` 已存在时停止，不覆盖或刷新；`status: spec` 时用户可以按规则手工调整代码锚点。
- draft 中存在影响目标、契约、验收或锚点的未确认 `[AI 推断]`、歧义或缺失事实时停止，不创建部分 spec。

## 上下文

读取当前 `draft.md`、[`../rules/change-documents.md`](../rules/change-documents.md) 和 [`../rules/specifications.md`](../rules/specifications.md)。

只按 draft 明确涉及的产物读取精确当前能力规格和适用工程规则；仅为确认真实文件路径、技术目标或直接依赖确有需要时，读取已授权目录的文件清单或精确目标代码。不得读取其他 change、归档、无关实现或沿调用关系扩张上下文。

## 输出

- 在 change 根目录创建 `spec.md`，frontmatter 写入 `status: spec` 和当前 UTC RFC 3339 `updated_at`。
- 规格只记录技术目标、精确代码锚点、可观察行为、失败边界、非目标和 Scenario。
- 代码锚点使用工作区相对的精确文件路径，不使用目录、glob、候选路径或自然语言占位符。
- 不修改 draft、正式代码、用户文档或既有稳定能力规格。
- 会话报告生成的契约、代码锚点，以及用户在 `/opsx-code` 前可以手工调整锚点的提示。
