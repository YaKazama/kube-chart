---
description: "[4/9] OPSX /opsx:code — 按已确认的三制品生成或局部修改代码"
argument-hint: "<change-id> [实现说明]"
agent: "agent"
---

执行 kube-chart 的 OPSX 动作 `/opsx:code`。

参数：${input:args:输入 <change-id>，可选追加实现说明}

## 读取顺序

必须按序读完以下三项，再读第 4 项：

1. [AGENTS.md](../../AGENTS.md)：项目基线、角色、上下文访问与规则路由。
2. [openspec/workflow.md](../../openspec/workflow.md)：动作模型、文件即状态、四向闭包、命令上下文类别。
3. [openspec/commands/code.md](../../openspec/commands/code.md)：本动作唯一职责、门禁、上下文与输出定义。
4. 仅第 3 项「上下文」段明确列出的文件，即当前 change 的三制品、`design.md` 代码边界列出的精确文件，以及按 write boundary 文件类型路由的工程规则。

## 执行边界

- 本文件只是路由入口，不复述、不扩充、不弱化规则；与上述文件冲突时一律以 `openspec/` 内文件为准。
- 按第 2 项的命令上下文类别取用业务上下文；本动作属于「会话与文件」类，聊天历史只用于理解和实施，不能替代制品。
- 路径只取自上述文档的明确链接或文件清单；不得由命令名猜测文件名，不得模糊匹配、自动纠错或按唯一活动 change 推断 change-id。
- 只修改 `design.md` 中 `access: write` 的文件和 writable scope；`access: read` 文件不得修改，不得沿相邻代码扩张边界。
- 三制品不完整、未确认或存在影响当前修改的歧义时按第 3 项门禁停止，并建议先执行 `/opsx:explore` 或 `/opsx:sync`。
- 职责、门禁、checkbox 规则与输出格式全部以第 3 项为准，不在本文件重复。
