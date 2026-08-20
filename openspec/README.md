# kube-chart OpenSpec

这里保存 kube-chart 的当前行为契约、进行中的变更和完成历史。开发命令入口在根 [`AGENTS.md`](../AGENTS.md)，完整工作流在 [`openspec/workflow.md`](workflow.md)。

## 当前状态

| 项目 | 阶段 | 下一步 |
|---|---|---|
| [当前 Chart 规格](specs/) | 暂无 | 随第一个真实模板变更建立，不批量回填 |
| [`refactor-api-resources`](changes/refactor-api-resources/proposal.md) | 批准前设计 Review | 确认缺失依赖的处理方式后继续执行 `/sdd-new refactor-api-resources` |

## 30 秒上手

```text
需求不明确           → 先分析，不创建文档
新建或继续草案       → /sdd-new <change-id> [能力名]
草案已经准备完成     → /sdd-approve <change-id>
变更已经批准         → /sdd-apply <change-id>
实现发现新条件       → /sdd-revise <change-id>
实现完成             → /sdd-verify <change-id>
验证及人工 Review 完成 → /sdd-spec <change-id>
```

不要根据“目录存在”判断下一步。继续变更时先进入其[活动变更目录](changes/)，读取 `proposal.md`、`tasks.md`、`approval.md`（若存在）和 `verification.md`：没有有效批准不能执行 `/sdd-apply`，没有完整验证和人工 Review 不能执行 `/sdd-spec`。

日常只需理解三类内容：

- 当前规格：[`openspec/specs/`](specs/)，表示现在必须怎样工作。
- 活动变更：[`openspec/changes/<change-id>/`](changes/)，表示准备怎样修改。
- 完成历史：[`openspec/changes/archive/`](changes/archive/)，解释为什么发生过变化。

## 原 SDD 内容如何保留

| 原 SDD 内容 | 新位置或步骤 |
|---|---|
| 需求 `spec.md` | `proposal.md` 记录范围，`specs/<能力名>/spec.md` 记录可验收行为 |
| `spec-code-plan` 的未知问题验证 | `/sdd-new` 批准前准备阶段的按需探索 |
| `design-plan.md`、`design.md`、`plan.md` | 重要决策写入可选的 `design.md`，实施步骤写入 `tasks.md` |
| `evidence.md` | `verification.md`，仍记录输入、命令、预期、实际结果和失败断言 |
| 人工 Review 与正式化门禁 | `/sdd-verify` 后人工 Review，最后由 `/sdd-spec` 合并并归档 |
| 正式 SDD | [`openspec/specs/<能力名>/spec.md`](specs/)，只保存当前有效契约 |

原 `spec-plan-code` 是默认主线；原 `spec-code-plan` 不再作为独立命令，只保留为 `/sdd-new` 批准前准备阶段的局部探索。`design.md` 按风险创建，`tasks.md` 始终生成；需要独立设计 Review 时直接停止等待确认，不再使用额外命令或参数。

## 目录

```text
openspec/
  config.yaml               OpenSpec 工具配置
  workflow.md               唯一工作流正文
  specs/                    当前行为契约
  changes/                  活动变更
    archive/                完成历史
  rules/                    Helm、values 和文档规则
  checks/                   开发与发布检查
  references/               官方资料与真实实现片段

docs/                       最终用户文档，不保存开发流程
```

## 常用入口

- 工程规则：[`rules/`](rules/)
- 核心模板能力：[`openspec/rules/core-capabilities.md`](rules/core-capabilities.md)
- 开发与发布检查：[`checks/`](checks/)
- 参考资料：[`references/`](references/)
- 最终用户文档：[`docs/`](../docs/)
