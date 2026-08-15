# 命令调用顺序与适用模式

本文件只定义命令顺序与阶段门禁。模式选择见 [`development-mode.md`](./development-mode.md)，命令目的、产物与必读文档见 [`AGENTS.md`](../../AGENTS.md) 的“触发命令”表，过程材料流转见 [`document-lifecycle.md`](./document-lifecycle.md)。

## 模式链路

| 模式 | 适用条件 | 强制链路 | 按需步骤 |
|---|---|---|---|
| `spec-code-plan` | 公共能力、兼容性或公共抽象未稳定 | `/sdd-new` → `/sdd-apply` → `/helm-lint` 与最小、完整、失败输入渲染 → Review → `/sdd-spec` | 高风险时在 `/sdd-apply` 前执行 `/sdd-design-plan --split`；用户可见行为变化后执行 `/sdd-guide` |
| `spec-plan-code` | 公共契约基本稳定，新增模板或功能迭代 | `/sdd-new` → `/sdd-design-plan` → `/sdd-tasks` → `/sdd-apply` → `/helm-lint` 与验证证据 → `/ck-dev` → Review → `/sdd-spec` | 高风险时以 `/sdd-design-plan --split` 替代合并设计计划；用户可见行为变化后执行 `/sdd-guide`；仅需统一既有 SDD 结构时执行 `/sdd-rewrite` |

## 阶段规则

- `/sdd-new` 在两种模式中都创建 `spec.md`；`spec-code-plan` 至少明确目标、边界、输入与失败输入，`spec-plan-code` 还必须完整记录期望行为与验收约束。
- `/sdd-design-plan` 默认生成按“设计决策在前、实施计划在后”组织的 `design-plan.md`。设计需要独立 Review 或冻结时使用 `--split`：`plan.md` 只引用已确认的 `design.md` 决策。
- `spec-code-plan` 不产生 `tasks.md`，但 `/sdd-apply` 必须在 `evidence.md` 记录命令、输入、结果与失败断言；跨模板结论进入 `patterns/` 前必须同时具备代码与证据。
- `spec-plan-code` 的 `spec.md` → `design-plan.md`（或 `design.md` → `plan.md`）→ `tasks.md` → `/sdd-apply` 不得跳步；每项过程产物确认后才能进入下一阶段。
- 所有模板修改都必须通过 `/helm-lint`。`/sdd-spec` 前还必须完成验证证据与人工 Review；正式 SDD 不依赖过程材料。

## 模式切换

- 当跨模板公共能力和 Helm/Kubernetes 兼容性均无未决问题，且至少完成一轮跨模板结论沉淀到 `patterns/` 后，可从 `spec-code-plan` 切换到 `spec-plan-code`；在 `evidence.md` 或设计计划中记录依据。
- `spec-plan-code` 遇到未知兼容性或基础能力问题时，仅该子问题回退至 `spec-code-plan`；解决后回到原主线。
