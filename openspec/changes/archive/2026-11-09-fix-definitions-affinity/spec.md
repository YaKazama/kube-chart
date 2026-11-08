---
updated_at: "2026-11-08T16:47:45Z"
---

# affinity 子模板写法重构规格

## NO SPEC DELTA

本 change 为纯内部实现重构，不改变任何用户可见行为，因此不产生规格增量。

受影响能力及其行为来源：

- `definitions.affinity`：行为基准为 `openspec/changes/archive/2026-11-07-definitions-affinity/spec.md`；重构后渲染结果、短键归一化优先级、字段丢弃规则、输出顺序、失败消息（含 `[definitions.affinity]` 前缀与字段路径）MUST 与之逐条一致。
- `definitions.nodeAffinity`：行为基准为 `openspec/changes/archive/2026-11-08-definitions-node-affinity/spec.md`。
- `definitions.podAffinity`：行为基准为 `openspec/changes/archive/2026-11-08-definitions-pod-affinity/spec.md` 与 `openspec/changes/archive/2026-11-08-fix-definitions-pod-affinity/spec.md`。
- `definitions.nodeSelectorTerm`：行为基准为 `openspec/changes/archive/2026-11-08-definitions-node-selector-term/spec.md`；其 `key` 校验已由 `base.labelKey` 承担，行为基准不变。

重构范围仅限把「先定义 list 字段表或字段名列表、再 `range` 派发」改写为逐字段直白书写。四个模板的入参、返回值、字段顺序、别名识别、空值跳过、去重去空、失败消息文本与失败时机 MUST 保持完全不变。

不新增、修改或删除任何 Requirement、Scenario、默认值、失败边界或非目标。
