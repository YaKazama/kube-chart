# Definitions 顶层 `$` 清理设计

## 技术目标

- capability：`definitions.affinity`、`definitions.nodeAffinity`、`definitions.podAffinity`、`definitions.podAntiAffinity`、`definitions.podAffinityTerm`、`definitions.nodeSelectorTerm`、`definitions.nodeSelector`
- artifact-type：Kubernetes 共享结构命名模板（library Chart）内部表达收敛
- target：`templates/api-resources/Definitions/` 下 7 个既有模板的顶层 `include` / `base.get` 参数表达式

## 设计决策

### Decision: 顶层 `$` 统一替换为 `.`

- requirements：`NO SPEC DELTA`（纯内部表达收敛，无行为映射）
- choice：把 `define` 块顶层直接出现在 `include` / `base.get` 参数列表首位、或出现在嵌套 `include` 调用参数首位的 `$` 改写为 `.`，共 18 处。替换只改变实参的书写形式，不改变实参求值结果。
- rationale：`include` 进入 `define` 时 `$` 与 `.` 同时指向该次调用传入的上下文；在 `range`、`with` 之外没有任何语义差别。`fix: affinity 子模板改为逐字段直白写法`（`ee61370`）删除外层 `range` 后未同步改写，使 `$` 只保留了书写噪声，容易让读者误判当前仍处于嵌套作用域。统一为 `.` 后，`$` 在文件内只出现在真正需要外层上下文的位置，具备可判读性。

### Decision: 逐文件按精确行处理，不整文件重写

- requirements：`NO SPEC DELTA`（纯内部表达收敛，无行为映射）
- choice：按文件聚合 18 处命中，逐条只替换该行的上下文实参；契约注释、失败消息、变量命名、缩进与空行全部保持原样。
- rationale：本次不改变行为，整文件重写会引入无关差异并放大回归面。逐行替换后，每个文件的版本控制差异只包含 `$` → `.` 一个字符级变化，便于人工确认没有夹带语义修改。

### Decision: 嵌套作用域保持 `$`

- requirements：`NO SPEC DELTA`（纯内部表达收敛，无行为映射）
- choice：`templates/api-resources/Definitions/_NodeSelectorRequirement.tpl` 第 37 行的 `(list $ $_name "" "" true)` 保持原样。
- rationale：该调用位于 `range $_name := list "key" "operator"` 内，此处的 `.` 会变成当前元素即字段名字符串，`$` 是唯一能取到 `define` 顶层入参的写法。把它改写为 `.` 会改变实参类型并破坏 `base.get` 的上下文契约，属于行为变化。

### Decision: `define` 之后不保留空行

- requirements：`NO SPEC DELTA`（纯排版收敛，无行为映射）
- choice：删除 `_Affinity.tpl`、`_NodeAffinity.tpl`、`_PodAffinity.tpl`、`_NodeSelectorTerm.tpl`、`_NodeSelector.tpl` 5 个文件中 `{{- define ... -}}` 与其后首个内容行之间的空行；其余文件不因本 change 调整。
- rationale：`define` 行以 `-}}` 结尾，会裁剪紧随其后的全部空白，该空行不产生任何输出，删除不改变渲染结果。当前目录 19 个模板中已有 18 个原本就没有该空行，删除后这 5 个文件与主流排版一致；`_PodAntiAffinity.tpl` 仍保留该空行，属于本 change 未触及的既有差异。工程规则未强制该空行，删除后仍满足既有排版约定。

### Decision: 以渲染输出比对作为等价证据

- requirements：`NO SPEC DELTA`（纯内部表达收敛，无行为映射）
- choice：在 `/tmp/` 最小 application Chart 中分别渲染 `definitions.affinity` 完整链路与 `definitions.nodeSelector` 链路，把改写前后的输出逐字比对；同时对 7 个文件恢复后的原始文本做 `(list $ ` 全文检索复核。
- rationale：本 change 声称无行为变化，最有说服力的证据是同一输入下渲染结果完全一致，而不是只靠静态判断 `$` 与 `.` 等价。两个被选链路分别覆盖「多层子结构嵌套 + 短长键归一化 + 双字段委托」与「必填集合 + 逐项委托 + 空内容丢弃」两类结构，能覆盖 7 个文件中实际被改写的调用点。

## 依赖契约

- 本 change 不新增、删除或改名任何命名模板调用，也不改变任何被调用模板的入参形态与返回边界。
- 被改写的实参在改写前后求值为同一个 map，因此 `base.get`、`base.labelKey`、`base.field`、`base.slice`、`base.isFromYamlError`、`base.isFromYamlArrayError` 以及 `definitions.*` 子模板的 `availability`、`source`、`operation`、`input`、`output` 与 `ownership` 均维持既有结论，全部为 `existing` + `consume`。
- 因此本 change 不产生新的依赖契约条目；依赖复核结论由既有 change 与工程规则直接约束。

## 代码边界

### `templates/api-resources/Definitions/_Affinity.tpl`

- access：`write`
- operations：`update 第 27、56、85 行 include "base.get" 参数列表首位的上下文实参`、`remove define "definitions.affinity" 之后紧邻的空行`
- writable-scopes：`define "definitions.affinity"` 块内上述三处 `base.get` 调用行的上下文实参，以及 `define` 行与其后首个内容行之间的空行

### `templates/api-resources/Definitions/_NodeAffinity.tpl`

- access：`write`
- operations：`update 第 27、80 行 include "base.get" 参数列表首位的上下文实参`、`remove define "definitions.nodeAffinity" 之后紧邻的空行`
- writable-scopes：`define "definitions.nodeAffinity"` 块内上述两处 `base.get` 调用行的上下文实参，以及 `define` 行与其后首个内容行之间的空行

### `templates/api-resources/Definitions/_PodAffinity.tpl`

- access：`write`
- operations：`update 第 27、30 行 include 参数列表首位的上下文实参`、`remove define "definitions.podAffinity" 之后紧邻的空行`
- writable-scopes：`define "definitions.podAffinity"` 块内上述两处 `include` 调用行的上下文实参，以及 `define` 行与其后首个内容行之间的空行

### `templates/api-resources/Definitions/_PodAntiAffinity.tpl`

- access：`write`
- operations：`update 第 29、32 行 include 参数列表首位的上下文实参`
- writable-scopes：`define "definitions.podAntiAffinity"` 块内上述两处 `include` 调用行的上下文实参

### `templates/api-resources/Definitions/_PodAffinityTerm.tpl`

- access：`write`
- operations：`update 第 38、59、76、93、114、130 行 include "base.get" 参数列表首位的上下文实参`
- writable-scopes：`define "definitions.podAffinityTerm"` 块内上述六处 `base.get` 调用行的上下文实参

### `templates/api-resources/Definitions/_NodeSelectorTerm.tpl`

- access：`write`
- operations：`update 第 30、36 行 include 参数列表首位的上下文实参`、`remove define "definitions.nodeSelectorTerm" 之后紧邻的空行`
- writable-scopes：`define "definitions.nodeSelectorTerm"` 块内上述两处 `include` 调用行的上下文实参，以及 `define` 行与其后首个内容行之间的空行

### `templates/api-resources/Definitions/_NodeSelector.tpl`

- access：`write`
- operations：`update 第 24 行 include "base.get" 参数列表首位的上下文实参`、`remove define "definitions.nodeSelector" 之后紧邻的空行`
- writable-scopes：`define "definitions.nodeSelector"` 块内该处 `base.get` 调用行的上下文实参，以及 `define` 行与其后首个内容行之间的空行

### `templates/api-resources/Definitions/_NodeSelectorRequirement.tpl`

- access：`read`
- operations：`consume 第 37 行 range 内 (list $ $_name ...) 的既有写法作为保持不变的反例基线`

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume define "base.get" 的上下文实参语义，用于确认顶层 $ 与 . 求值一致`

### `templates/base/_collection.tpl`

- access：`read`
- operations：`consume define "base.slice.cleanup" 的既有调用契约，用于渲染比对`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume define "base.isFromYamlError"`、`consume define "base.isFromYamlArrayError"`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume define "base.field" 的渲染边界，用于渲染比对`

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume define "base.slice" 的序列化边界，用于渲染比对`

### `templates/base/_k8s.tpl`

- access：`read`
- operations：`consume define "base.labelKey" 的校验边界，用于渲染比对`

## 验证设计

- 基线构造：在 `/tmp/` 建立 `baseline` 与 `current` 两个最小 application Chart，装载同一组 `templates/base/*.tpl` 与 7 个目标模板。`current` 使用改写后的工作区文件；`baseline` 的 6 个已跟踪文件用 `git show <HEAD 前的提交>:<path>` 还原，`_NodeSelector.tpl` 未被版本控制跟踪，按 `Decision: 顶层 $ 统一替换为 .` 锁定的第 25 行位置反向还原为 `$` 形态。
- 最小有效：同一输入下两个 Chart 分别执行 `helm template`，`definitions.affinity` 链路输出逐字一致；输入同时提供 `nodeAffinity` 的 `required`、`podAffinity` 的 `required` 与 `podAntiAffinity` 的 `preferred`，覆盖三个子结构。
- 关键结构覆盖：同一输入下两个 Chart 的 `definitions.nodeSelector` 链路输出逐字一致，覆盖必填集合、逐项委托与空内容项丢弃；`definitions.podAffinityTerm` 的六个字段由 `definitions.podAffinity` 的 `required` 分支触达。
- 排版等价：`current` 已删除 5 处 `define` 后的空行而 `baseline` 保留，上述比对因此同时证明该空行删除不产生输出差异。
- 静态复核：`templates/api-resources/Definitions/` 下检索 `(list $ `，改写后只应剩余 `_NodeSelectorRequirement.tpl` 第 37 行一处；7 个改写文件无冲突标记、无行尾空白、`define` 与 `end` 配平、文件末尾单换行。
