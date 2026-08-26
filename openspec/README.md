# kube-chart OpenSpec

这里保存 kube-chart 的当前行为契约、进行中的变更和完成历史。开发命令入口在根 [`AGENTS.md`](../AGENTS.md)，完整工作流在 [`openspec/workflow.md`](workflow.md)。

## 当前状态

| 项目 | 阶段 | 下一步 |
|---|---|---|
| [当前 Chart 规格](specs/) | 暂无 | 随第一个真实模板变更建立，不批量回填 |
| [`add-apps-deployment`](changes/add-apps-deployment/) | 草案，待确认子模板 | 修改 proposal 中的 `[DEP-002]`、`[DEP-003]` |

## 用户只修改一个文件

每个活动 change 的 `proposal.md` 是唯一用户入口，固定为“目标、需求、约束”。可以直接修改这三节，也可以在会话中描述，由 AI 更新并同步其他文件。

proposal 顶部直接列出状态、change-id、主要能力、命名模板和存放路径；多个模板按顺序成对列出，打开文件即可确认本次变更写什么、写到哪里。

项目规则、当前规格、目标代码和官方资料由 AI 自动读取；proposal 不设置“参考”节。用户主动提供的特殊依据直接归入需求或约束。

“约束”只填写用户针对本次变更明确指定的特殊限制；没有时保持空白。版本基线、工程规则、安全边界和验证要求由 AI 自动补充到生成产物，不显示在 proposal 中。

change 根目录只有 `proposal.md` 是用户编辑文件。变更规格放在 `specs/`，design、tasks、approval 和 verification 统一放在 `artifacts/`；这些都是 AI 产物，不要求用户理解内部格式，也不要在其中修改需求。verification 只在正式实现完成后的 `/sdd-verify` 阶段创建。

## 30 秒上手

```text
需求不明确           → 先分析；目标参数合法时先创建 proposal
新建或继续草案       → /sdd-new <change-id> <主要能力名> <define名称=tpl文件>...
发现缺失子模板       → 在 proposal“目标”中修改对应 checkbox 占位
草案已经准备完成     → /sdd-approve <change-id>
变更已经批准         → /sdd-apply <change-id>
实现发现新条件       → /sdd-revise <change-id>
实现完成             → /sdd-verify <change-id>
验证及人工 Review 完成 → /sdd-spec <change-id>
```

不要根据“目录存在”判断下一步。继续变更时先读取 `proposal.md`、`specs/` 和 `artifacts/`：没有有效批准不能执行 `/sdd-apply`，没有基于当前正式实现的完整验证和人工 Review 不能执行 `/sdd-spec`。

例如：

```text
/sdd-new add-apps-deployment deployment apps.deployment=templates/api-resources/Apps/_Deployment.tpl
```

`deployment` 是主要规格归属，`apps.deployment` 与 `_Deployment.tpl` 是显式绑定的 Helm 模板目标。首次执行创建三节式 proposal，并由 AI 同步其余材料。父级行为明确但子模板缺失时，只在 proposal “目标”维护完整占位行；其他材料引用编号。用户修改 checkbox 行或通过后续 `/sdd-new` 确认映射后继续展开。

日常只需理解三类内容：

- 当前规格：[`openspec/specs/`](specs/)，表示现在必须怎样工作。
- 活动变更：[`openspec/changes/<change-id>/`](changes/)，表示准备怎样修改。
- 完成历史：[`openspec/changes/archive/`](changes/archive/)，解释为什么发生过变化。

## 原 SDD 内容如何保留

| 原 SDD 内容 | 新位置或步骤 |
|---|---|
| `目标、需求、约束` | 原样保留在 `proposal.md`，作为唯一用户入口 |
| OpenSpec Requirement | AI 从 proposal 同步到 `specs/<能力名>/spec.md` |
| `spec-code-plan` 的未知问题验证 | `/sdd-new` 批准前准备阶段的按需探索 |
| `design-plan.md`、`design.md`、`plan.md` | 重要决策写入可选的 `artifacts/design.md`，实施步骤写入 `artifacts/tasks.md` |
| `evidence.md` | 正式实现完成后由 `/sdd-verify` 创建 `artifacts/verification.md`；草案和提前探索不生成验证文件 |
| 人工 Review 与正式化门禁 | `/sdd-verify` 后人工 Review，最后由 `/sdd-spec` 合并并归档 |
| 正式 SDD | [`openspec/specs/<能力名>/spec.md`](specs/)，只保存当前有效契约 |

原 `spec-plan-code` 是默认主线；原 `spec-code-plan` 不再作为独立命令，只保留为 `/sdd-new` 批准前准备阶段的局部探索。`artifacts/design.md` 按风险创建，`artifacts/tasks.md` 始终生成；需要独立设计 Review 时直接停止等待确认，不再使用额外命令或参数。

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
