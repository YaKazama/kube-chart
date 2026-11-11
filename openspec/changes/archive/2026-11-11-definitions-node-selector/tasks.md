# NodeSelector 共享结构任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_NodeSelector.tpl`：新建文件，在 `writable-scopes` 内 `add` 紧邻 `define` 之前的中文整体契约注释与 `define "definitions.nodeSelector"` 骨架，并实现取值与输入门禁：`base.get` 非必填取值并保留默认别名识别、空输出中断、`fromYamlArray` 归一化、`base.isFromYamlArrayError` 保护、恢复后空数组中断，失败消息使用 `[definitions.nodeSelector]` 前缀；对应 `Decision: 目标文件与命名模板归属`、`Decision: 取值与输入门禁在本层完成`。
- [x] T2 `templates/api-resources/Definitions/_NodeSelector.tpl`：在 `writable-scopes` 内实现逐项委托闭环：按输入顺序 `range`、元素非 map 时以 `nodeSelectorTerms[<index>]` 路径中断、把元素本体作为上下文 `include "definitions.nodeSelectorTerm"`、返回值 `fromYaml` 与 `base.isFromYamlError` 保护、解析错误以条目下标中断、非空结果用 `mustAppend` 收集；对应 `Decision: 逐项 map 门禁与委托回收`。
- [x] T3 `templates/api-resources/Definitions/_NodeSelector.tpl`：在 `writable-scopes` 内实现收集中断与输出闭环：收集列表为空时中断，非空时用 `base.field` 搭配 `base.slice` 输出唯一的 `nodeSelectorTerms` 字段，并补齐字段级中文注释；对应 `Decision: 收集结果为空时中断`、`Decision: 输出使用 base.field 与 base.slice`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart（`definitions.nodeSelectorTerm` 使用工作区真实实现）：提供一项含 `matchExpressions` 的 term，验证输出只含 `nodeSelectorTerms`、数组含一项且内容与委托结果一致。
- [x] V2 `/tmp/` 最小 application Chart（真实依赖）：提供三项 term，分别只含 `matchExpressions`、只含 `matchFields`、两者都含字符串简写与 map 混用条目，验证输出项数与顺序一致、无其他字段；另验证 `nodeSelectorTermsAlias` 覆盖与非空别名优先、空别名回退规范键。
- [x] V3 `/tmp/` 最小 application Chart（真实依赖）：`nodeSelectorTerms` 分别为缺失、`null`、空字符串、`[]`、map、字符串，以及元素为字符串简写、数字、布尔值，逐一验证渲染中断且失败消息以 `[definitions.nodeSelector]` 开头，条目相关消息包含 `nodeSelectorTerms[<index>]`。
- [x] V4 `/tmp/` 最小 application Chart（真实依赖）：分别提供 `nodeSelectorTerms: [{}]` 与 `[{} , 有效 term]`，验证前者收集为空即中断、后者空内容项被丢弃且有效项保留并保持相对顺序。
- [x] V5 `/tmp/` 最小 application Chart：term 内含非法 `operator` 时验证失败消息保持 `[definitions.nodeSelectorTerm]` 前缀；再以返回非 YAML 的 `definitions.nodeSelectorTerm` 同名 fixture 验证 `base.isFromYamlError` 保护分支中断且消息包含 `nodeSelectorTerms[<index>]`。
