---
change-id: definitions-pod-anti-affinity
updated_at: "2026-11-09T04:34:03Z"
---

# PodAntiAffinity 模板

## 目标

- 新增核心模板 `definitions.podAntiAffinity`，渲染 PodAntiAffinity 字段片段。

## 需求

- 参照 `definitions.podAffinity` 实现，不是直接复用；`PodAntiAffinity` 与 `PodAffinity` 定义结构相同，因此允许以当前模板为准复制 `definitions.podAffinity` 的实现并改名。
- 复制后的模板名与私有辅助模板名统一改为 `definitions.podAntiAffinity` 前缀族（如 `definitions.podAntiAffinity.termList`）。
- 当前模板 `definitions.podAntiAffinity` 内的失败消息由当前模板自身管理，统一使用前缀 `[definitions.podAntiAffinity]`，不得沿用 `[definitions.podAffinity]`。
- 其他模板中的失败消息由各自模板独立管理；本层不捕获、不改写并原样传播这些消息。
- 子模板 `definitions.weightedPodAffinityTerm`、`definitions.podAffinityTerm` 保持不变并被继续委托，PodAntiAffinity 不新增术语子模板。
- 入参形态与 `definitions.podAffinity` 一致，包含 `preferredDuringSchedulingIgnoredDuringExecution`（WeightedPodAffinityTerm array）与 `requiredDuringSchedulingIgnoredDuringExecution`（PodAffinityTerm array）两个长键。
- `weight` 的 1-100 范围由子模板 `definitions.weightedPodAffinityTerm` 校验；本层只校验整数形态，取值超出范围时由该子模板中断渲染。
- 新模板及其私有辅助模板由独立文件承载，不得写入或扩充已归档 change 的 `_PodAffinity.tpl`。
- 独立文件名按一类型一文件约定为 `templates/api-resources/Definitions/_PodAntiAffinity.tpl`。

## 期望输入格式

- 与 `definitions.podAffinity` 相同：顶层只识别两个规范长键。
- 短键 `preferred`、`required` 已由父级 `definitions.affinity` 归一化，本层不再识别。

## 约束

- 不复用 `definitions.podAffinity` 的模板与同文件私有辅助模板：两者分属不同文件，类似情况的通用性有限，跨文件复用不受推荐。
- 新模板在当前 change 内独立实现，等价逻辑通过复制而非跨文件 include。
- 文件边界隔离：已归档 change 的制品文件保持原样，不改动、不追加。

## 非目标

- 不改变 `definitions.podAffinity` 对其现有调用方的可观察行为。
- 不为 `definitions.weightedPodAffinityTerm`、`definitions.podAffinityTerm` 增加 anti-affinity 变体。

## 验收

- `definitions.podAntiAffinity` 模板存在，可被父级 `definitions.affinity` 调用。
- 其取值、类型门禁、元素跳过与字段输出行为与 `definitions.podAffinity` 等价。
- 当前模板产生的失败消息前缀为 `[definitions.podAntiAffinity]`。
- 依赖层产生的失败消息保持各自模板前缀，不被本层改写。
- 未修改 `definitions.podAffinity` 及其私有辅助模板。
- 新模板与私有辅助模板位于独立文件，与 `_PodAffinity.tpl` 物理分离。
- 返回值为可嵌入 `podAntiAffinity` 下的字段片段，不含 `podAntiAffinity` 键本身。

## 开放问题

<!-- 暂无。 -->
