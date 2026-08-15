# changes

每个未完成的模板或功能使用独立目录：

```text
changes/<change-id>/
  spec.md
  design-plan.md
  tasks.md
  evidence.md
  examples/
```

高风险变更可将 `design-plan.md` 拆为 `design.md` 与 `plan.md`。完成代码、验证和人工 Review 后，正式 SDD 更新至 `../specs/`，过程材料移至 `../archive/changes/`。

`evidence.md` 使用 `../patterns/templates/evidence-template.md`，记录验收 ID、输入资产、命令、预期与实际结果、失败断言和 Review 结论；它是过程证据，不能被正式 SDD 引用。
