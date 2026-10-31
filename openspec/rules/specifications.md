# 规格规则

## 规格权威

- `openspec/changes/<change-id>/spec.md` 是当前 change 可观察行为的唯一权威；design、tasks 和正式代码不得新增、弱化或改写其行为。
- `/opsx:spec` 只从当前 draft 的明确意图和适用工程规则生成或校对规格；`/opsx:sync` 只在用户确认预览差异后按代码、测试和既有文档事实同步规格。来源保护统一遵循 [`change-documents.md`](change-documents.md)。
- 代码事实与当前规格不一致时，`/opsx:code` 必须报告影响；是实现偏差时修代码，是用户接受的行为变化时通过 `/opsx:sync` 受控同步，不得静默反写。
- `openspec/specs/` 中已有的稳定能力规格不参与 change 状态判断或自动同步；只有当前动作解析明确涉及的既有能力时，才读取精确目标规格。
- `openspec/changes/archive/` 保存历史，不参与活动执行契约判断；`/opsx:docs` 与 `/opsx:ck:publish` 可以按各自职责读取。

## spec.md 结构

```markdown
# <变更名称>规格

## Purpose

<仅为新增能力填写目的；修改已有能力时删除本节。>

## ADDED Requirements

### Requirement: <名称>

系统 MUST <可观察行为>。

#### Scenario: <场景名称>

- **WHEN** <条件或动作>
- **THEN** <可观察结果>

## 非目标

- <不属于本 change 的行为>
```

- 在上述正文前添加 [`change-documents.md`](change-documents.md) 唯一定义的 spec frontmatter。
- 新行为放入 `## ADDED Requirements`。
- 修改行为放入 `## MODIFIED Requirements`，包含完整的新 Requirement 和全部 Scenario。
- 删除行为放入 `## REMOVED Requirements`，记录 `Reason` 和 `Migration`。
- 只改名使用 `## RENAMED Requirements`，以 `FROM:` 和 `TO:` 表达。
- 新能力包含 `## Purpose`；修改已有能力不重复 Purpose。
- Requirement 使用 MUST 或 SHALL，且至少包含一个 WHEN/THEN Scenario。
- 只描述输入、输出、默认值、类型、可观察行为、失败边界和非目标；用户意图明确要求委托既定能力时，可以记录该依赖边界及传入、返回的可观察契约，但不得写目标文件、基础函数选择、常量键、逐步实现、方案比较、任务或验证结论。
- 规则对既定需求形成的可观察行为或失败边界必须写入 Requirement；通用实现约束继续由工程规则直接约束 design 和代码。
- 没有可观察行为变化时使用 `## NO SPEC DELTA`，说明受影响能力和理由；不得同时包含 ADDED、MODIFIED、REMOVED 或 RENAMED。

## 重复校对与同步

- `/opsx:spec` 发现现有 spec 时逐项比较 draft、现有 spec、design 和 tasks：保留仍有效内容，只更新、补全或删除有明确依据的部分，并输出实际差异和冲突。
- `/opsx:spec` 不得从聊天历史、代码便利性或 AI 建议生成 Requirement；影响行为的开放问题未关闭时，不得把执行契约标记为已确认。
- `/opsx:sync` 必须把代码事实与用户可见行为区分开。重构、内部类型、格式和等价实现通常只更新 design 或 tasks；输入、输出、默认值、失败边界、Scenario 或非目标变化才建议更新 spec。
- `/opsx:sync` 不得把偶然实现、bug、临时兼容、测试 fixture、未使用分支或无法证明稳定性的代码写入规格。
- 同步内容与 draft 或现有规格冲突、存在多个合法表达、不能从当前确认唯一确定，或无法与 design/tasks 闭包时停止冲突项，不自行选择。
