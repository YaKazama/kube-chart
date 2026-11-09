# PodAntiAffinity 共享结构任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_PodAntiAffinity.tpl`：在 `writable-scopes` 内 `add` 紧邻 `define` 之前的中文整体契约注释与 `define "definitions.podAntiAffinity.weightedTerm"`，实现 `preferred` 元素归一化：`base.get` 取值 `weight`，空输出时中断，非空时以 `base.env` 的 `TYPES.INT` 校验整数形态并转为 `int64`，`base.get` 关闭别名读取已有 `podAffinityTerm` 后 `fromYaml` 恢复并用 `base.isFromYamlError` 保护，`mustDeepCopy` 后 `unset` 三个键再 `mustMerge` 并入，合并结果为空时 `fail`，最终 `toYamlPretty` 输出恒含 `weight` 与 `podAffinityTerm` 的映射；补齐字段级中文注释；对应 `Decision: preferred 元素归一化后委托既有术语子模板`。

- [x] T2 `templates/api-resources/Definitions/_PodAntiAffinity.tpl`：在 `writable-scopes` 内 `add` 紧邻 `define` 之前的中文整体契约注释与两个私有列表模板 `define "definitions.podAntiAffinity.termList"`、`define "definitions.podAntiAffinity.weightedTermList"`，实现 `base.get` 关闭别名取值、`fromYamlArray` 恢复、`base.isFromYamlArrayError` 保护、非数组中断、`null` 与空 map 跳过、非 map 中断、逐项委托（weighted 版本先经 `definitions.podAntiAffinity.weightedTerm`）、`fromYaml` 与 `base.isFromYamlError` 保护、`base.field` 搭配 `base.slice` 输出；失败前缀统一为 `[definitions.podAntiAffinity]`；对应 `Decision: 列表字段收敛为两个私有辅助模板`。

- [x] T3 `templates/api-resources/Definitions/_PodAntiAffinity.tpl`：在 `writable-scopes` 内 `add` 紧邻 `define` 之前的中文整体契约注释与 `define "definitions.podAntiAffinity"`，按 `preferredDuringSchedulingIgnoredDuringExecution` → `requiredDuringSchedulingIgnoredDuringExecution` 顺序分别 `include` `definitions.podAntiAffinity.weightedTermList`（元素模板 `definitions.weightedPodAffinityTerm`）与 `definitions.podAntiAffinity.termList`（元素模板 `definitions.podAffinityTerm`）；补齐字段级中文注释；对应 `Decision: 独立文件与命名模板族`、`Decision: 以 definitions.podAffinity 为唯一实现蓝本复制`、`Decision: 失败信息归属`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart（装载真实 `definitions.weightedPodAffinityTerm`、`definitions.podAffinityTerm` 与全部 `base.*`，不使用 fixture）：只提供 `requiredDuringSchedulingIgnoredDuringExecution` 单元素 `topologyKey: zone`，验证输出只含该字段且可被 `fromYaml` 回收；只提供单元素 `preferred` 扁平形态，验证输出为 `weight` 与 `podAffinityTerm` 两键的加权术语。
- [x] V2 `/tmp/` 最小 application Chart（真实依赖）：同时提供两个字段，`preferred` 元素含 `weight`、`topologyKey`、`namespaceSelector`、`labelSelector`、`matchLabelKeys`、`namespaces`，`required` 元素含术语字段，验证字段顺序、条目数与输入有效元素数一致、`namespaces` 的 `aaa bbb` 被拆分为 `aaa`、`bbb`、术语字段原样进入 `podAffinityTerm`；另通过 `definitions.affinity` 调用验证 `podAntiAffinity` 键的真实输出。
- [x] V3 `/tmp/` 最小 application Chart（真实依赖）：验证 `preferred` 元素已含 `podAffinityTerm` 时其余字段合并进该 map 且同名键以已有值为准；`required` 元素原样透传；短键 `preferred`、`required` 与两个 `*Alias` 单独出现时返回空字符串；两个字段为空 array 或含 `null`、空 map 元素时不产生对应输出；两个字段都无有效内容时输出空字符串。
- [x] V4 `/tmp/` 最小 application Chart（真实依赖）：字段为 map、string、数字；元素为 string、数字、布尔、array；`weight` 缺失、`null`、空字符串、`"11"`、`1.5`、bool、map、array；`podAffinityTerm` 为非 map；元素只有 `weight`；元素只含 `weight` 与 `podAffinityTerm: {}`；逐一验证渲染中断，本层错误信息含 `[definitions.podAntiAffinity]`、字段名与元素下标，依赖层错误消息保持原有前缀未被改写。
- [x] V5 静态检查：`templates/api-resources/Definitions/_PodAntiAffinity.tpl` 无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、字段注释紧邻对应处理闭环、文件末尾单换行；`git diff` 确认 `_PodAffinity.tpl` 与 `_Affinity.tpl` 未被修改。
