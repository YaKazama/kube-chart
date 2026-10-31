# `/opsx:spec`

## 职责

根据当前文件创建、校对或更新 change 的 `spec.md`、`design.md` 和 `tasks.md`，并执行 draft ↔ spec ↔ design ↔ tasks 四向闭包检查；不生成代码，不依赖聊天历史。

```text
/opsx:spec <change-id>
/opsx:spec <change-id> --confirm
```

## 门禁

- change 目录和 `draft.md` 必须存在；缺失时停止并报告执行 `/opsx:new <change-id>` 所需的确切缺口。
- draft 中影响行为、验收、技术目标、依赖、代码边界或任务的未确认 `[AI 推断]` 或阻塞性开放问题，必须作为冲突报告，不得自行选择后写入执行制品。
- 已有 spec、design 或 tasks 不是失败条件。任一文件存在时必须读取并逐项比较；缺失文件按已确认 draft 和既有制品闭包创建。

## 上下文

本动作只使用文件上下文，不使用聊天历史。读取当前 `draft.md`、已有 `spec.md`、`design.md`、`tasks.md`、[`../rules/change-documents.md`](../rules/change-documents.md)、[`../rules/specifications.md`](../rules/specifications.md)、[`../rules/designs.md`](../rules/designs.md) 和 [`../rules/tasks.md`](../rules/tasks.md)。

只按 draft 和已有制品明确涉及的产物读取精确当前能力规格、适用工程规则、文件清单、目标代码和直接依赖。代码和参考资料只提供当前实现事实、版本事实和技术约束，不得反向生成 Requirement、默认值、失败边界或验收。

## 重复执行

1. 建立 draft、spec、design 和 tasks 的现有映射。
2. 对每个已有制品列出保留、更新、补全、删除候选和冲突；不得整文件盲目重写。
3. 不存在的制品按当前闭包创建；存在的制品只修改具有明确来源的区段。
4. 保留语义未变且仍有事实支撑的 task checkbox；task 文本变化或证据失效时取消对应勾选。
5. 重新执行四向闭包检查，并把未闭包项精确映射回来源文件。

## 输出

- 创建或更新 `spec.md`、`design.md`、`tasks.md`；首次生成的 spec 使用 `confirmed: false`。
- 任一执行制品正文或 task 文本发生变化时，把 `spec.md` 的 `confirmed` 重置为 `false` 并更新 `updated_at`；无变化时不改文件。
- 无法唯一确定的冲突项保持原文或保持缺失，不用 AI 推断覆盖；已经安全写入的独立补全可以保留，但不得宣称整体闭包完成。
- 会话输出文件级差异、冲突、缺失项、行为闭包、设计闭包、任务闭包和实现事实映射结论。
- 只有三制品完整、无阻塞冲突且四向闭包成立时，才报告可供用户审阅并显式设置 `confirmed: true`。

## 确认

`--confirm` 只表示确认当前文件中的三制品组合，不允许携带新的行为或设计内容。命令必须重新读取所有允许的文件并完成差异与四向闭包检查；只要候选更新、冲突、缺失项或失效 checkbox 仍存在，就保持 `confirmed: false` 并报告。当前三制品无需修改且闭包成立时，只把 `confirmed` 改为 `true` 并更新 `updated_at`。
