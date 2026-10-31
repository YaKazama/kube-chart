# `/opsx:new`

## 职责

为新的 change 创建目录和轻量 `draft.md`，记录意图、验收和开放问题；不生成 spec、design、tasks、代码或用户文档。

```text
/opsx:new <change-id>
```

## 门禁

- change-id 必须是 kebab-case，并精确映射到 `openspec/changes/<change-id>/`。
- 目标活动目录已存在时停止，不覆盖、不续写，也不自动改名。
- 当前输入和聊天历史无法唯一确定的内容不得伪装为用户意图；必要建议标记 `[AI 推断]`，不确定事项写入开放问题。

## 上下文

读取当前命令输入、与本 change 明确相关的聊天历史、[`../rules/change-documents.md`](../rules/change-documents.md)，以及创建目标前用于确认确切路径不存在的文件清单。

只有在用户意图明确引用某个当前文件且其内容会影响草稿准确性时，才读取该精确文件。不得扫描其他 change 或归档来补全意图。

## 输出

- 创建 `openspec/changes/<change-id>/draft.md`，frontmatter 和正文遵循变更文档规则。
- 把明确意图写入目标、需求、约束、非目标或验收，把尚未形成共识的事项写入开放问题。
- 会话报告新建路径、已记录意图、`[AI 推断]` 和开放问题。
- 任一步写入失败时报告实际文件，不继续创建其他制品。
