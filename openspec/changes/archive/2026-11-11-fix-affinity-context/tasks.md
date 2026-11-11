# Definitions 顶层 `$` 清理任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_Affinity.tpl`：在 `writable-scopes` 内把第 27、56、85 行三处 `include "base.get"` 参数列表首位的 `$` 改为 `.`，并删除 `define` 之后紧邻的空行，其余字符保持原样；对应 `Decision: 顶层 $ 统一替换为 .`、`Decision: 逐文件按精确行处理，不整文件重写`。
- [x] T2 `templates/api-resources/Definitions/_NodeAffinity.tpl`：在 `writable-scopes` 内把第 27、80 行两处 `include "base.get"` 参数列表首位的 `$` 改为 `.`，并删除 `define` 之后紧邻的空行，其余字符保持原样；对应 `Decision: 顶层 $ 统一替换为 .`、`Decision: 逐文件按精确行处理，不整文件重写`。
- [x] T3 `templates/api-resources/Definitions/_PodAffinity.tpl`：在 `writable-scopes` 内把第 27、30 行两处 `include` 参数列表首位的 `$` 改为 `.`，并删除 `define` 之后紧邻的空行，其余字符保持原样；对应 `Decision: 顶层 $ 统一替换为 .`、`Decision: 逐文件按精确行处理，不整文件重写`。
- [x] T4 `templates/api-resources/Definitions/_PodAntiAffinity.tpl`：在 `writable-scopes` 内把第 29、32 行两处 `include` 参数列表首位的 `$` 改为 `.`，其余字符保持原样；对应 `Decision: 顶层 $ 统一替换为 .`、`Decision: 逐文件按精确行处理，不整文件重写`。
- [x] T5 `templates/api-resources/Definitions/_PodAffinityTerm.tpl`：在 `writable-scopes` 内把第 38、59、76、93、114、130 行六处 `include "base.get"` 参数列表首位的 `$` 改为 `.`，其中第 130 行为嵌套调用，只改最内层 `base.get` 的上下文实参，其余字符保持原样；对应 `Decision: 顶层 $ 统一替换为 .`、`Decision: 逐文件按精确行处理，不整文件重写`。
- [x] T6 `templates/api-resources/Definitions/_NodeSelectorTerm.tpl`：在 `writable-scopes` 内把第 30、36 行两处 `include` 参数列表首位的 `$` 改为 `.`，并删除 `define` 之后紧邻的空行，其余字符保持原样；对应 `Decision: 顶层 $ 统一替换为 .`、`Decision: 逐文件按精确行处理，不整文件重写`。
- [x] T7 `templates/api-resources/Definitions/_NodeSelector.tpl`：在 `writable-scopes` 内把第 24 行 `include "base.get"` 参数列表首位的 `$` 改为 `.`，并删除 `define` 之后紧邻的空行，其余字符保持原样；对应 `Decision: 顶层 $ 统一替换为 .`、`Decision: 逐文件按精确行处理，不整文件重写`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart：建立 `baseline` 与 `current` 两个 Chart，装载同一组 `templates/base/*.tpl` 与 7 个目标模板；`current` 用改写后的工作区文件，`baseline` 的 6 个已跟踪文件用 `git show <改写前提交>:<path>` 还原，`_NodeSelector.tpl` 按第 25 行反向还原为 `$` 形态。
- [x] V2 等价渲染：同一输入下分别对 `baseline` 与 `current` 执行 `helm template`，输入同时提供 `nodeAffinity` 的 `required`、`podAffinity` 的 `required` 与 `podAntiAffinity` 的 `preferred`，`definitions.affinity` 链路输出逐字一致且三个子结构都出现。
- [x] V3 等价渲染：同一输入下两个 Chart 的 `definitions.nodeSelector` 链路输出逐字一致，输入为两项 term，覆盖必填集合、逐项委托与 `definitions.podAffinityTerm` 的六字段取值。
- [x] V4 静态复核：`templates/api-resources/Definitions/` 下 `(list $ ` 检索结果只剩 `_NodeSelectorRequirement.tpl` 第 37 行一处；7 个改写文件无冲突标记、无行尾空白、`define` 与 `end` 配平、文件末尾单换行。
