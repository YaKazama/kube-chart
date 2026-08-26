# kube-chart OpenSpec

这里保存当前行为契约、活动变更与归档历史。命令入口见 [`AGENTS.md`](../AGENTS.md)，共享状态机见 [`workflow.md`](workflow.md)。

用户入口和变更文档格式统一见 [`rules/change-documents.md`](rules/change-documents.md)，状态与门禁统一见 [`workflow.md`](workflow.md)。本文件只提供导航，不定义第二套规则。

具体职责与最小读取范围见 [`commands/`](commands/)，工程规则见 [`rules/`](rules/)，外部事实入口见 [`references/`](references/)。

## 目录职责

```text
openspec/
  commands/                 每个命令的职责与读取范围
  rules/                    按修改类型拆分的工程规则
  specs/                    已实现并合并的当前行为契约
  changes/                  活动变更与 archive/ 历史
  references/               必要时按需读取的官方资料入口
```
