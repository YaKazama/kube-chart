# `/opsx-review`

## 职责

对当前已变更代码执行三制品一致性核对和文件级轻量检查，输出总结并归档 change；不修复代码，不执行完整 Chart 发布验证。

```text
/opsx-review <change-id>
```

## 门禁

- 正常执行只接受完整三制品契约中的 `status: code`；活动目录为 `status: reviewed` 时只作为上次归档移动中断的恢复入口，但仍需重新完成本轮核对。
- tasks 必须全部勾选；存在未完成任务时停止。
- 使用 design 的 write boundary 限定版本控制状态查询；其中没有当前已修改、已暂存或未跟踪文件时停止，不能用历史提交或归档补充。
- 代码与 spec、design 或 tasks 不一致，存在必须回写但尚未写入的行为，或轻量检查失败时保持 `code`，不归档。

## 上下文

读取当前 `spec.md`、`design.md` 和 `tasks.md`，并通过版本控制状态在 write boundary 内确定当前已变更文件；读取这些文件的当前内容和差异，以及核对直接需要的 read boundary。额外读取 [`../rules/change-documents.md`](../rules/change-documents.md) 和已变更文件类型对应的工程规则作为控制上下文。

不得读取 draft、其他 change、归档、历史聊天、旧摘要、旧工具输出、旧验证结果，或沿 read boundary 扩张调用链。

## 输出

- 逐项核对当前已变更代码是否满足 spec、design、tasks 和 writable scope 限制。
- 执行适用的文件级语法、格式或静态检查；没有真实可用入口时明确标记未执行，不臆造验证器。
- 任一项失败时只在会话中报告文件、契约偏差、检查结果和建议执行的 `/opsx-fix` 或 `/opsx-spec-rewrite`；正常 `code` 状态不修改代码或制品。若当前是归档中断遗留的活动 `reviewed` 状态，则把状态恢复为 `code` 并更新 `spec.md` 的 `updated_at`。
- 全部核对通过后，将 `spec.md` frontmatter 更新为 `status: reviewed` 和当前 `updated_at`，再移动包含 draft、spec、design 和 tasks 的 change 目录到 `openspec/changes/archive/YYYY-MM-DD-<change-id>/`。
- 归档目标存在时停止，不覆盖；移动失败时保留活动目录供相同命令恢复。
- 会话总结修改文件、三制品一致性、实际检查、未覆盖范围和归档位置；不得表述为完整发布验证通过，不创建记录文件。
