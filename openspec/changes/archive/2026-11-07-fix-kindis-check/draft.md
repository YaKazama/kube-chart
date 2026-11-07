---
change-id: fix-kindis-check
updated_at: "2026-11-07T10:13:12Z"
---

# 修正 YAML 恢复后重复的 kindIs 类型检查

## 目标

- 检查 `templates/` 目录下全部 `*.tpl` 文件，修正 `base.isFromYamlError` 与 `base.isFromYamlArrayError` 之后仍然对同一恢复结果做 `kindIs` 重复检查的写法。

## 需求

- 范围限定为 `templates/` 目录下的 `*.tpl` 文件，不包含 `openspec/`、`docs/`、根 `README.md` 和样例目录。
- 只修正 `fromYaml` 或 `fromYamlArray` 结果已被 `base.isFromYamlError` 或 `base.isFromYamlArrayError` 排除解析错误、随后又对同一变量做 `kindIs "map"` 或 `kindIs "slice"` 判断的写法。
- 修正时保持既有可观察行为不变：字段生效条件、失败边界、错误消息文本、输出字段与顺序均不改动。
- 仅删除多余的类型判断，不改变其余条件、分支结构或变量命名。
- 保留 `kindIs` 用于多类型输入分支选择、判断未经 YAML 恢复的原始元素（如数组元素、字符串简写项），以及 `include` 结果不经过错误 helper 的其他场景。
- 已确认的排查范围与结果：`templates/` 下共 18 个 `*.tpl`、58 处 `base.isFromYamlError`/`base.isFromYamlArrayError` 调用；错误 helper 之后对同一恢复结果再做同类 `kindIs` 的写法共 3 处需修正，分布在以下两个文件。
- 修正范围一：`templates/api-resources/Apps/_DeploymentSpec.tpl` 的 `strategy` 分支，`$_strategyIsError` 已由错误 helper 得出，其后的 `(kindIs "map" $_strategyParsed)` 属于重复判断，应予删除。
- 修正范围二：`templates/base/_k8s.tpl` 第 334 行与第 344 行，`eq (include "base.isFromYamlError" ...) "false"` 之后仍判断 `kindIs "map"`，属于同类重复判断，**已确认纳入本次修正范围**。
- `templates/base/_k8s.tpl` 的修正只删除与错误 helper 同义的 `kindIs "map"`，保留原有的非空判断与错误 helper 判定；`base.labels` 的可观察输出 MUST 保持不变。
- 同文件 `rollingUpdate` 分支的 `(not (kindIs "map" $strategyRollingUpdate))` 与错误 helper 同处一个 `or` 条件并共同 `fail`，属于单一 map 目标类型的类型门禁，不在本次删除范围。
- `templates/api-resources/Core/_PodSpec.tpl` 的 `os` 分支中 `kindIs "map"` 位于 `else if`，用于在 string 与 map 两种输入间选择归一化分支，不是错误 helper 之后的重复判断，保持不动。
- `templates/base/_get.tpl` 的 `kindIs "string"` 分支处理的是 `fromYaml` 后的标量空值判定；该模板自身是对外能力实现，不在本次模板消费方修正范围内。
- `templates/base/_k8s.tpl` 的 `labels` 与 `helmLabels` 分支已转入修正范围，见上方「修正范围二」。
- `templates/api-resources/Definitions/_LabelSelector.tpl` 与 `_ObjectMeta.tpl` 的 `kindIs "string"` 遍历的是 map 的**值**，属于元素类型校验，不是恢复结果类型判断，不在修正范围。
- 遵循 [`../../rules/core-capabilities.md`](../../rules/core-capabilities.md) 的 YAML 解析保护与 `kindIs` 使用规则。

## 期望输入格式

<!-- 只填写用户明确指定的本次特殊限制。 -->

## 约束

- 只修改 `templates/` 下的 `*.tpl` 模板代码；不修改 `openspec/`、`docs/`、根 `README.md`、`values.yaml` 和样例。
- 允许修改的文件限定为 `templates/api-resources/Apps/_DeploymentSpec.tpl` 与 `templates/base/_k8s.tpl`；不得由此扩大修改其他文件。
- 不新增、重命名或删除命名模板；不改变任何 `define` 名称与调用契约。
- 不重构与本次无关的重复代码，不合并字段处理逻辑。
- 修改后每个文件保持单末尾换行且不引入冲突标记。

## 非目标

- 不改变 `base.isFromYamlError`、`base.isFromYamlArrayError`、`fromYaml`、`fromYamlArray` 的能力或实现。
- 不调整 `base.env` 常量、`base.get` 取值语义与 `base.field` 渲染行为。
- 不修正与重复 `kindIs` 无关的其他代码风格问题。
- 不对整 Chart 执行 `helm lint` 或发布检查。

## 验收

- `templates/` 下不再存在「错误 helper 之后紧跟同一变量的同类 `kindIs` 判断」的写法，包括 `_DeploymentSpec.tpl` 的 1 处与 `_k8s.tpl` 的 2 处。
- 每个被修改字段的取值、生效条件、失败消息与输出结果与修改前一致。
- `base.labels` 在自定义标签、仅 `helmLabels`、两者同时存在与非 map 输入四种情形下的输出与修改前完全一致。
- 相关模板在 `/tmp/` 最小 application Chart 中的渲染结果与修改前一致。
- 修改文件数与逐文件改动位置在会话报告中逐项列出。

## 开放问题

- 已关闭：全量排查确认不存在其他需要一并处理的多类型输入场景；删除 `_DeploymentSpec.tpl` 的 1 处重复 `kindIs` 不会使其失去保护，因为 `$_strategyIsError` 已等价覆盖该判断，且 `else` 分支继续处理字符串简写。
- 已关闭：`templates/base/_k8s.tpl` 第 334 行与第 344 行的两处重复判断已确认纳入本次修正范围，写入需求「修正范围二」，不再是待确认事项。
