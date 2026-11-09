# PodAntiAffinity 共享结构设计

## 技术目标

- capability：`definitions.podAntiAffinity`
- artifact-type：Kubernetes 共享结构命名模板
- target：`templates/api-resources/Definitions/_PodAntiAffinity.tpl` 中的 `define "definitions.podAntiAffinity"` 及其同前缀私有辅助模板

## 设计决策

### Decision: 独立文件与命名模板族

- requirements：`渲染 PodAntiAffinity 字段片段`
- choice：新增 `templates/api-resources/Definitions/_PodAntiAffinity.tpl`，文件内定义 `definitions.podAntiAffinity` 与三个私有辅助模板 `definitions.podAntiAffinity.termList`、`definitions.podAntiAffinity.weightedTermList`、`definitions.podAntiAffinity.weightedTerm`；不修改 `_PodAffinity.tpl`，不向其追加任何 `define`。
- rationale：`PodAntiAffinity` 是 Kubernetes 官方共享结构，只能落在同域共享结构层 `api-resources/Definitions`；`helm-templates.md` 要求共享结构文件使用 `_<结构名>.tpl`、辅助模板沿用同一命名空间和能力前缀，且同文件围绕主模板组织。draft 已确认独立文件承载，并明确不得混入已归档 change 的文件。

### Decision: 以 definitions.podAffinity 为唯一实现蓝本复制

- requirements：`渲染 PodAntiAffinity 字段片段`、`输入类型与空元素边界`
- choice：逐块复制 `_PodAffinity.tpl` 的四段处理逻辑到新文件，把全部 `define` 名、`include` 目标中的私有辅助模板名与失败信息前缀替换为 `podAntiAffinity`；取值、类型门禁、元素跳过、委托与 `base.field` 输出顺序保持逐行等价。
- rationale：两个结构在 K8s API 快照中字段集完全一致（`preferredDuringSchedulingIgnoredDuringExecution` 与 `requiredDuringSchedulingIgnoredDuringExecution` 两项）。draft 已确认「参照而非复用」：跨文件复用会把一个文件的私有辅助模板暴露给另一个文件，通用性有限，因此以复制改名实现行为等价。

### Decision: 列表字段收敛为两个私有辅助模板

- requirements：`输入类型与空元素边界`
- choice：主模板按 `preferredDuringSchedulingIgnoredDuringExecution` → `requiredDuringSchedulingIgnoredDuringExecution` 顺序分别 `include` `definitions.podAntiAffinity.weightedTermList` 与 `definitions.podAntiAffinity.termList`，两者分别以 `list [上下文, 字段名, 元素处理模板名]` 接收参数；辅助模板只负责 `base.get` 取值、`fromYamlArray` 恢复、字段级类型门禁、`null` 与空 map 跳、逐项委托与 `base.field` 输出。
- rationale：两个字段的取值与门禁逻辑同构，仅元素处理模板不同，由一个参数化的私有模板承载可避免在同一文件内复制两份遍历骨架；`helm-templates.md` 允许同文件的同前缀私有辅助模板承担这类结构复用。两个辅助模板与 `weightedTerm` 均以 list 作为 `include` 上下文，因此三者的中文契约注释必须在 `define` 之前显式声明 `list [上下文, 字段名, 元素处理模板名]` 与 `list [元素 map, 字段名, 元素下标]` 入参形态，以满足 `上下文类型` 要求。

### Decision: preferred 元素归一化后委托既有术语子模板

- requirements：`委托术语子模板`、`校验 preferred 元素的 weight`
- choice：`definitions.podAntiAffinity.weightedTerm` 以 `list [元素 map, 字段名, 元素下标]` 接收参数，输出恒含 `weight` 与 `podAffinityTerm` 两个键的 YAML 映射；`weight` 经 `base.get` 默认别名识别取值并用 `TYPES.INT` 校验整数形态，空输出按必填缺失中断，匹配后以 `int64` 归一为整数；`podAffinityTerm` 以元素已有值为合并起点，其余键（排除 `weight`、`weightAlias`、`podAffinityTerm`）经 `mustDeepCopy` 后 `mustMerge` 并入，合并结果为空时中断；归一化上下文再交给 `definitions.weightedPodAffinityTerm`。`required` 元素不归一化，直接交给 `definitions.podAffinityTerm`。
- rationale：两个术语子模板已按 `definitions.weightedPodAffinityTerm`、`definitions.podAffinityTerm` 现有契约消费嵌套形态与扁平形态，draft 已确认不为 anti-affinity 新增术语子模板；因此本层只承担「扁平输入 → 子模板所需上下文」的归一化，`weight` 的 1-100 范围继续由 `definitions.weightedPodAffinityTerm` 校验。

### Decision: 失败信息归属

- requirements：`渲染 PodAntiAffinity 字段片段`
- choice：本层所有 `fail` 消息统一使用 `[definitions.podAntiAffinity]` 前缀；委托子模板抛出的失败信息原样传播，不捕获、不改写。
- rationale：`helm-templates.md` 要求失败消息统一为 `[模板名] 字段路径: 错误原因`。依赖层的 `[definitions.weightedPodAffinityTerm]`、`[definitions.podAffinityTerm]`、`[base.*]` 前缀属于各自模板名，改写会破坏依赖层契约；draft 已确认失败消息按模板归属划分：本层消息由本层管理，其他模板消息由各自模板独立管理，本层不捕获、不改写并原样传播。

## 依赖契约

### Dependency: `definitions.weightedPodAffinityTerm`

- availability：`existing`
- source：`templates/api-resources/Definitions/_WeightedPodAffinityTerm.tpl`
- operation：`consume`
- input：`dict`，恒含 `weight`（integer，1-100）与 `podAffinityTerm`（非空 map）两个键。
- output：可 `fromYaml` 解析为 `WeightedPodAffinityTerm` map 的 YAML 字段片段；入参缺失、`weight` 非整数或超范围、`podAffinityTerm` 非 map 或为空时中断。
- ownership：`weight` 的 1-100 范围校验、`podAffinityTerm` 结构渲染与字段输出由依赖层负责；本层只负责构造归一化上下文、校验 `weight` 整数形态与 `podAffinityTerm` 非空。

### Dependency: `definitions.podAffinityTerm`

- availability：`existing`
- source：`templates/api-resources/Definitions/_PodAffinityTerm.tpl`
- operation：`consume`
- input：`requiredDuringSchedulingIgnoredDuringExecution` 的单个数组元素 map，原样传入。
- output：可 `fromYaml` 解析为 `PodAffinityTerm` map 的 YAML 字段片段；`topologyKey` 缺失或非法、字段类型不符时中断。
- ownership：六字段的取值、校验、归一化与渲染由依赖层负责；本层只负责元素门禁、原样委托与错误保护。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：三种调用形式：① `list [上下文, 字段名, "", "", false, false]`，关闭同级别名；② `list [元素, "weight"]`，保持别名默认开启以支持 `weightAlias`；③ `list [元素, "podAffinityTerm", "", "", false, false]`，关闭同级别名。
- output：可由 `fromYaml` / `fromYamlArray` 解析的 YAML 字符串；路径缺失、`null` 或空字符串时为空输出。
- ownership：数据源优先级、别名识别与序列化由依赖层负责；调用形式选择、空输出判定与失败消息由本层负责。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：`""`
- output：可由 `fromYaml` 解析的常量 Map；本层读取 `TYPES.INT`。
- ownership：常量集中定义由依赖层负责；常量键选择与调用时机由本层负责。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [字段名, 已渲染元素列表, "base.slice"]`。
- output：`字段名:` 加换行缩进的 YAML 列表片段；渲染结果为空时不输出字段。
- ownership：序列化与空值跳过由依赖层负责；字段生效条件、键名与渲染模板选择由本层负责。

### Dependency: `base.slice`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：已累积的非空元素 map 列表。
- output：YAML 列表字符串；非 slice 输入时中断。
- ownership：slice 类型门禁与序列化由依赖层负责；字段生效条件由本层负责。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 返回值，用于 `podAffinityTerm` 恢复结果、归一化上下文与委托返回值。
- output：布尔字符串 `"true"` / `"false"`。
- ownership：错误形态识别由依赖层负责；失败消息与中断决策由本层负责。

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 返回值，用于两个字段的数组恢复。
- output：布尔字符串 `"true"` / `"false"`。
- ownership：错误形态识别由依赖层负责；失败消息与中断决策由本层负责。

## 代码边界

### `templates/api-resources/Definitions/_PodAntiAffinity.tpl`

- access：`write`
- operations：`add define "definitions.podAntiAffinity"`、`add define "definitions.podAntiAffinity.termList"`、`add define "definitions.podAntiAffinity.weightedTermList"`、`add define "definitions.podAntiAffinity.weightedTerm"`、`add 各 define 之前的中文整体契约注释`、`add 字段级中文注释`
- writable-scopes：上述四个 `define` 块及其紧邻契约注释；文件不包含其他内容

### `templates/api-resources/Definitions/_Affinity.tpl`

- access：`read`
- operations：`consume definitions.affinity 第三个分支对 definitions.podAntiAffinity 的既有调用契约`

### `templates/api-resources/Definitions/_PodAffinity.tpl`

- access：`read`
- operations：`consume 四段处理逻辑作为复制蓝本；确认不被修改`

### `templates/api-resources/Definitions/_WeightedPodAffinityTerm.tpl`

- access：`read`
- operations：`consume definitions.weightedPodAffinityTerm 的入参键与必填边界`

### `templates/api-resources/Definitions/_PodAffinityTerm.tpl`

- access：`read`
- operations：`consume definitions.podAffinityTerm 的入参边界与返回值形态`

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume base.get 的调用形式、别名开关、必填语义与空输出边界`

### `templates/base/_env.tpl`

- access：`read`
- operations：`consume TYPES.INT 的运行时表达式`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume base.field 的调用形式、渲染模板路由与空值输出行为`

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume base.slice 的类型门禁与序列化行为`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume base.isFromYamlError、base.isFromYamlArrayError 的返回形态与失败判定`

## 验证设计

- 依赖边界：`definitions.weightedPodAffinityTerm`、`definitions.podAffinityTerm` 与全部 `base.*` 均为当前工作区真实实现，验证在 `/tmp/` 最小 application Chart 中装载真实模板文件，不使用同名 fixture；`definitions.affinity` 用于确认调用链真实生效。
- 最小有效输入：只提供 `requiredDuringSchedulingIgnoredDuringExecution` 单元素 `topologyKey: zone`，验证输出只含该字段且可被 `fromYaml` 回收。
- 较完整有效输入：按 draft 入参形态同时提供两个字段，`preferred` 元素使用扁平形态（`weight`、`topologyKey`、`namespaceSelector`、`labelSelector`、`matchLabelKeys`、`namespaces`），`required` 元素使用术语字段；验证字段顺序、条目数、`preferred` 元素被归一化为两个键、术语字段进入 `podAffinityTerm`、`namespaces` 的 `aaa bbb` 被拆分为 `aaa`、`bbb`。
- 选择性有效输入：验证 `preferred` 元素已含 `podAffinityTerm` 时其余字段合并进该 map 且同名键以已有值为准；`required` 元素原样透传；短键 `preferred`、`required` 与两个 `*Alias` 单独出现时返回空字符串；两个字段为空 array 或含 `null`、空 map 元素时不产生对应输出。
- 关键失败输入：字段为 map、string、数字；元素为 string、数字、布尔、array；`preferred` 元素 `weight` 缺失、`null`、空字符串、`"11"`、`1.5`、bool、map、array；`podAffinityTerm` 为非 map；元素只有 `weight`；元素只含 `weight` 与 `podAffinityTerm: {}`；逐一验证渲染中断，并断言本层错误前缀为 `[definitions.podAntiAffinity]`，依赖层错误消息保持原有前缀未被改写。
- 静态检查：`_PodAntiAffinity.tpl` 无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、字段注释紧邻对应处理闭环、文件末尾单换行；`_PodAffinity.tpl` 与 `_Affinity.tpl` 内容未被修改。
