# `/opsx-fix`

## 职责

根据当前命令中的用户要求，对已生成代码做局部调整，并判定是否需要用户决定回写行为规格；不修改 change 制品。

```text
/opsx-fix <change-id> <局部调整要求>
```

## 门禁

- 只接受完整三制品契约中的 `status: code`。
- 调整要求必须由用户在当前命令中明确给出；不得用历史聊天、旧摘要或代码事实补全意图。
- 需要增加 task、改变 design、扩大 write boundary、修改用户文档或扩大 capability 时停止，不修改文件，并建议新建 change。

## 上下文

读取当前 `spec.md`、`design.md`、`tasks.md`、与本次局部调整直接相关的 design 代码边界、[`../rules/change-documents.md`](../rules/change-documents.md) 以及适用工程规则。

命令定义、工作流和规则属于控制上下文，不受代码边界限制。不得读取 draft、其他 change、归档、未声明代码边界、用户文档、历史聊天或旧验证结果。

## 输出

- 只修改已锁定的 `access: write` 文件及 writable scope；read boundary 不得修改，不修改 `draft.md`、`spec.md`、`design.md`、`tasks.md`、用户文档或代码边界。
- 修改后依据完整 spec 和 design 核对本轮变化属于实现等价修正还是契约变化。
- 会话必须使用以下固定结论之一：
  - `无需回写`：只涉及重构、DRY、类型稳定、语法修复或使实现重新符合现有 spec 和 design。
  - `必须回写`：改变输入、输出、默认值、失败边界、可观察行为或验收。
- 结论为 `必须回写` 时，给出精确的建议回写位置和文本；若回写会使 design 或 tasks 失效，明确当前 change 不能继续 Review。
- 结论为 `无需回写` 时，明确是否已具备 `/opsx-review` 条件。
- 状态始终保持 `code`，不得更新任何 change 制品。
