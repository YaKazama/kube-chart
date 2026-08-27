# `/sdd-revise`

## 职责

重置当前未合并 change：将 `draft.md` frontmatter `status` 改为 `draft`，并移除该 change 的 `plan/` 与 `records/`，防止旧派生产物污染下一次 `/sdd-plan`。该操作是幂等的；不校验进入命令前的状态、approval 是否存在或摘要是否有效。

## 读取

- `draft.md` frontmatter

## 输出

- 只将 `draft.md` frontmatter 中的 `status` 改为 `draft`；正文和其他 frontmatter 字段保持不变。
- 递归移除当前 change 根目录中确切的 `plan/` 与 `records/`；目录或文件已经不存在时继续执行，不得扩展删除范围，不读取或删除其他 change、归档、规格、规则或正式代码。
- 状态重置和两个目录清理全部完成后才报告成功；报告已保留 `draft.md` 正文、已移除的派生产物，并提示用户完成需求修订后执行 `/sdd-plan`。
