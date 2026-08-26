# `/ck-deploy`

## 职责

只对整个 Chart 执行只读发布检查，不创建、修改、批准、合并或归档 change。

## 读取

- `AGENTS.md`、`openspec/workflow.md`、本文件
- `Chart.yaml`、正式模板、values、Schema、当前规格、用户文档与稳定样例
- [`../checks/release.md`](../checks/release.md)
- 检查项明确要求的工程规则

## 输出

只在会话中输出通过项、失败项、证据和发布结论。检查失败不得修改文件来掩盖问题。
