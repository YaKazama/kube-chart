# PodAffinity weightedPodAffinityTerm 上下文修正任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_PodAffinity.tpl`：在 `writable-scopes` 内 `update` `$fields` 字段表，为 `preferredDuringSchedulingIgnoredDuringExecution` 增加 `mode` 为 `weighted`、`requiredDuringSchedulingIgnoredDuringExecution` 增加 `mode` 为 `term`，并在整体契约注释中更新 preferred 字段的行为与边界描述；对应 `Decision: 字段表区分委托形态`。
- [x] T2 `templates/api-resources/Definitions/_PodAffinity.tpl`：在 `writable-scopes` 内实现 `mode` 为 `weighted` 的 `weight` 取值与校验：`base.get (list $_term "weight")` 保留默认别名、`trim` 后为空中断、`base.env` 的 `TYPES.INT` 直接匹配未剥离引号的原始文本、不匹配中断、通过后 `int64` 转换，失败消息含模板名、字段名与元素下标；对应 `Decision: weight 取值与整数校验`。
- [x] T3 `templates/api-resources/Definitions/_PodAffinity.tpl`：在 `writable-scopes` 内实现 `podAffinityTerm` 构造与合并：`mustDeepCopy` 元素、关闭别名读取 `podAffinityTerm`、`fromYaml` 与 `base.isFromYamlError` 保护、`kindIs "map"` 门禁、`unset` `weight`/`weightAlias`/`podAffinityTerm`、以已有 `podAffinityTerm`（缺失时为 `dict`）为 `mustMerge` 目标、合并后为空 map 时中断，最后以 `dict "weight" ... "podAffinityTerm" ...` 作为 `mode` 为 `weighted` 的委托上下文；对应 `Decision: podAffinityTerm 构造与合并优先级`、`Decision: podAffinityTerm 必填与非空归一`。
- [x] T4 `templates/api-resources/Definitions/_PodAffinity.tpl`：在 `writable-scopes` 内确认 `mode` 为 `term` 时元素原样透传与既有收集、错误保护、`base.field` 搭配 `base.slice` 输出逻辑保持一致，并按 `mode` 分派委托上下文；对应 `Decision: required 分支与输出不变`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart（`definitions.weightedPodAffinityTerm`、`definitions.podAffinityTerm` 为同名回显 fixture）：`preferredDuringSchedulingIgnoredDuringExecution` 单元素含 `weight: 11` 与 `topologyKey`，验证 fixture 收到的上下文只有 `weight` 与 `podAffinityTerm` 两键，且 `podAffinityTerm` 内含 `topologyKey`。
- [x] V2 `/tmp/` 最小 application Chart（fixture）：元素含 `weightAlias: 22`、`namespaceSelector`、`labelSelector`、`matchLabelKeys`、`namespaces`，验证 `weight` 取别名值、术语字段原样透传、`weightAlias` 不出现在 `podAffinityTerm` 下。
- [x] V3 `/tmp/` 最小 application Chart（fixture）：元素含 `podAffinityTerm` 且带有同名 `topologyKey`，验证冲突取 `podAffinityTerm` 内的值且层级不增加；再验证 `podAffinityTerm: {}` 与缺失但存在其他术语字段时均能正确合并。
- [x] V3b `/tmp/` 最小 application Chart（fixture）：元素只含 `weight`、以及只含 `weight` 与 `podAffinityTerm: {}`，验证两者均渲染中断且错误信息含 `podAffinityTerm` 与元素下标。
- [x] V4 `/tmp/` 最小 application Chart（fixture）：`weight` 为缺失、`null`、`""`、`"11"`、`1.5`、`true`、`{}`、`[]`，`podAffinityTerm` 为非 map，以及 fixture 返回非 YAML，逐一验证渲染中断且错误信息含 `[definitions.podAffinity]`、字段名与元素下标。
- [x] V5 `/tmp/` 最小 application Chart（fixture）：`requiredDuringSchedulingIgnoredDuringExecution` 元素仍原样传给 fixture；`weight` 取 200 时正常渲染，验证本层不做范围校验。
- [x] V6 静态检查：`templates/api-resources/Definitions/_PodAffinity.tpl` 无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、文件末尾单换行。
