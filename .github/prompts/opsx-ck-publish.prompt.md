---
description: "OPSX /opsx:ck:publish — 对整个 Chart 执行只读发布检查"
agent: "agent"
---

执行 kube-chart 的 OPSX 动作 `/opsx:ck:publish`。本动作不接受 change-id。

## 读取顺序

必须按序读完以下三项，再读第 4 项：

1. [AGENTS.md](../../AGENTS.md)：项目基线、角色、上下文访问与规则路由。
2. [openspec/workflow.md](../../openspec/workflow.md)：动作模型、文件即状态、四向闭包、命令上下文类别。
3. [openspec/commands/ck-publish.md](../../openspec/commands/ck-publish.md)：本动作唯一职责、上下文、检查范围与输出定义。
4. 仅第 3 项「上下文」和「检查范围」段明确列出的文件与仓库已有命令。

## 执行边界

- 本文件只是路由入口，不复述、不扩充、不弱化规则；与上述文件冲突时一律以 `openspec/` 内文件为准。
- 按第 2 项的命令上下文类别取用业务上下文；本动作属于「仅文件」类，不得把本轮聊天历史、`/opsx:verify` 结果、`/opsx:archive` 摘要或历史会话结论作为完整发布检查的替代。
- 路径只取自上述文档的明确链接或文件清单；不得由命令名猜测文件名，不得模糊匹配 change-id。
- 检查范围覆盖整个 Chart，但只读取检查项或失败直接涉及的内容。
- 必须实际执行第 3 项要求的真实 Helm 命令；不得臆造仓库不存在的命令或校验器。
- 只读执行，不创建、修改、修复、同步或归档 change；失败后不得修改文件掩盖问题。
- 职责、检查项与输出格式全部以第 3 项为准，不在本文件重复。
