---
description: "[3/9] OPSX /opsx:spec — 创建或校对 spec/design/tasks 并做四向闭包检查"
argument-hint: "<change-id> [--confirm]"
agent: "agent"
---

执行 kube-chart 的 OPSX 动作 `/opsx:spec`。

参数：${input:args:输入 <change-id>，需要确认当前三制品组合时追加 --confirm}

## 读取顺序

必须按序读完以下三项，再读第 4 项：

1. [AGENTS.md](../../AGENTS.md)：项目基线、角色、上下文访问与规则路由。
2. [openspec/workflow.md](../../openspec/workflow.md)：动作模型、文件即状态、四向闭包、命令上下文类别。
3. [openspec/commands/spec.md](../../openspec/commands/spec.md)：本动作唯一职责、门禁、重复执行、确认与输出定义。
4. 仅第 3 项「上下文」段明确列出的文件。

## 执行边界

- 本文件只是路由入口，不复述、不扩充、不弱化规则；与上述文件冲突时一律以 `openspec/` 内文件为准。
- 按第 2 项的命令上下文类别取用业务上下文；本动作属于「仅文件」类，不得把本轮聊天历史作为业务依据，必须从允许的当前文件重新建立事实。
- 路径只取自上述文档的明确链接或文件清单；不得由命令名猜测文件名，不得模糊匹配、自动纠错或按唯一活动 change 推断 change-id。
- 已有制品必须逐项对比后再更新或补全，不得整文件盲目重写；无法闭包时保持可验证内容并报告缺口。
- 不得用 AI 推断覆盖冲突项，不得在 `--confirm` 时携带新的行为或设计内容。
- 职责、门禁、闭包判据与输出格式全部以第 3 项为准，不在本文件重复。
