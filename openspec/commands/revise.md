# `/sdd-revise`

## 职责

只将当前未合并 change 的 `draft.md` frontmatter `status` 改为 `draft`。该操作是幂等的；不校验进入命令前的状态、approval 是否存在或摘要是否有效。

## 读取

- `draft.md` frontmatter

## 输出

- 只将 `draft.md` frontmatter 中的 `status` 改为 `draft`；正文和其他 frontmatter 字段保持不变。
- 除命令入口和 `draft.md` 外，不读取其他 change 内容；不修改 draft 正文、plan、approval、verification、规格、规则或正式代码，既有 plan 不能继续作为实施依据。
- 报告状态已重置，并提示用户完成需求修订后执行 `/sdd-plan`。
