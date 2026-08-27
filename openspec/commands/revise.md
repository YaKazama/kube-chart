# `/sdd-revise`

## 职责

幂等重置当前未合并 change：将状态改为 `draft`，移除其 `plan/` 与 `records/`，防止旧产物污染下次 `/sdd-plan`；不检查原状态、approval 是否存在或摘要是否有效。

```text
/sdd-revise <change-id>
```

## 读取

### 固定读取

- 当前 change 的 `draft.md` frontmatter

### 条件读取

- 只检查当前 change 根目录下确切的 `plan/` 与 `records/` 是否存在，不读取其中内容。

### 禁止读取

- 不读取 draft 正文、plan 或 records 内容、其他 change、归档、规格、规则、正式代码、参考资料或外部资源。

## 输出

- 只将 `draft.md` frontmatter 的 `status` 改为 `draft`；正文及其他 frontmatter 字段不变。
- 递归移除当前 change 根目录中确切的 `plan/` 与 `records/`；目录或文件已经不存在时继续执行，不得扩展删除范围，不读取或删除其他 change、归档、规格、规则或正式代码。
- 状态重置和目录清理全部完成后才报告成功；报告保留的 draft 正文、移除的派生产物，并提示完成需求修订后执行 `/sdd-plan`。
