# 正式化门禁

执行 `/sdd-spec` 前必须满足：

- `spec.md`、`design-plan.md`，或已确认的 `design.md` 与 `plan.md`、`tasks.md`、代码和验证证据不存在未解决冲突。
- 所有验收 ID 均有对应的通过证据；计划项已完成或明确取消。
- 最小有效输入和较完整有效输入渲染符合预期。
- 关键非法输入按预期失败，错误格式符合 `[模板名] 字段路径: 错误原因`。
- `helm lint` 通过。
- 通用规则已提炼至 `patterns/`，模板专属规则已写入正式 SDD。
- 正式 SDD 不含过程内容、命令执行记录或临时假设，也不引用 `changes/` 或 `archive/`。
- 人工 Review 已完成。

通过后：更新 `specs/` 中对应模板的唯一正式 SDD；过程文档移至 `archive/changes/<change-id>/`；用户可见行为变化时更新或标记 `guide/`。
