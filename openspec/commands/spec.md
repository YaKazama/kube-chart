# `/opsx:spec`

## 职责

根据当前文件创建、校对或更新 change 的 `spec.md`、`design.md` 和 `tasks.md`，并执行 draft ↔ spec ↔ design ↔ tasks 四向闭包检查；不生成代码，不依赖聊天历史。

```text
/opsx:spec <change-id>
```

## 门禁

- change 目录和 `draft.md` 必须存在；缺失时停止并报告执行 `/opsx:new <change-id>` 所需的确切缺口。
- draft 中影响行为、验收、技术目标、依赖、代码边界或任务的未确认 `[AI 推断]` 或阻塞性开放问题，必须作为冲突报告，不得自行选择后写入执行制品。
- 创建或更新 design 依赖契约前，必须实际读取涉及的公共模板（`base.*`、`definitions.*` 和同 API 组既有模板）及其精确 source，按 [`../rules/helm-templates.md`](../rules/helm-templates.md) 与 [`../rules/core-capabilities.md`](../rules/core-capabilities.md) 复核是否存在且能力足够，并据此确定 `availability`、`operation` 和边界；不得凭推断或命名猜测写入依赖契约。
- 公共模板缺失或能力不足，且 draft 未确认由本 change 以 `add | update | remove | rename` 授权时，必须作为冲突报告；不得自行选择新增、改写公共模板或绕开缺口改为内联实现。
- 已有 spec、design 或 tasks 不是失败条件。任一文件存在时必须读取并逐项比较；缺失文件按已确认 draft 和既有制品闭包创建。

## 上下文

本动作只使用文件上下文，不使用聊天历史。读取当前 `draft.md`、已有 `spec.md`、`design.md`、`tasks.md`、[`../rules/change-documents.md`](../rules/change-documents.md)、[`../rules/specifications.md`](../rules/specifications.md)、[`../rules/designs.md`](../rules/designs.md) 和 [`../rules/tasks.md`](../rules/tasks.md)。

只按 draft 和已有制品明确涉及的产物读取精确当前能力规格、适用工程规则、文件清单、目标代码和直接依赖。复核依赖契约时读取 design 依赖契约涉及的公共模板及其精确 source，用于判定存在性、能力范围和调用边界。代码和参考资料只提供当前实现事实、版本事实和技术约束，不得反向生成 Requirement、默认值、失败边界或验收。

## 重复执行

1. 建立 draft、spec、design 和 tasks 的现有映射。
2. 对每个已有制品列出保留、更新、补全、删除候选和冲突；不得整文件盲目重写。
3. 不存在的制品按当前闭包创建；存在的制品只修改具有明确来源的区段。
4. 保留语义未变且仍有事实支撑的 task checkbox；task 文本变化或证据失效时取消对应勾选。
5. 重新执行四向闭包检查，并把未闭包项精确映射回来源文件。

## 输出

- 创建或更新 `spec.md`、`design.md`、`tasks.md`；`spec.md` frontmatter 只维护 `updated_at`。
- 依赖契约必须逐项给出经复核的 `availability` 和 `operation`：`existing` 对应真实精确 source，`unavailable` 明确不在本 change 实现，并在对应 Dependency 中记录复核确认的公共模板缺口。
- 任一执行制品正文或 task 文本发生变化时，同步更新 `spec.md` 的 `updated_at`；无变化时不改文件。
- 无法唯一确定的冲突项保持原文或保持缺失，不用 AI 推断覆盖；已经安全写入的独立补全可以保留，但不得宣称整体闭包完成。
- 会话输出文件级差异、冲突、缺失项、行为闭包、设计闭包、任务闭包和实现事实映射结论。

## 完成判据

三制品完整、无阻塞冲突、依赖契约的公共模板复核结论与当前事实一致且四向闭包成立时，报告本次可交付的三制品组合；任一条件不成立则报告精确缺口。
