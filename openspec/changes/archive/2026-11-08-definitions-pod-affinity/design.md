# PodAffinity 共享结构设计

## 技术目标

- capability：`definitions.podAffinity`
- artifact-type：Kubernetes 共享结构命名模板（library Chart）
- target：`templates/api-resources/Definitions/_PodAffinity.tpl`

## 设计决策

### Decision: 目标文件与命名模板归属

- requirements：`渲染 PodAffinity 字段片段`
- choice：在 `templates/api-resources/Definitions/` 新建 `_PodAffinity.tpl`，定义 `definitions.podAffinity`，并在紧邻 `define` 之前写入中文整体契约注释。
- rationale：`PodAffinity` 是 `api-resources/Definitions` 层的可复用嵌套结构，文件名遵循 `_<Kind>.tpl` 约定；既有消费者 `definitions.affinity` 已按 `include "definitions.podAffinity"` 调用，且只向下传递两个规范长键的 array，本模板必须与既有调用契约一致。

### Decision: 固定字段表驱动循环

- requirements：`渲染 PodAffinity 字段片段`、`委托术语子模板`
- choice：以元素为 `dict` 的固定列表驱动处理，顺序为 `preferredDuringSchedulingIgnoredDuringExecution` 对应 `definitions.weightedPodAffinityTerm`、`requiredDuringSchedulingIgnoredDuringExecution` 对应 `definitions.podAffinityTerm`；取值使用 `base.get (list $ <键名> "" "" false false)`，显式关闭同级 `*Alias` 识别。
- rationale：两个字段的处理流程同构，字段表避免重复分支并固定 API 字段顺序；关闭别名是规格“只识别规范长键”的直接表达，短键归一化已由父级 `definitions.affinity` 完成，本层不重复。

### Decision: 数组解析与元素门禁

- requirements：`输入类型与空元素边界`
- choice：`base.get` 输出 `trim` 后为空则跳过该字段；否则 `fromYamlArray` 并用 `base.isFromYamlArrayError` 排除解析错误，错误时中断；array 为空则跳过该字段；逐元素用 `kindIs "invalid"` 判定 `null` 并跳过，用 `kindIs "map"` 判定元素形态，非 map 中断，空 map 跳过。
- rationale：字段取值经 `fromYamlArray` 成功后即保证 array，不再重复 `kindIs "slice"`；元素是未经 YAML 恢复的原始值，`kindIs` 用于此处符合解析保护规则；`kindIs "invalid"` 是项目内既有的 `null` 判定方式。

### Decision: 子模板委托与字段输出

- requirements：`委托术语子模板`
- choice：对每个有效元素执行 `include` 调用字段表指定的子模板，返回值经 `fromYaml` 与 `base.isFromYamlError` 保护后按输入顺序累加；累加结果非空时用 `base.field (list <键名> <map 列表> "base.slice")` 输出。
- rationale：元素内部结构由子模板独占，本层只做透传与错误保护；`base.slice` 承担最终类型的序列化与门禁；不引入 `mustUniq` 或额外清洗，符合规格“不合并、不去重、不去空”。

## 依赖契约

### Dependency: `definitions.weightedPodAffinityTerm`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：单个 `WeightedPodAffinityTerm` 元素 map，由父级数组元素原样传入，可包含 `weight` 与术语字段及任意未定义键。
- output：可 `fromYaml` 解析为单个 `WeightedPodAffinityTerm` map 的 YAML 字符串；无法解析时由本层中断。
- ownership：元素内部字段的取值、校验、归一化与渲染由依赖层负责；本层只负责透传、错误保护与收集。本 change 只引用该模板，不创建实现。

### Dependency: `definitions.podAffinityTerm`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：单个 `PodAffinityTerm` 元素 map，由父级数组元素原样传入，可包含 `topologyKey`、`labelSelector`、`namespaceSelector`、`matchLabelKeys`、`namespaces` 等字段及任意未定义键。
- output：可 `fromYaml` 解析为单个 `PodAffinityTerm` map 的 YAML 字符串；无法解析时由本层中断。
- ownership：元素内部字段的取值、校验、归一化与渲染由依赖层负责；本层只负责透传、错误保护与收集。本 change 只引用该模板，不创建实现。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, "preferredDuringSchedulingIgnoredDuringExecution", "", "", false, false]` 与 `list [上下文, "requiredDuringSchedulingIgnoredDuringExecution", "", "", false, false]`；关闭别名识别，不传强制类型与必填校验。
- output：可 `fromYamlArray` 解析的 YAML 字符串；路径缺失或空值时为空输出。
- ownership：数据源优先级、合并与序列化由依赖层负责；空输出判定、解析保护与失败消息由本层负责。

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 的返回值。
- output：布尔字符串 `"true"` / `"false"`。
- ownership：错误形态识别由依赖层负责；中断决策与失败消息由本层负责。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 的返回值，用于子模板输出。
- output：布尔字符串 `"true"` / `"false"`。
- ownership：错误形态识别由依赖层负责；中断决策与失败消息由本层负责。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [字段名, 子模板输出 map 列表, "base.slice"]`。
- output：`key:` 加换行缩进的字段片段；空值时不输出。
- ownership：序列化与目标类型门禁由依赖层负责；字段生效条件与输出顺序由本层负责。

### Dependency: `base.slice`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：由 `base.field` 传入的 map 列表。
- output：YAML 列表字符串；非 slice 时中断。
- ownership：列表序列化与类型门禁由依赖层负责；列表内容与顺序由本层负责。

## 代码边界

### `templates/api-resources/Definitions/_PodAffinity.tpl`

- access：`write`
- operations：`add define "definitions.podAffinity"`、`add 紧邻 define 之前的中文整体契约注释`、`add 字段级中文注释`
- writable-scopes：新建文件全部内容

### `templates/api-resources/Definitions/_Affinity.tpl`

- access：`read`
- operations：消费 `definitions.podAffinity` 的既有调用契约；不修改

### `templates/base/_get.tpl`

- access：`read`
- operations：消费 `base.get`

### `templates/base/_convert.tpl`

- access：`read`
- operations：消费 `base.isFromYamlError`、`base.isFromYamlArrayError`

### `templates/base/_field.tpl`

- access：`read`
- operations：消费 `base.field`

### `templates/base/_types.tpl`

- access：`read`
- operations：消费 `base.slice`

## 验证设计

- 最小有效：`/tmp/` 最小 application Chart，两个 unavailable 子模板使用同名回显 fixture；只提供 `preferredDuringSchedulingIgnoredDuringExecution` 单元素，验证输出只含该字段，且 fixture 收到的上下文与输入元素逐键一致。
- 较完整有效：同一 fixture 下同时提供两个字段各两个元素，验收稿示例中的 `weight`、`topologyKey`、`namespaceSelector`、`labelSelector`、`matchLabelKeys`、`namespaces` 原样透传；验证输出字段顺序为 preferred 在前、条目数与有效元素数一致、元素内部字段未被改写。
- 空值与跳过：两个字段为空 array、元素为 `null` 与空 map，验证这些字段或元素不产生输出；两个字段都无有效内容时返回空字符串。
- 关键失败：字段为 map、string 或数字；元素为 string、数字、布尔或 array；fixture 返回非 YAML 内容。逐一验证渲染中断且错误信息含 `[definitions.podAffinity]`、字段名与元素下标。
- 键识别边界：只提供 `preferred`、`required` 与两个 `*Alias` 键时返回空字符串。
- 依赖边界：两个子模板当前不可用，全部验证以同名 fixture 提供，fixture 原样回显上下文；只证明本模板的取值、元素门禁、透传与输出行为，不构成真实依赖集成通过的证据。
