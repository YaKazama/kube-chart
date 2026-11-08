---
change-id: fix-definitions-affinity
updated_at: "2026-11-08T16:25:53Z"
---

# affinity 子模板改为逐字段直白写法

## 目标

- 把 affinity 链中「先定义 list 字段表、再 `range` 派发」的写法改为逐字段直白写法，使每个字段的取值、归一化与渲染在同一处完整可读，不再依赖 `kind` / `template` / `mode` 之类的间接路由。

## 需求

- affinity 链的每个子模板 MUST 按字段顺序逐块书写，每块自成“取值 → 解析 → 错误保护或类型门禁 → 归一化 → `base.field` 渲染”闭环，不再以字段表加 `range` 的方式派发。
- 改造 MUST NOT 改变任何可观察行为：渲染结果、字段顺序、别名识别、空值跳过、去重去空与失败消息 MUST 全部保持当前一致。
- 已按扫描确认存在「先定义 list 再 `range` 派发」的 affinity 链模板：
  - `templates/api-resources/Definitions/_Affinity.tpl`：`$substructures`（`kind` / `template` 字段表）与 `$keyPairs`（短键与长键配对表），均在 `range` 中派发。
  - `templates/api-resources/Definitions/_NodeAffinity.tpl`：`$fields`（`kind` / `template` / `mode` 字段表）在 `range` 中派发；另有 `range $_name := list "matchExpressions" "matchFields"` 以字段名列表派发。
  - `templates/api-resources/Definitions/_PodAffinity.tpl`：`$fields`（`kind` / `template` / `mode` 字段表）在 `range` 中派发。
  - `templates/api-resources/Definitions/_NodeSelectorTerm.tpl`：`$names := list "matchExpressions" "matchFields"` 在 `range` 中派发。
- 已按扫描确认不含该写法、本次不改动的 affinity 链模板：`_PodAffinityTerm.tpl`（已是逐字段直白写法）、`_PreferredSchedulingTerm.tpl`、`_WeightedPodAffinityTerm.tpl`。
- 已按扫描确认属于累加用途、不是派发表的 `list` 变量，MUST NOT 因本条要求被消除：`_NodeAffinity.tpl` 的 `$terms`、`$rendered`，`_PodAffinity.tpl` 的 `$rendered`，`_NodeSelectorTerm.tpl` 的 `$requirements`、`$values`、`$rendered`，`_PodAffinityTerm.tpl` 的 `$matchLabelKeys`、`$mismatchLabelKeys`、`$namespaces`。
- 逐字段展开后产生的重复片段 MUST 在同一文件内新增辅助命名模板统一处理；辅助模板 MUST 使用所属文件主能力前缀，MUST NOT 跨文件抽取为 `base.*` 或其他文件的能力，MUST NOT 引入字段表或字段名列表作为派发源。
- 已知会因逐字段展开产生的重复片段：
  - `_Affinity.tpl`：三段子结构各自的“短键优先、空短键回退长键、双空不写入”归一化逻辑。
  - `_NodeAffinity.tpl`：preferred 与 required 两段各自的 `matchExpressions` / `matchFields` 归一化逻辑。
  - `_NodeSelectorTerm.tpl`：`matchExpressions` 与 `matchFields` 各自的条目归一化与校验逻辑。
  - `_PodAffinity.tpl`：两段的数组元素遍历与 `base.field` 输出骨架。
- 校验以改造前的原内容为准：行为基准取自已归档 change `openspec/changes/archive/2026-11-07-definitions-affinity/` 的规格与验收，重构后的渲染结果、取值优先级与失败边界 MUST 与之保持一致。
- 同链其他已归档 change（`2026-11-08-definitions-node-affinity`、`2026-11-08-definitions-pod-affinity`、`2026-11-08-definitions-node-selector-term` 等）可作为 `definitions.nodeAffinity`、`definitions.podAffinity`、`definitions.nodeSelectorTerm` 的补充行为基准。

## 期望输入格式

<!-- 本次不涉及用户输入格式变化。 -->

## 约束

- 本次是纯内部重构，MUST NOT 修改任何模板的入参、返回值、字段输出顺序与失败边界。
- MUST NOT 修改 `templates/base/` 下的公共模板。
- MUST NOT 修改 `_env.tpl` 常量、`base.labelKey` 调用契约或任何依赖模板的调用形式。
- 逐字段展开后如出现重复片段，MUST 在同一文件内新增辅助命名模板统一处理；调用点仍为每个字段一处显式 `include`，MUST NOT 把字段名或字段描述作为表后 `range` 派发。

## 非目标

- 不改变 affinity 链的任何用户可见行为。
- 不改造 `_PodAffinityTerm.tpl`、`_PreferredSchedulingTerm.tpl`、`_WeightedPodAffinityTerm.tpl`。
- 不处理 `definitions.preferredSchedulingTerm` 的 `preference` 必填性调整。
- 不处理 `nodeAffinity`、`podAffinity`、`podAntiAffinity` 的 map 类型兼容。

## 验收

- 四个改造文件中不再存在以字段表或字段名列表 `range` 派发的写法。
- 重复片段已由同文件内新增的辅助命名模板统一处理，MUST NOT 在逐字段语句块中留下未归一的相同逻辑副本。
- 改造前后对同一组输入的渲染结果完全一致，包括字段顺序与去重去空结果，并以 `openspec/changes/archive/2026-11-07-definitions-affinity/` 规格与验收作为行为基准。
- 改造前后对同一组非法输入的失败消息完全一致，包括模板名前缀、字段路径与原因。

## 开放问题

<!-- 暂无。 -->
