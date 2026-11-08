---
change-id: fix-label-key-check
updated_at: "2026-11-08T16:08:52Z"
---

# 标签键校验统一到 base.labelKey

## 目标

- 项目内所有 Kubernetes 标签键校验统一复用公共模板 `base.labelKey`，不再在各 Definitions 模板内重复实现拆分、段校验与前缀长度判断。

## 需求

- 凡需要对标签键做语法校验的模板，一律通过 `base.labelKey` 完成，不再内联 `splitList "/"`、`KEY_NAME_FOR_APPS`、`KEY_PREFIX_FOR_APPS` 或 253 字符前缀上限判断。
- `base.labelKey` 是标签键语法的唯一实现来源；其校验规则不变。
- 标签键语法校验失败的错误消息，其模板名前缀以发生校验的调用方模板为准，不得出现 `[base.labelKey]` 或 `[base.string.verify]` 前缀；字段路径与原因格式保持不变。
- 已按 `templates/` 全量扫描确认需要改造的标签键校验实现：
  - `templates/api-resources/Definitions/_NodeSelectorTerm.tpl` 第 140-155 行：`definitions.nodeSelectorTerm` 内联 `splitList "/"`、`mustRegexMatch` 校验 `KEY_NAME_FOR_APPS` / `KEY_PREFIX_FOR_APPS`、`253` 长度判断，并以 `[definitions.nodeSelectorTerm] %s[%d].key` 自行 `fail`。
  - `templates/api-resources/Definitions/_LabelSelectorRequirement.tpl` 第 39-50 行：`definitions.labelSelectorRequirement` 内联 `splitList "/"`、以 `include "base.string.verify"` 校验名称段与前缀段、`253` 长度判断，并以 `[definitions.labelSelectorRequirement] key` / `key.prefix` 自行 `fail`。
  - `templates/api-resources/Definitions/_PodAffinityTerm.tpl` 第 67、84、134 行：`definitions.podAffinityTerm` 已调用 `base.labelKey`，但标签键失败时前缀为 `[base.labelKey]` 或 `[base.string.verify]`，需改为自身模板名与字段路径。
  - `templates/base/_k8s.tpl` 第 256-278 行的 `base.labelKey` 需能表达调用方消息前缀，并自行产生名称段与前缀段校验失败消息，不再经由 `base.string.verify`。
- 已按全量扫描确认不在本次改造范围、且当前不含标签键语法校验的实现：`_LabelSelector.tpl`（只校验 key 非空与 string 类型，语法委托 `definitions.labelSelectorRequirement`）、`_NodeSelectorRequirement.tpl`（`key` 可为 `matchFields` 的字段路径，不做标签键语法校验）、`_ObjectMeta.tpl`（`labels` 委托 `base.labels`，不校验键语法）、`_Affinity.tpl`、`_NodeAffinity.tpl`、`_PodAffinity.tpl`、`_PreferredSchedulingTerm.tpl`、`_WeightedPodAffinityTerm.tpl`、`api-resources/Apps/*`、`api-resources/Core/*` 以及 `base/` 下其余文件。

## 期望输入格式

<!-- 本次不涉及用户输入格式变化。 -->

## 约束

- 不修改 `base.labelKey` 的校验规则与返回值语义：仍返回 `trim` 后且校验通过的标签键字符串。
- 为满足错误前缀要求，`base.labelKey` 的入参形态允许扩展以携带调用方模板名与字段路径；具体入参形态由 design 决定。
- 不修改 `_env.tpl` 中的 `KEY_NAME_FOR_APPS`、`KEY_PREFIX_FOR_APPS` 常量；`base.labelKey` 继续使用这两个常量。
- 只替换标签键校验实现，不改变各模板的字段取值、必填性、输出顺序与渲染方式。
- 错误消息沿用 `[模板名] 字段路径: 错误原因` 格式。

## 非目标

- 不新增标签键校验能力。
- 不为 `_ObjectMeta.tpl` 的 `labels` 增加键语法校验。
- 不为 `_NodeSelectorRequirement.tpl` 的 `key` 增加标签键语法校验。
- 不调整 `base.labelKey` 已定义的四类失败边界（类型、多斜杠、名称段、前缀段与前缀长度）。
- 不处理本条之外的模板重构、字段必填性调整或 map 类型兼容。

## 验收

- `templates/` 下除 `base.labelKey` 自身外，不再出现 `splitList "/"` 与 `K8S.SELECTOR.KEY_NAME_FOR_APPS` / `K8S.SELECTOR.KEY_PREFIX_FOR_APPS` 的校验用法。
- `definitions.nodeSelectorTerm`、`definitions.labelSelectorRequirement`、`definitions.podAffinityTerm` 在合法标签键下的渲染结果与改造前一致。
- 非法标签键（多斜杠、名称段非法、前缀段非法、前缀超长）仍中断渲染，且错误消息前缀为发生校验的调用方模板名，不出现 `[base.labelKey]` 或 `[base.string.verify]`。

## 开放问题

<!-- 暂无。 -->
