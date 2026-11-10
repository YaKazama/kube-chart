---
updated_at: "2026-11-10T16:41:34Z"
---

# nodeAffinity weight 类型门禁收敛规格

## MODIFIED Requirements

### Requirement: 校验 preferredDuringSchedulingIgnoredDuringExecution 的 weight

`definitions.nodeAffinity` MUST 要求 `preferredDuringSchedulingIgnoredDuringExecution` 每个条目包含 `weight`。

`weight` 缺失、为 YAML `null` 或为空字符串时 MUST 在 `definitions.nodeAffinity` 层中断渲染，失败消息 MUST 包含 `weight`。

`weight` MUST NOT 由 `definitions.nodeAffinity` 判定标量形态或数值范围。标量形态与 1 - 100 闭区间 MUST 由 `definitions.preferredSchedulingTerm` 校验。

`weight` 为原生整数、int64 或整数值浮点时 MUST 输出对应整数，包含 `50`、`50.0` 与 int64 的 `50`。

`weight` 为纯数字字符串（如 `"50"`）时 MUST 中断渲染。

`weight` 为空 map、空 list、非空 map、非空 list、非数字字符串、带非零小数部分的浮点或布尔值时 MUST 中断渲染。

`weight` 为 `0`、负数或大于 `100` 的整数时 MUST 中断渲染。

上述形态与范围失败消息 MUST 由实际触发校验的能力产出，`definitions.nodeAffinity` MUST NOT 追加自身前缀或字段路径。

#### Scenario: 原生整数通过

- **WHEN** 条目提供 `weight: 50`
- **THEN** 输出包含 `weight: 50`

#### Scenario: int64 通过

- **WHEN** 条目以 int64 传入 `weight: 50`
- **THEN** 输出包含 `weight: 50`

#### Scenario: 整数值浮点通过

- **WHEN** 条目提供 `weight: 50.0`
- **THEN** 输出包含 `weight: 50`

#### Scenario: 纯数字字符串中断

- **WHEN** 条目提供 `weight: "50"`
- **THEN** 渲染中断，失败消息以 `[base.int]` 开头

#### Scenario: weight 缺失

- **WHEN** 条目不含 `weight`，或 `weight` 为 YAML `null`、空字符串
- **THEN** 渲染中断，失败消息包含 `weight`

#### Scenario: 空集合中断

- **WHEN** 条目提供 `weight: {}` 或 `weight: []`
- **THEN** 渲染中断，失败消息由实际校验能力产出，不以 `[definitions.nodeAffinity]` 开头

#### Scenario: 非空集合中断

- **WHEN** 条目提供 `weight: {a: b}` 或 `weight: [1, 2]`
- **THEN** 渲染中断，失败消息以 `[base.int]` 开头

#### Scenario: 非数字文本与浮点中断

- **WHEN** 条目提供 `weight: abc`、`weight: 1.5` 或 `weight: true`
- **THEN** 渲染中断，失败消息以 `[base.int]` 开头

#### Scenario: 超出 1 - 100 中断

- **WHEN** 条目提供 `weight: 0`、`weight: -1` 或 `weight: 101`
- **THEN** 渲染中断，失败消息以 `[base.int.range]` 开头

## 非目标

- 不修改 `definitions.preferredSchedulingTerm` 与 `definitions.weightedPodAffinityTerm` 的 `weight` 处理。
- 不修改 `definitions.nodeAffinity` 的 `requiredDuringSchedulingIgnoredDuringExecution` 分支。
- 不修改 `definitions.nodeAffinity.matchList` 辅助模板。
- 不处理 `definitions.nodeSelector` 在仓库中缺失的问题；该缺口不影响本 Requirement 的 `preferredDuringSchedulingIgnoredDuringExecution` 分支。
- 不新增或修改任何 `base.*` 能力模板，也不改变 `base.int`、`base.int.range` 的接受范围。
