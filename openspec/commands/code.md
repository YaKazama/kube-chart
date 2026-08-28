# `/opsx-code`

## 职责

按已锁定的 `spec.md`、`design.md` 和 `tasks.md` 生成正式代码并完成任务；不修订用户意图、行为契约或技术设计，不生成其他 change 制品。

```text
/opsx-code <change-id>
```

## 门禁

- spec、design 或 tasks 任一文件不存在时中断并报告确切缺口：必须先成功执行 `/opsx-spec <change-id>`。
- 只接受 `status: spec`；其他状态不修改文件。
- Requirement、Scenario、设计决策、依赖契约、代码边界或 task 存在占位符、歧义、无效路径、未决项或相互冲突时停止。
- design 中每个当前正式依赖必须具有唯一精确 source，tasks 中每个写入目标必须属于 `access: write` 的 writable scope。
- 用户执行本命令即确认已 Review 并接受当前三制品执行契约。

## 上下文

读取当前 `spec.md`、`design.md`、`tasks.md`、design 代码边界列出的精确当前文件、[`../rules/change-documents.md`](../rules/change-documents.md) 以及按 write boundary 文件类型路由的工程规则。

命令定义、工作流和规则属于控制上下文，不受代码边界限制。不得读取 draft、历史聊天、旧摘要、旧工具输出、其他 change、归档、未列入代码边界的正式实现，或沿 read dependency 继续扩张调用链。

## 输出

- 按 tasks 顺序实施；只修改 design 中 `access: write` 的文件和 writable scope，`access: read` 文件不得修改。
- 每项任务实际完成并完成其局部检查后，才把对应 checkbox 从 `[ ]` 改为 `[x]`；不得改写 task 文本或顺序。
- 当前未实现且不属于本 change 的依赖，只能按 design 已锁定的最小契约在 `/tmp/` 验证 Chart 中提供 fixture；不得在正式代码中创建占位实现，也不得表述为真实依赖集成通过。
- 需要扩大 write boundary、修改 design、改变 spec 或新增 task 时停止并报告，不得用历史上下文或临时推断补齐。
- 本动作不声明 Review 或发布验证通过，不创建验证记录。
- 全部 task 完成、代码与三制品一致且适用轻量检查通过后，只把 `spec.md` frontmatter 更新为 `status: code` 和当前 `updated_at`；spec 与 design 正文、tasks 文本和代码边界保持不变。
- 中途失败或存在未完成 task 时保持 `status: spec`，保留已真实完成的 checkbox，报告已修改文件、已完成任务、未完成内容和阻塞原因，允许用户再次执行本命令续作。
