# SDD 工作流

```text
/sdd-new → spec.md → /sdd-design-plan →       design-plan.md ─┐
                          └────────────→ design.md → plan.md ─┤
                                                         ↓
                  /sdd-tasks → tasks.md → /sdd-apply → 代码与 evidence.md
                                                         ↓
                         Review → /sdd-spec → 正式 SDD → archive/
```

- `/sdd-new`：以当前正式 SDD 为基线，在 `changes/<change-id>/` 初始化用户需求表。
- `/sdd-design-plan`：在同一文档中先形成字段设计、规则归属和决策，再形成文件级实施与验证计划。
- 高风险变更可将 `design-plan.md` 拆为 `design.md` 与 `plan.md`；`plan.md` 只能引用已确认的设计决策。
- `/sdd-tasks`：从已确认计划形成可验证的原子任务，每项引用计划 ID 与验收 ID。
- `/sdd-apply`：修改模板、必要示例和验证资产，并在 `evidence.md` 记录命令、输入、结果和失败断言。
- `/sdd-spec`：检查代码、证据与 Review，更新正式 SDD，归档过程材料。
- `/sdd-guide`：仅在用户可见行为稳定后生成或更新用户文档。
