# PodAffinity 与 PodAntiAffinity 二级模板失败消息前缀任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_PodAffinity.tpl`：在 `writable-scopes` 内把 `define "definitions.podAffinity.termList"`、`define "definitions.podAffinity.weightedTermList"`、`define "definitions.podAffinity.weightedTerm"` 三个块中共 11 条 `fail` 消息的方括号模板名前缀分别替换为 `definitions.podAffinity.termList`、`definitions.podAffinity.weightedTermList`、`definitions.podAffinity.weightedTerm`，其余字符与 `printf` 参数保持不变；对应 `Decision: 逐处替换前缀字面量`、`Decision: 失败消息归属按语句所在模板判定`。

- [x] T2 `templates/api-resources/Definitions/_PodAntiAffinity.tpl`：在 `writable-scopes` 内把 `define "definitions.podAntiAffinity.termList"`、`define "definitions.podAntiAffinity.weightedTermList"`、`define "definitions.podAntiAffinity.weightedTerm"` 三个块中共 11 条 `fail` 消息的方括号模板名前缀分别替换为对应的完整二级模板名，并把 `define "definitions.podAntiAffinity"` 之前契约注释中描述失败消息前缀的句子改为「本层及其私有辅助模板的失败消息使用各自模板名，委托子模板的失败消息原样传播」；其余字符与 `printf` 参数保持不变；对应 `Decision: 逐处替换前缀字面量`、`Decision: 主模板契约注释同步修正`、`Decision: 失败消息归属按语句所在模板判定`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart（装载真实 `definitions.weightedPodAffinityTerm`、`definitions.podAffinityTerm` 与全部 `base.*`）：对 `definitions.podAffinity` 与 `definitions.podAntiAffinity` 分别提供单元素 `required`（`topologyKey: zone`）与单元素 `preferred` 扁平形态，断言 `required` 输出含单个 `{topologyKey: zone}` 元素、`preferred` 输出为 `podAffinityTerm` 与 `weight` 两键的加权术语，且结果可被 `fromYaml` 回收；同时断言输出文本与修正前一致。
- [x] V2 `/tmp/` 最小 application Chart（真实依赖）：按已归档 change 的六字段输入同时提供两个字段，断言字段顺序、条目数、`namespaces` 的 `aaa bbb` 被拆分为 `aaa`、`bbb`、`preferred` 元素的 `podAffinityTerm` 与 `weight` 两键、术语字段原样进入 `podAffinityTerm`；另经 `definitions.affinity` 的短键 `preferred`、`required` 调用，断言 `podAffinity` 与 `podAntiAffinity` 键输出与修正前一致。
- [x] V3 `/tmp/` 最小 application Chart（真实依赖）：对 `definitions.podAffinity` 的 3 个二级模板逐一触发全部失败分支，断言每条错误前缀等于所属二级模板完整名，且字段名、元素下标与原因文本与修正前一致。
- [x] V4 `/tmp/` 最小 application Chart（真实依赖）：对 `definitions.podAntiAffinity` 的 3 个二级模板逐一触发全部失败分支，断言每条错误前缀等于所属二级模板完整名，且字段名、元素下标与原因文本与修正前一致。
- [x] V5 `/tmp/` 最小 application Chart（真实依赖）：断言依赖层失败消息前缀保持为 `[base.get]`、`[base.int.range]`、`[definitions.podAffinityTerm]`、`[definitions.weightedPodAffinityTerm]`，未被本层改写。
- [x] V6 静态检查：两个写入文件内不存在以 `[definitions.podAffinity]` 或 `[definitions.podAntiAffinity]` 作前缀的 `fail` 消息；`define` 与 `end` 配平、契约注释位置不变、无行尾空白、文件末尾单换行；`git diff` 只包含两个文件的 `fail` 字面量与 `_PodAntiAffinity.tpl` 的注释句子。
