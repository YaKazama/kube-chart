# `/sdd-rewrite`

## 职责

只无语义变更地整理指定当前规格，不创建 change，不修改实现或用户文档。

## 读取

- `AGENTS.md`、`openspec/workflow.md`、本文件
- 指定的 `openspec/specs/<能力>/spec.md`
- [`../rules/specifications.md`](../rules/specifications.md)
- 仅在无法确认语义时读取对应正式实现

## 输出

只改写指定当前规格的结构和表达。必须保留所有有效 Requirement、Scenario、默认值和边界；发现语义变化或实现不一致时停止。
