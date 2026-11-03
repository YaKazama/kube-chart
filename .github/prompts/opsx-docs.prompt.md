---
description: "[7/9] OPSX /opsx:docs — 从指定 change 或全部归档生成最终用户文档"
argument-hint: "[change-id]"
agent: "agent"
---

执行 kube-chart 的 OPSX 动作 `/opsx:docs`。

change-id：${input:changeId:输入 kebab-case 的 change-id；留空表示处理全部归档内容}

## 读取顺序

必须按序读完以下三项，再读第 4 项：

1. [AGENTS.md](../../AGENTS.md)：项目基线、角色、上下文访问与规则路由。
2. [openspec/workflow.md](../../openspec/workflow.md)：动作模型、文件即状态、四向闭包、命令上下文类别。
3. [openspec/commands/docs.md](../../openspec/commands/docs.md)：本动作唯一职责、上下文、门禁与输出定义。
4. 仅第 3 项「上下文」段在当前有无 change-id 情形下明确列出的文件。

## 执行边界

- 本文件只是路由入口，不复述、不扩充、不弱化规则；与上述文件冲突时一律以 `openspec/` 内文件为准。
- 按第 2 项的命令上下文类别取用业务上下文；本动作属于「仅文件」类，不得把本轮聊天历史作为业务依据。
- 路径只取自上述文档的明确链接或文件清单；不得由命令名猜测文件名，不得模糊匹配、自动纠错或按唯一活动 change 推断 change-id。
- 带 change-id 时不得自动改为读取同名归档；该 change 缺规格来源、正式实现或验证依据的项按第 3 项门禁跳过并报告证据缺口。
- 只更新 `docs/` 与工作区根 `README.md`；不修改 `openspec/changes/`、模板、values、Schema 或稳定样例。
- 职责、门禁、文档范围与输出格式全部以第 3 项为准，不在本文件重复。
