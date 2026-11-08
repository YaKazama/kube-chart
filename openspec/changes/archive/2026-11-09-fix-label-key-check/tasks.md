# 标签键校验统一任务

## 实施

- [x] T1 `templates/base/_k8s.tpl`：在 `writable-scopes` 内把 `define "base.labelKey"` 的入参改为 `list [标签键, 调用方模板名, 调用方字段路径]`，校验入参形态后依次完成 `kindOf` string 门禁、`trim`、`splitList "/"`、段数判断、`mustRegexMatch` 搭配 `K8S.SELECTOR.KEY_NAME_FOR_APPS` 与 `K8S.SELECTOR.KEY_PREFIX_FOR_APPS`、前缀 253 字符上限，全部失败统一以 `[<模板名>] <字段路径>: <原因>` 形式 `fail`，移除对 `base.string.verify` 的调用，并更新紧邻契约注释；对应 `Decision: 统一入口与入参形态`、`Decision: 校验规则与消息集中实现`、`Decision: 校验规则来源保持不变`。
- [x] T2 `templates/api-resources/Definitions/_NodeSelectorTerm.tpl`：在 `writable-scopes` 内删除 `if not $skip` 块中的内联 `splitList "/"`、两处 `mustRegexMatch` 与 253 判断，改为 `include "base.labelKey" (list $key "definitions.nodeSelectorTerm" (printf "%s[%d].key" $_name $index))`，保留空 `key` 前置失败，并更新该字段注释；对应 `Decision: definitions.nodeSelectorTerm 收敛`。
- [x] T3 `templates/api-resources/Definitions/_LabelSelectorRequirement.tpl`：在 `writable-scopes` 内删除内联拆分、两处 `base.string.verify` 与 253 判断，改为由 `include "base.labelKey"` 产出 `$key`，并更新字段注释与整体契约注释中的消息前缀说明；对应 `Decision: definitions.labelSelectorRequirement 收敛`。
- [x] T4 `templates/api-resources/Definitions/_PodAffinityTerm.tpl`：在 `writable-scopes` 内为 `matchLabelKeys`、`mismatchLabelKeys` 的循环补项下标并向 `base.labelKey` 传入 `<字段名>[<下标>]` 字段路径，为 `topologyKey` 传入 `topologyKey` 字段路径，三处均传入 `definitions.podAffinityTerm`，并更新整体契约注释与字段注释中的消息前缀表述；对应 `Decision: definitions.podAffinityTerm 收敛`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart（装载真实 `templates/base/*.tpl`、`_NodeSelectorTerm.tpl`、`_NodeSelectorRequirement.tpl`、`_LabelSelector.tpl`、`_LabelSelectorRequirement.tpl`、`_PodAffinityTerm.tpl`）：为三个调用方分别提供无前缀、带前缀与带首尾空白的合法标签键，验证渲染成功且 `key` 与 `topologyKey` 输出为 `trim` 后的原值。
- [x] V2 `/tmp/` 最小 application Chart（真实依赖）：对 `definitions.nodeSelectorTerm` 构造 `a/b/c`、`-zone`、`Bad_Prefix/name`、64 字符名称段与非 string 输入，验证失败消息以 `[definitions.nodeSelectorTerm]` 开头、字段路径为 `matchExpressions[<下标>].key` 或 `matchFields[<下标>].key`，且不含 `[base.labelKey]` 与 `[base.string.verify]`。
- [x] V3 `/tmp/` 最小 application Chart（真实依赖）：对 `definitions.labelSelectorRequirement` 构造 `a/b/c`、`-zone`、`Bad_Prefix/name`、前缀超 253 字符与非 string 输入，验证失败消息以 `[definitions.labelSelectorRequirement]` 开头、字段路径为 `key`（含前缀超长场景），且不含 `[base.labelKey]` 与 `[base.string.verify]`。
- [x] V4 `/tmp/` 最小 application Chart（真实依赖）：对 `definitions.podAffinityTerm` 的 `topologyKey`、`matchLabelKeys`、`mismatchLabelKeys` 分别构造多斜杠、名称段非法、前缀段非法与非 string 输入，验证失败消息以 `[definitions.podAffinityTerm]` 开头、字段路径为 `topologyKey` 或 `<字段名>[<下标>]`，且不含 `[base.labelKey]` 与 `[base.string.verify]`。
- [x] V5 静态检查：`templates/` 下 `splitList "/"`、`K8S.SELECTOR.KEY_NAME_FOR_APPS`、`K8S.SELECTOR.KEY_PREFIX_FOR_APPS` 的校验用法仅出现在 `base.labelKey` 内（`templates/base/_env.tpl` 的常量定义除外）；四个写入文件无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、字段注释紧邻对应处理闭环、文件末尾单换行。
