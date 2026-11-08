# PodAffinity 共享结构任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_PodAffinity.tpl`：新建文件，在 `writable-scopes` 内 `add` 紧邻 `define` 之前的中文整体契约注释与 `define "definitions.podAffinity"` 骨架，并实现固定字段表与字段读取：按 `preferredDuringSchedulingIgnoredDuringExecution` → `requiredDuringSchedulingIgnoredDuringExecution` 顺序 `base.get` 取值、显式关闭别名、空输出跳过、`fromYamlArray`、`base.isFromYamlArrayError` 保护、非数组中断，并补齐字段级中文注释；对应 `Decision: 目标文件与命名模板归属`、`Decision: 固定字段表驱动循环`。
- [x] T2 `templates/api-resources/Definitions/_PodAffinity.tpl`：在 `writable-scopes` 内实现元素门禁：空 array 跳过该字段、`kindIs "invalid"` 判定 `null` 并跳过、`kindIs "map"` 判定元素形态、非 map 中断且错误含字段名与元素下标、空 map 跳过；对应 `Decision: 数组解析与元素门禁`。
- [x] T3 `templates/api-resources/Definitions/_PodAffinity.tpl`：在 `writable-scopes` 内实现委托与输出闭环：逐元素 `include` 字段表指定子模板、`fromYaml` 与 `base.isFromYamlError` 保护、按输入顺序累加、`base.field` 搭配 `base.slice` 输出、两个字段均无有效内容时返回空字符串；对应 `Decision: 子模板委托与字段输出`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart（`definitions.weightedPodAffinityTerm`、`definitions.podAffinityTerm` 为同名回显 fixture）：只提供 `preferredDuringSchedulingIgnoredDuringExecution` 单元素，验证输出只含该字段、fixture 收到与输入元素逐键一致的上下文。
- [x] V2 `/tmp/` 最小 application Chart（fixture）：同时提供两个字段各两个元素且元素含 `weight`、`topologyKey`、`namespaceSelector`、`labelSelector`、`matchLabelKeys`、`namespaces`，验证字段顺序、条目数与有效元素数一致、元素内部字段原样透传。
- [x] V3 `/tmp/` 最小 application Chart（fixture）：两个字段为空 array、元素为 `null` 与空 map，验证不产生对应输出；两个字段都无有效内容时返回空字符串；另验证只提供 `preferred`、`required` 与两个 `*Alias` 键时返回空字符串。
- [x] V4 `/tmp/` 最小 application Chart（fixture）：字段为 map、string、数字，元素为 string、数字、布尔、array，以及 fixture 返回非 YAML 内容，逐一验证渲染中断且错误信息含 `[definitions.podAffinity]`、字段名与元素下标。
- [x] V5 静态检查：`templates/api-resources/Definitions/_PodAffinity.tpl` 无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、字段注释紧邻对应处理闭环、文件末尾单换行。
