# Affinity 共享结构任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_Affinity.tpl`：新建文件并 `add` `define "definitions.affinity"` 与紧邻其前的中文契约注释，覆盖入参字段、短键归一化行为、失败边界与返回值；对应 `Decision: 目标文件与命名模板归属`。
- [x] T2 `templates/api-resources/Definitions/_Affinity.tpl`：在 `define "definitions.affinity"` 块内实现顶层三类子结构的固定键遍历、`base.get` 取值（别名开关传 `false`，空输出跳过）、`fromYaml` 恢复与 `base.isFromYamlError` 判定，判定为解析错误时 `fail` 并输出 `[definitions.affinity] <子结构>: must be map type`；对应 `Decision: 顶层键集合固定为三类子结构`、`Decision: 子结构取值与类型门禁`。
- [x] T3 `templates/api-resources/Definitions/_Affinity.tpl`：在 `define "definitions.affinity"` 块内对每个子结构分别取 `preferred`、`required` 与对应规范长键，经 `fromYamlArray` 恢复并用 `base.isFromYamlArrayError` 判定，错误时 `fail` 并输出 `[definitions.affinity] <子结构>.<字段名>: must be array type`；用 `default` 以短键值优先、长键值退化写入新建的 `$normalized`，两个规范键都为空时不进入委托；对应 `Decision: 短键与长键按 array 取值并退化`、`Decision: 只输出两个规范长键并丢弃其余字段`。
- [x] T4 `templates/api-resources/Definitions/_Affinity.tpl`：在 `define "definitions.affinity"` 块内按固定顺序委托 `definitions.nodeAffinity`、`definitions.podAffinity`、`definitions.podAntiAffinity`，对返回 YAML 用 `fromYaml` 与 `base.isFromYamlError` 保护后直接以 `base.field` + `base.map` 按规范键输出；对应 `Decision: 子模板委托与输出形态`、`Decision: 子模板返回值的错误边界`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart（三个子模板为同名 fixture）：只提供 `podAffinity.required`，输出只含 `podAffinity`，内部键为 `requiredDuringSchedulingIgnoredDuringExecution`。
- [x] V2 `/tmp/` 最小 application Chart（fixture）：三类子结构同时提供且各含短键与规范长键，输出三个规范键齐全、无 `preferred` / `required`、短键值生效。
- [x] V3 `/tmp/` 最小 application Chart（fixture）：同子结构同时提供 `preferred` 与非空长键时取 `preferred` 且不中断渲染；`preferred` 为空集合时取长键值；两侧都为空集合时该键不输出。
- [x] V4 `/tmp/` 最小 application Chart（fixture）：同一字段依次验证四档优先级：`preferredAlias`、`preferred`、`preferredDuringSchedulingIgnoredDuringExecutionAlias`、`preferredDuringSchedulingIgnoredDuringExecution` 同时存在时取 `preferredAlias`，逐档移除后依次取短键、长键别名、长键；`required` 侧用 `requiredAlias`、`required`、`requiredDuringSchedulingIgnoredDuringExecutionAlias`、`requiredDuringSchedulingIgnoredDuringExecution` 重复同一组递进验证。
- [x] V5 `/tmp/` 最小 application Chart（fixture）：子结构额外提供 `mismatchLabelKeys` 等字段时 fixture 收到的 map 不含这些字段；只提供 `podAntiAffinity` 时 fixture 未被调用且输出不含另外两个键；`podAffinity: {}` 时输出不含 `podAffinity`；入参为空 map 时输出为空结果而不是 `{}`。
- [x] V6 `/tmp/` 最小 application Chart（fixture）：`podAntiAffinity` 取值为字符串时渲染中断，错误信息包含 `[definitions.affinity]` 与 `podAntiAffinity`。
- [x] V7 `/tmp/` 最小 application Chart（fixture）：`podAffinity.preferred` 取值为 map 时渲染中断，错误信息包含 `[definitions.affinity]` 与 `podAffinity.preferred`；`nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution` 取值为字符串时渲染中断，错误信息包含完整字段路径。
- [x] V8 `/tmp/` 最小 application Chart（fixture）：fixture 子模板返回非 YAML 文本时渲染中断，错误信息包含 `[definitions.affinity]` 与对应字段名。
- [x] V9 静态检查：`templates/api-resources/Definitions/_Affinity.tpl` 无冲突标记、无行尾空白、`define` 与 `end` 配平、末尾单换行。
