# `/opsx:sync`

## 职责

根据代码事实、测试事实和必要文件上下文，预览并经用户精确确认后反向同步 `spec.md`、`design.md` 和 `tasks.md`；禁止修改 `draft.md`、正式代码和用户文档。

```text
/opsx:sync <change-id> [简短同步说明]

确认回写：
- <精确建议更新项>
```

## 上下文

本动作不依赖聊天历史。读取当前命令输入中的简短同步说明或精确确认、当前 draft、spec、design、tasks、代码边界、相关版本控制差异、测试文件与实际测试结果、代码库中当前 change 明确引用的变更说明，以及 [`../rules/change-documents.md`](../rules/change-documents.md)、[`../rules/specifications.md`](../rules/specifications.md)、[`../rules/designs.md`](../rules/designs.md) 和 [`../rules/tasks.md`](../rules/tasks.md)。

只读取确认代码和测试事实、计算制品差异及闭包直接需要的文件；不得从聊天历史、旧会话摘要或未重新取得的工具结果补充同步内容。

## 预览

每次执行都先根据当前文件重新输出：

1. 代码事实。
2. 与现有 design、tasks、spec 的差异。
3. 建议更新项。
4. 疑似冲突项。
5. 需要用户确认项。
6. 不建议写入规格项。

没有“确认回写”区块、区块只作泛化确认，或确认项与当前重新计算的建议不一致时，本次只输出预览，不修改任何文件。用户可以把精确建议复制到新的 `/opsx:sync <change-id>` 命令输入，或写入当前 change 已明确引用的变更说明后再次执行。

## 回写

- 只回写当前“确认回写”区块与重新计算建议完全对应的内容；未确认项、疑似冲突项和无关整理保持不变。
- 内部重构、语法、类型、DRY 或等价实现只在确有必要时更新 design/tasks，不写入 spec。
- 输入、输出、默认值、失败边界、Scenario、非目标或其他可观察行为变化必须单独确认后才能更新 spec。
- 同步 task checkbox 时必须有当前代码或测试证据；证据失效的 checkbox 取消勾选。
- 回写后执行四向闭包。确认内容不足以闭包时不写冲突项，并报告仍需确认的精确缺口。
- 成功回写且四向闭包成立时，更新 spec 的 `updated_at`；只有本轮确认覆盖全部实际差异且用户确认当前组合时才写入 `confirmed: true`，否则写入 `false`。
- 会话报告实际回写位置、未回写项、冲突和闭包结论。
