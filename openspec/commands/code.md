# `/opsx:code`

## 职责

按已确认的 `spec.md`、`design.md` 和 `tasks.md` 生成或局部修改正式代码，更新具有当前实现证据的实施 task，并报告本次修改对规格、设计和任务的影响。不执行 Helm 渲染或完整 Chart 检查。

```text
/opsx:code <change-id> [实现说明]
```

## 门禁

- spec、design 或 tasks 任一文件不存在时停止并报告确切缺口。
- `spec.md` 必须为 `confirmed: true`，且当前 draft、spec、design 和 tasks 仍通过四向闭包。
- Requirement、Scenario、设计决策、依赖契约、代码边界或 task 存在会影响当前修改的歧义、无效路径、未决项或冲突时，停止相关修改。
- 所有影响验收、接口、行为和任务边界的决策必须已写入 draft、spec、design 或 tasks。聊天历史可以帮助理解和实施，不能替代制品；缺失时提示先执行 `/opsx:explore` 或 `/opsx:sync` 沉淀。

## 上下文

读取当前命令输入、与当前实现直接相关的聊天历史、当前 draft、spec、design、tasks、design 代码边界列出的精确文件、[`../rules/change-documents.md`](../rules/change-documents.md)，以及按 write boundary 文件类型路由的工程规则。

只沿 design 明确列出的直接依赖读取必要实现，不以聊天历史或相邻代码扩张 capability、行为或 write boundary。

## 输出

- 按 tasks 的依赖顺序实施，只修改 design 中 `access: write` 的文件和 writable scope；`access: read` 文件不得修改。
- 每个文件写入后确认目标存在、内容已生成，并对本次已变更精确文件执行冲突标记、文件末尾换行和明显语法结构检查。
- 不在本动作执行 `helm template`、全 Chart lint 或发布检查；需要实际渲染的验证 task 保持未勾选，并提示 `/opsx:verify <change-id>`。
- 实施 task 的代码结果和对应静态检查均完成后，才把 checkbox 从 `[ ]` 改为 `[x]`；不得改写 task 文本或顺序。
- 需要扩大 write boundary、改变 spec/design 或新增 task 时停止越界部分，不用临时推断补齐。
- 会话报告修改文件、已完成与未完成 task、明显静态检查结果，以及 `规格影响`、`设计影响`、`任务影响`。每项明确为“无”“已有制品已覆盖”或“需要先沉淀”。
- 本动作不改变 `confirmed`，不声明 Helm 验证、归档核对或发布检查通过。
