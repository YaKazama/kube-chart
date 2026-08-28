# 规格规则

## 规格权威

- `openspec/changes/<change-id>/spec.md` 是当前 change 可观察行为的唯一权威；design、tasks 和正式代码不得新增、弱化或改写其行为。
- `spec.md` 只能从当前 draft 的明确意图派生，或由用户通过 `/opsx-spec-rewrite` 在当前命令中确认后修改；需求来源保护统一遵循 [`change-documents.md`](change-documents.md)。
- 当前代码不一致时修代码；用户明确改变行为契约时执行 `/opsx-spec-rewrite`。不得按现有代码静默反写规格。
- `openspec/specs/` 中已有的稳定能力规格不参与 OPSX 状态机或自动同步；只有 `/opsx-spec` 为解析 draft 中明确指向的既有能力确有需要时，才读取精确目标规格。
- `openspec/changes/archive/` 只保存历史，不参与当前契约判断。

## spec.md 结构

```markdown
---
status: spec
updated_at: "<UTC RFC 3339 时间>"
---

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

- 新行为放入 `## ADDED Requirements`。
- 修改行为放入 `## MODIFIED Requirements`，包含完整的新 Requirement 和全部 Scenario。
- 删除行为放入 `## REMOVED Requirements`，记录 `Reason` 和 `Migration`。
- 只改名使用 `## RENAMED Requirements`，以 `FROM:` 和 `TO:` 表达。
- 新能力包含 `## Purpose`；修改已有能力不重复 Purpose。
- Requirement 使用 MUST 或 SHALL，且至少包含一个 WHEN/THEN Scenario。
- 只描述输入、输出、默认值、类型、可观察行为、失败边界和非目标；用户意图明确要求委托既定能力时，可以记录该依赖边界及传入、返回的可观察契约，但不得写目标文件、基础函数选择、常量键、逐步实现、方案比较、任务或验证结论。
- 规则对既定需求形成的可观察行为或失败边界必须写入 Requirement；通用实现约束继续由工程规则直接约束 design 和代码。
- 没有可观察行为变化时使用 `## NO SPEC DELTA`，说明受影响能力和理由；不得同时包含 ADDED、MODIFIED、REMOVED 或 RENAMED。

## 受控回写

- `/opsx-spec-rewrite` 只接受 `status: code`，只把当前命令中用户明确确认的内容写入现有 Requirement、Scenario、非目标或失败边界。
- `/opsx-fix` 的上一轮摘要可以作为用户撰写确认内容的参考，但不能替代当前命令中的确认文本。
- 回写不得修改 Purpose、capability、design、tasks、代码边界或扩大 change；发生上述变化时停止，并建议新建 change。
- 回写后保持 `status: code`，更新 `updated_at`；不得修改 draft、design、tasks、正式代码或用户文档。
- 回写内容与当前规格冲突、存在多个合法表达、不能从用户确认唯一确定，或会使 design/tasks 失效时停止，不自行选择。
- `/opsx-review` 必须依据回写后的完整三制品契约重新核对当前已变更代码，不复用 fix 的判断。
