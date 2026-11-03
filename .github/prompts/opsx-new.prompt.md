---
description: "OPSX /opsx:new — 新建 change 目录与轻量 draft.md"
argument-hint: "<change-id>（kebab-case）"
agent: "agent"
---

执行 kube-chart 的 OPSX 动作 `/opsx:new`。

change-id：${input:changeId:输入 kebab-case 的 change-id}

## 读取顺序

必须按序读完以下三项，再读第 4 项：

1. [AGENTS.md](../../AGENTS.md)：项目基线、角色、上下文访问与规则路由。
2. [openspec/workflow.md](../../openspec/workflow.md)：动作模型、文件即状态、四向闭包、命令上下文类别。
3. [openspec/commands/new.md](../../openspec/commands/new.md)：本动作唯一职责、门禁、上下文与输出定义。
4. 仅第 3 项「上下文」段明确列出的文件，以及确认目标路径不存在所需的文件清单。

## 执行边界

- 本文件只是路由入口，不复述、不扩充、不弱化规则；与上述文件冲突时一律以 `openspec/` 内文件为准。
- 按第 2 项的命令上下文类别取用业务上下文；本动作属于「会话与文件」类，允许使用当前输入和与本 change 相关的聊天历史。
- 路径只取自上述文档的明确链接或文件清单；不得由命令名猜测文件名，不得模糊匹配、自动纠错或按唯一活动 change 推断 change-id。
- 不扫描其他 change、归档或 `openspec/specs/` 来补全意图。
- 职责、门禁、写入内容与输出格式全部以第 3 项为准，不在本文件重复。
