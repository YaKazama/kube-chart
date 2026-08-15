# 开发模式

## `spec-code-plan`

适用于基础能力、兼容性行为或公共抽象仍未稳定的阶段。

- 先实现与验证目标模板的关键行为。
- 使用最小输入、完整输入、失败输入和 Helm 渲染结果确认真实边界。
- 跨模板结论进入 `patterns/`，模板专属结论进入正式 SDD。
- 未经代码与验证证据确认的结论不得固化为正式规则。

## `spec-plan-code`

适用于公共契约基本稳定后的新增模板或功能迭代。

- 以当前正式 SDD 为基线。
- 在 `changes/` 依次完成 `spec.md`、`design-plan.md` 与 `tasks.md`；高风险变更使用已确认的 `design.md` 与 `plan.md` 替代 `design-plan.md`。
- 按计划实现、验证，在 `evidence.md` 记录验收证据，完成 Review 后更新正式 SDD。

遇到新的未知兼容性或基础能力问题时，可局部回退至 `spec-code-plan`。
