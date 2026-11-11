# NodeSelector 共享结构设计

## 技术目标

- capability：`definitions.nodeSelector`
- artifact-type：Kubernetes 共享结构命名模板（library Chart）
- target：`templates/api-resources/Definitions/_NodeSelector.tpl`

## 设计决策

### Decision: 目标文件与命名模板归属

- requirements：`渲染 NodeSelector 字段片段`
- choice：在 `templates/api-resources/Definitions/` 新建 `_NodeSelector.tpl`，定义 `definitions.nodeSelector`，紧邻 `define` 之前写入中文整体契约注释。
- rationale：`NodeSelector` 是 `api-resources/Definitions` 层的可复用嵌套结构；既有调用点 `templates/api-resources/Definitions/_NodeAffinity.tpl` 已按 `include "definitions.nodeSelector" (dict "nodeSelectorTerms" $terms)` 调用，命名与目录必须与其契约一致。

### Decision: 取值与输入门禁在本层完成

- requirements：`校验 nodeSelectorTerms 输入`、`失败消息归属`
- choice：`include "base.get" (list $ "nodeSelectorTerms")` 取值并保留默认别名识别，`trim` 后为空即中断；非空时用 `fromYamlArray` 归一化，`base.isFromYamlArrayError` 判定为错误即中断；恢复后的数组为空时再次中断。不使用 `base.get` 的必填参数。
- rationale：规格要求本模板自身产生的失败消息使用 `[definitions.nodeSelector]` 前缀，而 `templates/base/_get.tpl` 的必填分支固定输出 `[base.get]` 前缀，无法满足前缀归属。`fromYamlArray` 成功即保证结果是数组，调用方不重复 `kindIs "slice"`；空数组能被成功解析，因此必须在解析后单独判定。

### Decision: 逐项 map 门禁与委托回收

- requirements：`校验 nodeSelectorTerms 输入`、`逐项委托 definitions.nodeSelectorTerm`
- choice：按输入顺序 `range` 数组，元素不是 map 时以条目下标中断；是 map 时把元素本体作为上下文 `include "definitions.nodeSelectorTerm"`，返回值经 `fromYaml` 与 `base.isFromYamlError` 保护，解析错误以条目下标中断，非空结果用 `mustAppend` 收集。
- rationale：元素是未经 YAML 恢复的原始值，按工程规则可用 `kindIs` 判定；`templates/api-resources/Definitions/_NodeAffinity.tpl` 已用 `if $_rendered` 消费 `fromYaml` 的空输出，说明空内容恢复后为假值，可直接用于“空内容不并入”的判断。委托边界与空内容丢弃规则由规格锁定，本层不解析 `matchExpressions`、`matchFields`。

### Decision: 收集结果为空时中断

- requirements：`逐项委托 definitions.nodeSelectorTerm`
- choice：循环结束后收集列表为空即中断，失败消息为 `[definitions.nodeSelector] nodeSelectorTerms: required field is missing or empty`。
- rationale：规格把 `nodeSelectorTerms` 定义为 Required 且必须有内容；空收集与输入缺失在同一层给出同一语义的消息，避免调用方需要区分两种无内容来源。

### Decision: 输出使用 base.field 与 base.slice

- requirements：`渲染 NodeSelector 字段片段`
- choice：`include "base.field" (list "nodeSelectorTerms" $rendered "base.slice")` 输出唯一字段。
- rationale：`$rendered` 已是委托结果 map 的列表，由 `base.slice` 执行最终 slice 门禁与序列化；结构子模板返回值不得直接作为 `base.field` 的渲染模板参数。规格锁定输出只有 `nodeSelectorTerms`，因此不需要字段生效判断以外的分支。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, "nodeSelectorTerms"]`，非必填并保留默认别名识别。
- output：可 `fromYamlArray` 解析的 YAML 字符串；路径缺失或取值为空标量时为空输出。
- ownership：数据源优先级、同级别名识别与序列化由依赖层负责；空输出判定、必填语义与失败消息由本层负责。

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 的返回值。
- output：布尔字符串 `"true"` / `"false"`。
- ownership：错误形态识别由依赖层负责；中断决策与失败消息由本层负责。

### Dependency: `definitions.nodeSelectorTerm`

- availability：`existing`
- source：`templates/api-resources/Definitions/_NodeSelectorTerm.tpl`
- operation：`consume`
- input：单个 `NodeSelectorTerm` map，可含 `matchExpressions`、`matchFields` 及其同级别名。
- output：可 `fromYaml` 解析为 `NodeSelectorTerm` map 的 YAML 字段片段；无有效内容时为空字符串；非法入参中断渲染。
- ownership：`matchExpressions`、`matchFields` 的解析、归一化、校验与字段输出由依赖层负责；本层只负责按顺序传递 term 与回收结果，不改写其失败消息。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 的返回值，用于 `definitions.nodeSelectorTerm` 的输出。
- output：布尔字符串 `"true"` / `"false"`。
- ownership：错误形态识别由依赖层负责；中断决策与失败消息由本层负责。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list ["nodeSelectorTerms", map 列表, "base.slice"]`。
- output：`nodeSelectorTerms:` 加换行缩进的字段片段；值为空时不输出。
- ownership：序列化与目标类型门禁由依赖层负责；字段生效条件与输出顺序由本层负责。

### Dependency: `base.slice`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：由 `base.field` 传入的 map 列表。
- output：YAML 列表字符串；非 slice 时中断。
- ownership：列表序列化与类型门禁由依赖层负责。

## 代码边界

### `templates/api-resources/Definitions/_NodeSelector.tpl`

- access：`write`
- operations：`add define "definitions.nodeSelector"`、`add 紧邻 define 之前的中文整体契约注释`、`add 字段级中文注释`
- writable-scopes：新建文件全部内容

### `templates/api-resources/Definitions/_NodeAffinity.tpl`

- access：`read`
- operations：`consume include "definitions.nodeSelector" 的既有调用契约`

### `templates/api-resources/Definitions/_NodeSelectorTerm.tpl`

- access：`read`
- operations：`consume define "definitions.nodeSelectorTerm" 的入参与返回边界`

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume define "base.get" 的取值、别名与返回边界`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume define "base.isFromYamlError"`、`consume define "base.isFromYamlArrayError"`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume define "base.field" 的渲染与输出边界`

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume define "base.slice" 的序列化与类型门禁`

## 验证设计

- 最小有效：`/tmp/` 最小 application Chart 加载本次变更模板与真实依赖；提供一项含 `matchExpressions` map 的 term，验证输出只含 `nodeSelectorTerms` 且该数组含一项、内容与委托结果一致。
- 较完整有效：同一 Chart 提供三项 term，分别只含 `matchExpressions`、只含 `matchFields`、两者都含字符串简写与 map 混用条目，验证输出顺序与输入一致、项数一致、`nodeSelectorTerms` 之外不出现其他字段；另验证 `nodeSelectorTermsAlias` 覆盖与空别名回退。
- 关键失败：`nodeSelectorTerms` 缺失、为 YAML `null`、空字符串、空数组、map、字符串，以及元素为字符串简写、数字、布尔值，逐项验证渲染中断且失败消息前缀为 `[definitions.nodeSelector]`，条目相关消息包含 `nodeSelectorTerms[<index>]`。
- 空内容与依赖边界：仅含 `{}` 的数组验证收集为空即中断；`[{} , 有效 term]` 验证空内容项被丢弃且有效项保留；term 内含非法 `operator` 验证失败消息保持 `[definitions.nodeSelectorTerm]` 前缀；使用返回非 YAML 的 `definitions.nodeSelectorTerm` 同名 fixture 验证解析保护分支。
