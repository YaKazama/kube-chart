# kube-chart OpenSpec

这里保存当前行为契约、活动变更与归档历史。命令入口见 [`AGENTS.md`](../AGENTS.md)，共享状态机见 [`workflow.md`](workflow.md)。

## 当前状态

| change | 阶段 | 下一步 |
|---|---|---|
| [`add-apps-deployment`](changes/add-apps-deployment/) | `planned` | `/sdd-approve add-apps-deployment` |

## 用户入口

用户只处理 `openspec/changes/<change-id>/draft.md`。frontmatter 显示当前阶段、change 身份和目标文件，正文固定为：

- 目标
- 需求
- 非目标
- 验收
- 约束

其中“约束”只保存用户明确指定的本次特殊限制。AI 可以草拟内容，但必须标记 `[AI 推断]`；用户确认后由 AI 去除标记并写回。会话中确认的修改不能只留在聊天记录。

## 流程

```text
/sdd-draft   创建或继续 draft.md
/sdd-plan    生成 plan/spec.md、可选 design.md、tasks.md
/sdd-approve 检查并冻结契约
/sdd-apply   实施正式代码并记录必需实施检查
/sdd-verify  可选独立验证
/sdd-merge   合并规格、同步文档、归档
```

每次命令都先报告 draft frontmatter 中的当前阶段。具体职责与最小读取范围见 [`commands/`](commands/)，阶段检查见 [`checks/`](checks/)，工程规则见 [`rules/`](rules/)。

`/sdd-plan` 遇到 `[AI 推断]`、`[待补充]`、未决设计选择或验收缺口时仍可刷新 plan，但状态保持 `draft`；没有阻塞项时才进入 `planned`。

## 目录职责

```text
openspec/
  commands/                 每个命令的职责与读取范围
  checks/                   按阶段拆分的检查清单
  rules/                    按修改类型拆分的工程规则
  specs/                    已实现并合并的当前行为契约
  changes/                  活动变更与 archive/ 历史
  references/               必要时按需读取的官方资料和实现片段
```
