---
change-id: fix-definitions-preferred-scheduling-term
updated_at: "2026-11-08T17:11:32Z"
---

# PreferredSchedulingTerm 的 preference 改为必填

## 目标

- 把 `definitions.preferredSchedulingTerm` 的 `preference` 从可选字段改为必填字段，使其与 Kubernetes `PreferredSchedulingTerm` 中 `preference` 为必填的语义一致。
- 同步调整 `definitions.nodeAffinity`，使 preferred 元素在未提供 `matchExpressions` 与 `matchFields` 时于该层中断，而不是向 `definitions.preferredSchedulingTerm` 传递空 `preference`。

## 需求

- `preference` MUST 为必填字段。
- `preference` 缺失、为 `null`、为空字符串或为空 map 时 MUST 中断渲染。
- `preference` 的必填校验 MUST 复用既有必填取值能力；必填失败消息保留该能力自身的消息前缀，与 `weight` 的必填失败形式一致，本模板 MUST NOT 重复实现必填判定或另造同义的必填失败消息。
- `preference` 取值不是 map 时 MUST 中断渲染。
- `preference` 委托 `definitions.nodeSelectorTerm`，其返回值为空或无法解析为 map 时 MUST 中断渲染。
- `preference` 校验通过时 MUST 以 `preference` 键输出，且 MUST 位于 `weight` 之后。
- `weight` 的既有行为 MUST NOT 变化：仍为必填 integer，1 - 100 闭区间，失败边界与消息保持不变。
- `weightAlias`、`preferenceAlias` 的隐式别名识别 MUST 保持不变。
- 本模板 MUST NOT 解析 `preference` 内部的 `matchExpressions`、`matchFields` 及其字符串简写，内部结构仍由 `definitions.nodeSelectorTerm` 负责。
- `definitions.nodeAffinity` 的 preferred 元素 MUST 在 `matchExpressions` 与 `matchFields` 归一化后均为空时中断渲染，MUST NOT 向 `definitions.preferredSchedulingTerm` 传递空 `preference`。
- `definitions.nodeAffinity` 的其余行为 MUST NOT 变化：两个规范长键只识别长键并关闭同级别名、元素必须为 map、`weight` 只校验存在性与标量形态、required 分支包裹 `nodeSelectorTerms` 后委托 `definitions.nodeSelector`、输出顺序与失败消息前缀保持不变。

## 期望输入格式

<!-- 本次不涉及用户输入格式变化。 -->

## 约束

- 修改 `templates/api-resources/Definitions/_PreferredSchedulingTerm.tpl` 与 `templates/api-resources/Definitions/_NodeAffinity.tpl`，MUST NOT 修改 `templates/base/` 或其他 Definitions 模板。
- 失败消息按产出方归属：必填校验复用既有必填取值能力并保留其消息前缀；类型判定与子模板边界的失败使用本模板名前缀与精确字段路径；`definitions.nodeAffinity` 的新增失败 MUST 包含所属字段名与元素下标。
- 除 `preference` 的必填性外，MUST NOT 改变字段顺序、别名识别、其他字段的取值与渲染方式。

## 非目标

- 不改变 `weight` 的校验规则、取值范围与失败边界。
- 不改变 `definitions.nodeSelectorTerm` 的入参契约与内部行为。
- 不处理 `nodeAffinity`、`podAffinity`、`podAntiAffinity` 的 map 类型兼容。

## 验收

- 同时提供合法 `weight` 与非空 `preference` 时，输出依次包含 `weight` 与 `preference`。
- 只提供 `weight` 时，渲染中断并返回错误。
- `preference` 为 `null`、空字符串、空 map、字符串或 list 时，渲染中断并返回错误。
- `preference` 的必填失败消息来自既有必填取值能力，字符串与 list 的失败消息使用 `[definitions.preferredSchedulingTerm]` 前缀。
- `preference` 委托 `definitions.nodeSelectorTerm` 返回空内容或非法 YAML 时，渲染中断并返回错误。
- `weight` 缺失、非整数或越界时，渲染行为与改造前一致。
- `definitions.nodeAffinity` 的 preferred 元素只含 `weight`、不含有效 `matchExpressions` 与 `matchFields` 时，在该层中断且错误信息含字段路径与元素下标。
- `definitions.nodeAffinity` 的其余行为（长键识别、元素类型、`weight` 校验、required 包裹、输出顺序）与改造前一致。

## 开放问题

<!-- 暂无。 -->
