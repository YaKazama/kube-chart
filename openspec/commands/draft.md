# `/sdd-draft`

## 职责

只新建或继续表达用户意图的 `draft.md`；不要求技术目标，不读取目标代码，不生成 spec、design 或 tasks。

```text
/sdd-draft <change-id>
```

新建时只校验 change-id 为 kebab-case 且无同名活动 change；继续时只读取该 change 的 `draft.md`。技术目标不是参数或必填项；参数非法时不写文件。

## 读取

### 固定读取

- [`../rules/change-documents.md`](../rules/change-documents.md)
- 继续草案时，仅当前 change 的 `draft.md`

### 条件读取

- 新建时只检查确切路径 `openspec/changes/<change-id>/draft.md` 是否存在；不得扫描其他 change 推断重名、相似名称或活动状态。

### 禁止读取

- 不读取当前规格、正式代码、目录结构、其他 change、归档、实现规则、参考资料或外部资源。

## 输出

- 按变更文档规则创建或更新轻量 `draft.md`。
- 不创建 `plan/` 或 `records/`；结束时提示用户只需编辑 draft 正文，然后执行 `/sdd-plan`。
