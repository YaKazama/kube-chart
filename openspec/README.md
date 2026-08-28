# kube-chart OpenSpec

这里保存活动变更、归档历史与工程规则。命令入口见 [`AGENTS.md`](../AGENTS.md)，共享状态与门禁见 [`workflow.md`](workflow.md)。

工作流采用精简 OPSX 动作模型：活动 change 只包含 `draft.md` 和 `spec.md`，局部修正是否回写规格由用户显式决定，完整发布验证统一由 `/ck-deploy` 承担。

用户入口、frontmatter、代码锚点和归档格式统一见 [`rules/change-documents.md`](rules/change-documents.md)，本文件只提供导航，不定义第二套规则。

具体职责与最小读取范围见 [`commands/`](commands/)，工程规则见 [`rules/`](rules/)，外部事实入口见 [`references/`](references/)。

## 目录职责

```text
openspec/
  commands/                 每个命令的职责与读取范围
  rules/                    按修改类型拆分的工程规则
  specs/                    既有稳定能力规格，不参与 change 状态机或自动同步
  changes/                  活动变更与 archive/ 历史
  references/               必要时按需读取的官方资料入口
```

归档目录中的旧 change 可以保留历史工作流产生的 `plan/` 或 `records/`，不得用其结构推断当前活动 change 的制品要求。
