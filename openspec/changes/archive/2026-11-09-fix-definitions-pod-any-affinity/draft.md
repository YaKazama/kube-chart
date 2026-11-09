---
change-id: fix-definitions-pod-any-affinity
updated_at: "2026-11-09T04:45:08Z"
---

# 修正 PodAffinity 与 PodAntiAffinity 二级模板的失败消息前缀

## 目标

- 修正 `definitions.podAffinity` 与 `definitions.podAntiAffinity` 两个文件下共 6 个二级模板的 `fail` 消息前缀，使每个二级模板使用自身模板名，不再沿用所属一级模板名。

## 需求

- 涉及文件：`templates/api-resources/Definitions/_PodAffinity.tpl`、`templates/api-resources/Definitions/_PodAntiAffinity.tpl`。
- 涉及二级模板，每个文件 3 个，共 6 个：
  - `definitions.podAffinity.termList`、`definitions.podAffinity.weightedTermList`、`definitions.podAffinity.weightedTerm`
  - `definitions.podAntiAffinity.termList`、`definitions.podAntiAffinity.weightedTermList`、`definitions.podAntiAffinity.weightedTerm`
- 每个二级模板的 `fail` 消息前缀改为该二级模板自身的完整模板名，例如 `[definitions.podAffinity.termList]`、`[definitions.podAntiAffinity.weightedTerm]`。
- 一级模板 `definitions.podAffinity` 与 `definitions.podAntiAffinity` 自身消息保持原前缀不变。
- 失败消息的其余内容（字段路径、元素下标、错误原因）保持原样。
- 消息前缀格式统一为 `[模板名] 字段路径: 错误原因`。

## 期望输入格式

<!-- 本次不涉及入参形态变化。 -->

## 约束

- 只修改失败消息前缀，不改变任何取值、类型门禁、元素跳过、委托或输出行为。
- 不修改其他模板，包括 `definitions.podAffinityTerm`、`definitions.weightedPodAffinityTerm`、`definitions.affinity` 与 `base.*`。

## 非目标

- 不改变 `definitions.podAffinity`、`definitions.podAntiAffinity` 的可观察输出行为。
- 不重构或合并 6 个二级模板的逻辑。
- 不新增或删除任何 `define`。
- 不修正依赖层 `base.*`、`definitions.podAffinityTerm`、`definitions.weightedPodAffinityTerm` 的失败消息。

## 验收

- 6 个二级模板的所有 `fail` 消息均以各自模板名作为前缀。
- 两个一级模板的 `fail` 消息前缀未被改动。
- 其他模板文件未被修改。
- 原有失败场景仍按原条件中断，仅前缀变化。

## 开放问题

<!-- 暂无。 -->
