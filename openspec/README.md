# kube-chart OpenSpec

这里保存当前行为契约、活动变更与归档历史。命令入口见 [`AGENTS.md`](../AGENTS.md)，共享状态机见 [`workflow.md`](workflow.md)。

## 用户入口

用户只处理 `openspec/changes/<change-id>/draft.md` 的正文并表达意图。frontmatter 由 AI 维护；新建时只记录当前阶段和 change 身份，通过 `/sdd-plan` 预检后再记录技术目标。主要能力、define 名称和目标路径不要求用户预先提供。正文固定为：

- 目标
- 需求
- 约束
- 非目标
- 验收

其中“约束”只保存用户明确指定的本次特殊限制。AI 可以草拟内容，但必须标记 `[AI 推断]`；用户确认后由 AI 去除标记并写回。会话中确认的修改不能只留在聊天记录。

## 流程

```text
/sdd-draft   创建或继续只表达意图的 draft.md
/sdd-plan    检查技术目标并生成 plan/spec.md、可选 design.md 和 tasks.md
/sdd-approve 检查并冻结契约
/sdd-apply   实施正式代码并运行真实命令获得开发反馈
/sdd-verify  运行真实命令并写入 verification.md
/sdd-merge   合并规格、同步文档、归档
```

每次命令都先报告 draft frontmatter 中的当前阶段。具体职责与最小读取范围见 [`commands/`](commands/)，阶段检查见 [`checks/`](checks/)，工程规则见 [`rules/`](rules/)。

状态固定为 `draft → planned → approved → applied → verified → merged`，只表示最近完成的稳定门禁。等待确认、执行中、失败或修订不创建额外状态。

`/sdd-plan` 首先检查主要能力、define 名称和目标路径。技术目标无法唯一确定或校验失败时不生成 plan，状态保持 `draft`；存在 `[AI 推断]`、`[待补充]`、未决设计选择或验收缺口时可刷新轻量 plan，但同样保持 `draft`。全部阻塞项消除后才进入 `planned`。

验证必须运行仓库真实存在的项目命令。Markdown checklist 只是执行提示，不能作为通过证据；实际命令、退出码、预期、实际结果和结论统一记录在 `records/verification.md`。

## 目录职责

```text
openspec/
  commands/                 每个命令的职责与读取范围
  checks/                   按阶段拆分的执行提示，不作为验证证据
  rules/                    按修改类型拆分的工程规则
  specs/                    已实现并合并的当前行为契约
  changes/                  活动变更与 archive/ 历史
  references/               必要时按需读取的官方资料和实现片段
```
