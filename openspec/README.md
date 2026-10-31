# kube-chart OpenSpec

这里保存活动变更、归档历史与工程规则。命令入口见 [`AGENTS.md`](../AGENTS.md)，文件即状态判据与共享闭包见 [`workflow.md`](workflow.md)。

工作流采用 OPSX 多制品动作模型：`draft.md` 保存意图与开放问题，`spec.md` 锁定行为，`design.md` 锁定技术设计与代码边界，`tasks.md` 记录实施和验证进度。动作可以按需重复执行，不使用刚性阶段或状态机；最小 Helm 渲染由 `/opsx:verify` 承担，完整发布检查由 `/opsx:ck:publish` 承担。

用户入口、制品归属、frontmatter 和归档格式统一见 [`rules/change-documents.md`](rules/change-documents.md)，本文件只提供导航，不定义第二套规则。

具体职责与最小读取范围见 [`commands/`](commands/)，工程规则见 [`rules/`](rules/)，外部事实入口见 [`references/`](references/)。

## 目录职责

```text
openspec/
  commands/                 每个命令的职责与读取范围
  rules/                    按修改类型拆分的工程规则
  specs/                    既有稳定能力规格，不参与活动 change 的文件状态判断
  changes/                  活动变更与 archive/ 历史
  references/               必要时按需读取的官方资料入口
```

归档目录中的旧 change 可以保留历史工作流产生的 frontmatter、`plan/` 或 `records/`，不得用其结构推断当前活动 change 的制品要求。
