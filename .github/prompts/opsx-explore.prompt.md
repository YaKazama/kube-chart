---
description: "OPSX /opsx:explore — 讨论并把共识或开放问题写入 draft"
argument-hint: "<change-id> [讨论主题或笔记路径]"
agent: "agent"
---

执行 kube-chart 的 OPSX 动作 `/opsx:explore`。

参数：${input:args:输入 <change-id>，可选追加讨论主题或当前 change 目录内的笔记路径}

## 读取顺序

必须按序读完以下三项，再读第 4 项：

1. [AGENTS.md](../../AGENTS.md)：项目基线、角色、上下文访问与规则路由。
2. [openspec/workflow.md](../../openspec/workflow.md)：动作模型、文件即状态、四向闭包、命令上下文类别。
3. [openspec/commands/explore.md](../../openspec/commands/explore.md)：本动作唯一职责、门禁、上下文与输出定义。
4. 仅第 3 项「上下文」段明确列出的文件。

## 执行边界

- 本文件只是路由入口，不复述、不扩充、不弱化规则；与上述文件冲突时一律以 `openspec/` 内文件为准。
- 按第 2 项的命令上下文类别取用业务上下文；本动作属于「会话与文件」类，允许使用与讨论主题相关的聊天历史。
- 路径只取自上述文档的明确链接或文件清单；不得由命令名猜测文件名，不得模糊匹配、自动纠错或按唯一活动 change 推断 change-id。
- 正式代码、执行制品和本地参考只作为事实与约束依据，不得把实现现状自动转成用户需求。
- 职责、门禁、共识判定与输出格式全部以第 3 项为准，不在本文件重复。
