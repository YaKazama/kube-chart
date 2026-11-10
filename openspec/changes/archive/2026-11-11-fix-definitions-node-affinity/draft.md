---
change-id: fix-definitions-node-affinity
updated_at: "2026-11-10T16:41:01Z"
---

# 修复 nodeAffinity weight 的父级类型门禁

## 目标

- 移除 `templates/api-resources/Definitions/_NodeAffinity.tpl` 中 `preferredDuringSchedulingIgnoredDuringExecution` 条目 `weight` 的父级类型门禁，改由 `definitions.preferredSchedulingTerm` 的 `base.int` 统一收口。
- 消除父级与子模板对同一取值重复做的形态校验。

## 需求

- 只处理 `preferredDuringSchedulingIgnoredDuringExecution` 条目中 `weight` 的取值、门禁与向子模板传递方式。
- 删除父级的 `fromYaml (printf "v: %s" ...)` 单值解码、`base.isFromYamlError` 检查与 `kindIs "map"`、`kindIs "slice"` 两个分支，把 `base.get` 的原始文本直接作为 `weight` 传给 `definitions.preferredSchedulingTerm`。
- 保留父级的存在性判断：`weight` 缺失、YAML null 或空字符串在本层中断。
- 保留 1 - 100 的取值校验由 `definitions.preferredSchedulingTerm` 承担。
- 接受 `weight: "50"` 由可用变为中断：删除解码后该值作为带引号文本进入子模板，被 `base.int` 拒绝。
- 失败消息由实际触发校验的模板持有，不再要求父级消息包含 `preferredDuringSchedulingIgnoredDuringExecution[<index>].weight`。
- 不改变 `preferredDuringSchedulingIgnoredDuringExecution` 与 `requiredDuringSchedulingIgnoredDuringExecution` 之外任何字段的输出。

## 期望输入格式

<!-- 只填写用户明确指定的本次特殊限制。 -->

## 约束

- 只修改 `templates/api-resources/Definitions/_NodeAffinity.tpl`。
- 仅使用 Helm 内置函数、Go Template、Sprig 与 Helm 特有函数。
- `weight` 的接受范围改为：原生整数、int64 与整数值浮点（如 `50`、`50.0`）继续可用；纯数字字符串（如 `"50"`）由可用变为中断。
- 非标量输入的失败消息前缀会由 `[definitions.nodeAffinity]` 变为 `[base.get]` 或 `[base.int]`，该变化已确认接受。

## 非目标

- 不修改 `definitions.preferredSchedulingTerm` 与 `definitions.weightedPodAffinityTerm` 的 `weight` 处理。
- 不修改 `requiredDuringSchedulingIgnoredDuringExecution` 分支与 `definitions.nodeAffinity.matchList` 辅助模板。
- 不处理 `definitions.nodeSelector` 在其他模板中的引用问题。
- 不新增或修改任何 `base.*` 公共能力模板。

## 验收

- 文件中不再出现 `fromYaml (printf "v: %s" ...)` 单值解码、`base.isFromYamlError` 检查与 `kindIs "map"`、`kindIs "slice"` 的 `weight` 分支。
- `weight` 为 `50`、`50.0` 或 int64 的 `50` 时输出 `weight: 50`。
- `weight: "50"` 中断渲染，消息前缀为 `[base.int]`。
- `weight` 缺失、为 `null`、为空字符串时在本层中断，消息包含 `weight`。
- `weight` 为 `{}`、`[]`、`{a: b}`、`[1, 2]`、`abc`、`1.5`、`true` 时中断渲染，消息前缀为 `[base.int]`。
- `weight` 为 `0` 或 `101` 时中断于 `base.int.range` 的 `1 - 100` 区间。
- 其余 affinity 字段的渲染结果与改造前一致。

## 开放问题

<!-- 当前无开放问题。 -->
