# `/opsx-draft`

## 职责

只新建或继续表达用户初始意图的 `draft.md`；不读取正式代码，不生成 spec 或其他制品。

```text
/opsx-draft <change-id>
```

新建时只校验 change-id 为 kebab-case 且确切目标路径不存在；继续时要求 `draft.md` 已存在且 `spec.md` 不存在。参数非法、目录结构异常或 spec 已存在时不写文件。

## 上下文

读取当前命令输入和 [`../rules/change-documents.md`](../rules/change-documents.md)。继续草案时额外读取当前 `draft.md`；新建时只检查确切目标路径是否存在。

当前规格、正式代码、工程实现规则、其他 change、归档和参考资料不属于本动作范围。

## 输出

- 按变更文档规则创建或更新轻量 `draft.md`，frontmatter 只含 `change-id` 和 `updated_at`。
- 只把当前命令中用户明确表达或确认的意图写回正文；AI 建议保留 `[AI 推断]`。
- 只在正文实际变化时更新 `updated_at`；无变化时不改文件。
- 不创建 `spec.md`、plan、records 或正式代码。
- 会话报告已写入意图、待确认推断和当前隐式 `draft` 状态。
