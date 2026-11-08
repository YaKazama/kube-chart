# affinity 子模板写法重构设计

## 技术目标

- capability：`definitions.affinity`、`definitions.nodeAffinity`、`definitions.podAffinity`、`definitions.nodeSelectorTerm`
- artifact-type：Kubernetes 共享结构命名模板内部重构
- target：`templates/api-resources/Definitions/_Affinity.tpl` 中的 `define "definitions.affinity"` 与新增 `define "definitions.affinity.schedulingTerm"`；`_NodeAffinity.tpl` 中的 `define "definitions.nodeAffinity"` 与新增 `define "definitions.nodeAffinity.matchList"`；`_PodAffinity.tpl` 中的 `define "definitions.podAffinity"` 与新增 `define "definitions.podAffinity.termList"`、`define "definitions.podAffinity.weightedTermList"`、`define "definitions.podAffinity.weightedTerm"`；`_NodeSelectorTerm.tpl` 中的 `define "definitions.nodeSelectorTerm"` 与新增 `define "definitions.nodeSelectorTerm.requirementList"`

## 设计决策

### Decision: 逐字段展开的判据

- requirements：本 change 无规格增量，约束来自 draft 的「需求」与「约束」
- choice：唯一需要消除的写法是「先构造 `list`（元素为字段表 `dict` 或字段名字符串），再用 `range` 遍历并派发」。改造后每个字段的处理以独立语句块书写，块内自成“取值 → 解析 → 错误保护或类型门禁 → 归一化 → `base.field` 渲染”闭环。
- rationale：字段表把每个字段的真实类型、失败边界与归一化方式隐藏在 `kind` / `template` / `mode` 字符串里，读者必须来回跳转才能确认某个字段的行为；逐块书写使每个字段的可观察行为在一处完整可读。这是 draft 明确要求的写法方向，替换依据是结构形态，不是行数。

### Decision: 累加型 `list` 变量保持不变

- requirements：draft「需求」中累加变量条目
- choice：`$terms`、`$rendered`、`$requirements`、`$values`、`$matchLabelKeys`、`$mismatchLabelKeys`、`$namespaces` 等以 `list` 初始化后逐项 `mustAppend` 的变量保持原样；只有被 `range` 遍历以派发字段的 `list` 才消除。
- rationale：这些变量承载逐项收集结果，`range` 遍历的是数据而不是字段定义；消除它们等于放弃数组渲染，会直接改变行为。

### Decision: definitions.affinity 三子结构展开

- requirements：draft「需求」中 `_Affinity.tpl` 条目
- choice：`nodeAffinity`、`podAffinity`、`podAntiAffinity` 三段各自独立展开，每段显式调用 `definitions.affinity.schedulingTerm` 两次，分别传 `preferred` 与 `preferredDuringSchedulingIgnoredDuringExecution`、`required` 与 `requiredDuringSchedulingIgnoredDuringExecution`；归一化结果非空时委托对应子模板并以 `base.field` 输出。
- rationale：`$substructures` 与 `$keyPairs` 双层 `range` 是当前派发链路的核心；三层嵌套 `range` 使 `$kind`、`$_pair` 与真实字段失去对应关系。展开后每段的子结构名、子模板名与字段路径均为字面量，六段重复的短长键归一化由同文件辅助模板统一承担，失败消息文本与现状逐字一致。

### Decision: definitions.nodeAffinity 两模式与两字段展开

- requirements：draft「需求」中 `_NodeAffinity.tpl` 条目
- choice：`preferredDuringSchedulingIgnoredDuringExecution` 与 `requiredDuringSchedulingIgnoredDuringExecution` 各写一段；每段内 `matchExpressions` 与 `matchFields` 各显式调用一次 `definitions.nodeAffinity.matchList`；`weight` 仅在 preferred 段出现一次。
- rationale：当前实现用 `$fields` 表选择子模板名 `definitions.preferredSchedulingTerm` 或 `definitions.nodeSelector` 与委托形态（逐项数组或包裹 `nodeSelectorTerms`），并用 `range $_name := list "matchExpressions" "matchFields"` 派发两个字段。展开后每段的委托模板名与包裹形态均为字面量，四段重复的两字段归一化由同文件辅助模板统一承担，`kindOf` 门禁、weight 标量校验与空集合跳过的时机保持不变。

### Decision: definitions.podAffinity 两字段展开

- requirements：draft「需求」中 `_PodAffinity.tpl` 条目
- choice：`preferredDuringSchedulingIgnoredDuringExecution` 与 `requiredDuringSchedulingIgnoredDuringExecution` 各写一段，每段显式调用一次本文件专属的数组辅助模板：preferred 调用 `definitions.podAffinity.weightedTermList`，required 调用 `definitions.podAffinity.termList`；两者入参均为 `list [上下文, 字段名, 元素处理模板名]`，元素处理模板名分别为 `definitions.weightedPodAffinityTerm` 与 `definitions.podAffinityTerm`。preferred 的元素预处理（`weight` 文本整数校验、`podAffinityTerm` 合并与合并后非空判定）全部下沉到同文件 `definitions.podAffinity.weightedTerm`。
- rationale：`$fields` 表用 `mode` 区分两种归一化路径与不同子模板名，这正是需要消除的间接路由。若把 preferred 的元素预处理留在主模板内，主模板就必须自己承担取值与元素循环，辅助模板将只剩形式意义。把两种元素形态拆成两个独立辅助模板（`termList` 原样委托、`weightedTermList` 先归一化再委托）使调用点在书写期即确定走哪条路径，不保留任何根据参数为空与否选择行为的运行期分支；代价是元素遍历、跳过与 `base.field` 输出骨架重复两份，这是 draft 要求优先保证直白可读的可接受代价。行为与消息文本与现状逐字一致。

### Decision: 同文件辅助模板统一处理重复

- requirements：draft「需求」中重复片段条目与「约束」中重复处理条目
- choice：按文件新增以主能力为前缀的辅助定义，只服务于本文件：`_Affinity.tpl` 新增 1 个，`_NodeAffinity.tpl` 新增 1 个，`_PodAffinity.tpl` 新增 3 个，`_NodeSelectorTerm.tpl` 新增 1 个，合计 6 个：
  - `definitions.affinity.schedulingTerm`：入参 `list [子结构 map, 子结构名, 短键, 长键]`，完成短键与长键的 `base.get` 取值、非 array 中断、短键非空优先与长键回退，返回可 `fromYamlArray` 解析的数组文本或空字符串；同一文件内被三次子结构 × 两组键共六次显式 `include`。
  - `definitions.nodeAffinity.matchList`：入参 `list [元素 map, 子结构名, 字段名, 下标]`，完成单个 `matchExpressions` 或 `matchFields` 的 `base.get` 取值、解析为 array、array 门禁与空集合跳过，返回可 `fromYamlArray` 解析的数组文本或空字符串；不解析也不校验数组元素内部结构，元素校验由 `definitions.nodeSelectorRequirement` 负责。被 preferred 与 required 两段各两次共四次显式 `include`。
  - `definitions.podAffinity.termList`：入参 `list [上下文, 字段名, 元素处理模板名]`，完成 `base.get` 取值、array 门禁、元素 `kindIs "map"` 与非 map 中断与空 map 跳过、以元素本体逐项委托元素处理模板、返回值错误保护与 `base.field` 输出；被 required 字段显式 `include` 一次。
  - `definitions.podAffinity.weightedTermList`：入参与结构与 `termList` 相同，差别是每个有效元素先经 `definitions.podAffinity.weightedTerm` 归一化为只含 `weight` 与 `podAffinityTerm` 的上下文再委托；被 preferred 字段显式 `include` 一次。
  - `definitions.podAffinity.weightedTerm`：入参 `list [元素 map, 子结构名, 下标]`，完成 `weight` 必填取值与整数形态校验、`podAffinityTerm` 合并（`mustDeepCopy` + `unset` + `mustMerge`）与合并后非空判定，返回恒含 `weight` 与 `podAffinityTerm` 两个键的 map 文本；被 `definitions.podAffinity.weightedTermList` 调用。
  - `definitions.nodeSelectorTerm.requirementList`：入参 `list [上下文, 字段名]`，完成取值、array 门禁、条目类型判定（string 简写主正则解析与原生 map 取值）、`key` 与 `operator` 与 `values` 校验、去重与委托 `definitions.nodeSelectorRequirement`，返回渲染后的 requirement 数组文本或空字符串；被两个字段各一次共两次显式 `include`。
- rationale：draft 要求重复片段由同文件内新增辅助命名模板统一处理，且明确不得跨文件抽取。去重靠两种方式实现：字段名固定为入参且每个字段一处显式 `include`（`schedulingTerm`、`matchList`、`termList`、`requirementList`），或同构逻辑仅差上下文预处理时拆为两个辅助模板（`termList` 与 `weightedTermList`）并把归一化下沉到第三个辅助模板（`weightedTerm`）。两种方式都不保留根据参数为空与否选择行为的运行期分支。辅助模板只服务本文件、不得被其他文件引用，因此不会扩张 `base` 层或跨 Definitions 的公共契约。
- tradeoff：命名模板之间只能传递字符串，因此每个新增辅助模板引入一次「`toYamlPretty` 序列化 → 调用方 `fromYaml` / `fromYamlArray` 恢复」往返；`definitions.podAffinity.weightedTerm` 由 `definitions.podAffinity.weightedTermList` 调用时同样多一次往返。该开销是本 change 用去重换取可读性的已知代价，不改变任何可观察行为；若后续成为性能瓶颈，应在规格层面重新权衡而非临时内联。

### Decision: definitions.nodeSelectorTerm 两字段展开

- requirements：draft「需求」中 `_NodeSelectorTerm.tpl` 条目与「约束」中重复处理条目
- choice：`matchExpressions` 与 `matchFields` 各写一段，每段显式调用一次 `definitions.nodeSelectorTerm.requirementList`，结果非空时以 `base.field` 搭配 `base.slice` 按固定顺序输出。
- rationale：当前实现用 `$names := list "matchExpressions" "matchFields"` 驱动两次 `range`，字段名在循环内才确定。展开后两个字段各有独立调用点与输出语句，条目归一化与校验的重复逻辑由同文件辅助模板统一承担，失败消息中的字段名仍由入参决定，文本与现状逐字一致。

### Decision: 失败消息与失败时机逐字保留

- requirements：draft「约束」中行为不变条目与「验收」
- choice：所有 `fail` 消息文本、模板名前缀、字段路径拼接（含条目下标）与触发顺序按当前实现逐字保留；不新增、不删除、不重排任何校验。
- rationale：本 change 不产生规格增量，行为基准是各模板的归档规格。消息文本属于用户可见输出，重构中任何措辞或顺序变化都会使归档规格失效。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：各模板现有的调用形式，包括 `list [上下文, 键名]`、`list [上下文, 键名, "", "", false, false]`（关闭别名）与 `list [上下文, "weight"]`（保留别名）。
- output：可 `fromYaml` / `fromYamlArray` 解析的 YAML 字符串；必填路径为空时中断。
- ownership：取值优先级、别名识别、必填校验与序列化由依赖层负责；本层只负责调用位置与参数不变。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：`""`
- output：常量 Map；`_PodAffinity.tpl` 读取 `TYPES.INT`，`_NodeSelectorTerm.tpl` 读取 `K8S.SELECTOR.NODE_TERM_FOR_APPS`、`K8S.SELECTOR.NODE_TERM_VALUES_FOR_APPS`、`SPLIT.COMMA`、`SYS.YAML_QUOTED`、`TYPES.INT`。
- ownership：常量定义由依赖层负责；本层不新增或修改常量键。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [键名, 值, "base.slice" 或 "base.map"]`。
- output：`key:` 加换行缩进的字段片段；渲染结果为空时不输出。
- ownership：序列化与空值跳过由依赖层负责；本层只负责字段名与渲染模板选择不变。

### Dependency: `base.slice`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：已归一化的数组。
- output：YAML 列表字符串；非 slice 输入时中断。
- ownership：slice 类型门禁与序列化由依赖层负责。

### Dependency: `base.map`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：已归一化的 map。
- output：YAML map 字符串；非 map 输入时中断。
- ownership：map 类型门禁与序列化由依赖层负责。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 返回值。
- output：布尔字符串 `"true"` / `"false"`。
- ownership：错误形态识别由依赖层负责。

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 返回值。
- output：布尔字符串 `"true"` / `"false"`。
- ownership：错误形态识别由依赖层负责。

### Dependency: `base.slice.cleanup`

- availability：`existing`
- source：`templates/base/_collection.tpl`
- operation：`consume`
- input：`list [values 数组, SPLIT.COMMA]`，由 `_NodeSelectorTerm.tpl` 原生 map 条目使用。
- output：清洗后的 YAML 列表。
- ownership：拆分、trim 与去重去空由依赖层负责。

### Dependency: `base.labelKey`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：`list [标签键, "definitions.nodeSelectorTerm", "<字段名>[<下标>].key"]`。
- output：`trim` 后且校验通过的标签键；语法非法时按调用方前缀中断。
- ownership：标签键语法校验与消息前缀由依赖层负责；本层只负责传入的字段路径仍由真实字段名与下标拼出。

### Dependency: `definitions.nodeAffinity`

- availability：`existing`
- source：`templates/api-resources/Definitions/_NodeAffinity.tpl`
- operation：`consume`
- input：`dict`，含归一化后的两个规范长键。
- output：可 `fromYaml` 解析为 `NodeAffinity` map 的 YAML 字符串。
- ownership：`definitions.affinity` 只负责取值、短键归一化与委托；本次不改变调用契约。

### Dependency: `definitions.podAffinity`

- availability：`existing`
- source：`templates/api-resources/Definitions/_PodAffinity.tpl`
- operation：`consume`
- input：`dict`，含归一化后的两个规范长键。
- output：可 `fromYaml` 解析为 `PodAffinity` map 的 YAML 字符串。
- ownership：同上。

### Dependency: `definitions.podAntiAffinity`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`dict`，含归一化后的两个规范长键。
- output：可 `fromYaml` 解析为 `PodAntiAffinity` map 的 YAML 字符串。
- ownership：`definitions.affinity` 只按名称委托，不创建该模板；本 change 不实现它，验证时使用同名 fixture。

### Dependency: `definitions.preferredSchedulingTerm`

- availability：`existing`
- source：`templates/api-resources/Definitions/_PreferredSchedulingTerm.tpl`
- operation：`consume`
- input：`dict`，含 `weight` 与 `preference`。
- output：可 `fromYaml` 解析为单项 map 的 YAML 字符串。
- ownership：`definitions.nodeAffinity` 只负责构造上下文与错误保护。

### Dependency: `definitions.nodeSelector`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`dict`，含 `nodeSelectorTerms` 数组。
- output：可 `fromYaml` 解析为 `NodeSelector` map 的 YAML 字符串。
- ownership：`definitions.nodeAffinity` 只负责包裹与委托；本 change 不实现它，验证时使用同名 fixture。

### Dependency: `definitions.weightedPodAffinityTerm`

- availability：`existing`
- source：`templates/api-resources/Definitions/_WeightedPodAffinityTerm.tpl`
- operation：`consume`
- input：`dict`，恒含 `weight` 与 `podAffinityTerm`。
- output：可 `fromYaml` 解析为单项 map 的 YAML 字符串。
- ownership：`definitions.podAffinity` 只负责构造上下文与错误保护。

### Dependency: `definitions.podAffinityTerm`

- availability：`existing`
- source：`templates/api-resources/Definitions/_PodAffinityTerm.tpl`
- operation：`consume`
- input：`dict`，即术语字段 map。
- output：可 `fromYaml` 解析为单项 map 的 YAML 字符串。
- ownership：`definitions.podAffinity` 只负责原样透传与错误保护。

### Dependency: `definitions.nodeSelectorRequirement`

- availability：`existing`
- source：`templates/api-resources/Definitions/_NodeSelectorRequirement.tpl`
- operation：`consume`
- input：`dict`，含 `key`、`operator` 与可选 `values`。
- output：可 `fromYaml` 解析为单项 map 的 YAML 字符串。
- ownership：`definitions.nodeSelectorTerm` 只负责条目归一化与委托。

## 代码边界

本 change 新增的四个辅助定义均写在所属主模板的同一文件内，只服务该文件，不构成跨文件依赖，因此记为本文件的 `add` operation 而非 Dependency。

### `templates/api-resources/Definitions/_Affinity.tpl`

- access：`write`
- operations：`update define "definitions.affinity"`：删除 `$substructures` 与 `$keyPairs` 两张表及其 `range`，改为三段子结构各两次显式调用辅助模板；`add define "definitions.affinity.schedulingTerm"` 与紧邻契约注释；更新主模板紧邻契约注释中的“同构处理”表述
- writable-scopes：`define "definitions.affinity"` 块内 `$substructures` 与 `$keyPairs` 定义及其派发结构、该块紧随的契约注释，以及新增的 `define "definitions.affinity.schedulingTerm"` 块与其紧邻契约注释

### `templates/api-resources/Definitions/_NodeAffinity.tpl`

- access：`write`
- operations：`update define "definitions.nodeAffinity"`：删除 `$fields` 表与其 `range`，改为 preferred 与 required 两段显式语句；删除 `range $_name := list "matchExpressions" "matchFields"`，改为四段显式调用辅助模板；`add define "definitions.nodeAffinity.matchList"` 与紧邻契约注释；更新主模板紧邻契约注释
- writable-scopes：`define "definitions.nodeAffinity"` 块内 `$fields` 定义、`range $_name := list "matchExpressions" "matchFields"` 及其派发结构、该块紧随的契约注释，以及新增的 `define "definitions.nodeAffinity.matchList"` 块与其紧邻契约注释

### `templates/api-resources/Definitions/_PodAffinity.tpl`

- access：`write`
- operations：`update define "definitions.podAffinity"`：删除 `$fields` 表与其 `range`，改为 preferred 与 required 两段显式语句并通过辅助模板输出；`add define "definitions.podAffinity.termList"` 与紧邻契约注释；`add define "definitions.podAffinity.weightedTermList"` 与紧邻契约注释；`add define "definitions.podAffinity.weightedTerm"` 与紧邻契约注释；更新主模板紧邻契约注释
- writable-scopes：`define "definitions.podAffinity"` 块内 `$fields` 定义及其派发结构、该块紧随的契约注释，以及新增的 `define "definitions.podAffinity.termList"`、`define "definitions.podAffinity.weightedTermList"`、`define "definitions.podAffinity.weightedTerm"` 块与其紧邻契约注释

### `templates/api-resources/Definitions/_NodeSelectorTerm.tpl`

- access：`write`
- operations：`update define "definitions.nodeSelectorTerm"`：删除 `$names := list "matchExpressions" "matchFields"` 与两处 `range $_name := $names`，改为两字段各一次显式调用辅助模板；`add define "definitions.nodeSelectorTerm.requirementList"` 与紧邻契约注释；更新主模板紧邻契约注释
- writable-scopes：`define "definitions.nodeSelectorTerm"` 块内 `$names` 定义、两处 `range $_name := $names` 及其派发结构、该块紧随的契约注释，以及新增的 `define "definitions.nodeSelectorTerm.requirementList"` 块与其紧邻契约注释

### `templates/base/_get.tpl`、`_env.tpl`、`_field.tpl`、`_types.tpl`、`_convert.tpl`、`_collection.tpl`、`_k8s.tpl`

- access：`read`
- operations：`consume 上述依赖契约记录的调用形式与返回边界`

### `templates/api-resources/Definitions/_PreferredSchedulingTerm.tpl`、`_WeightedPodAffinityTerm.tpl`、`_PodAffinityTerm.tpl`、`_NodeSelectorRequirement.tpl`

- access：`read`
- operations：`consume 被委托模板的入参与返回形态，用于确认逐字段展开后委托调用保持不变`

## 验证设计

- 依赖边界：`definitions.podAntiAffinity` 与 `definitions.nodeSelector` 当前不可用，验证在 `/tmp/` 最小 application Chart 中分别提供同名 fixture，fixture 原样回显入参；`definitions.nodeAffinity`、`definitions.podAffinity`、`definitions.preferredSchedulingTerm`、`definitions.weightedPodAffinityTerm`、`definitions.podAffinityTerm`、`definitions.nodeSelectorRequirement` 使用工作区真实实现。fixture 只证明本层调用与分支行为，不构成真实依赖集成通过的证据。
- 行为基准：以各模板归档规格中的 Scenario 为期望集合，逐条覆盖前缀场景，不做静态推断替代。
- `definitions.affinity`：覆盖三类子结构分别委托、只提供其一、子结构为空 map、全部缺失、短键归一化、短键优先于长键、空短键回退长键、短长键同级别名优先级、其余字段丢弃、子结构非 map、短键非 array、长键非 array、子模板返回非法 YAML。
- `definitions.nodeAffinity`：覆盖两个字段各单项与多项、元素为空 map、`matchExpressions` 与 `matchFields` 独立与同时提供、`weight` 缺失或非标量中断、元素非 map 中断、字段非 array 中断、子模板返回非法 YAML。
- `definitions.podAffinity`：覆盖两个字段各单项与多项、空 array 与空元素跳过、`weight` 缺失或非整数中断、`podAffinityTerm` 合并且已有值优先、合并结果为空中断、元素非 map 中断、字段非 array 中断、子模板返回非法 YAML。
- `definitions.nodeSelectorTerm`：覆盖 string 条目四种简写、原生 map 条目、混合与重复条目去重、空条目与空字段跳过、`key` 语法非法、`operator` 非法、`values` 与 `operator` 适用关系、条目类型非法、字段非 array、子模板返回非法 YAML。
- 失败消息一致性：逐条断言改造前后相同的模板名前缀、字段路径与原因文本。
- 结构检查：四个写入文件不再出现以字段表或字段名列表 `range` 派发的写法，也不存在「根据入参为空与否选择行为」的运行期分支；六个新增辅助定义（`definitions.affinity.schedulingTerm`、`definitions.nodeAffinity.matchList`、`definitions.podAffinity.termList`、`definitions.podAffinity.weightedTermList`、`definitions.podAffinity.weightedTerm`、`definitions.nodeSelectorTerm.requirementList`）只被各自文件 `include`，`grep -rln` 确认无其他文件引用；累加型 `list` 变量仍在；文件无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、字段注释紧邻对应处理闭环、文件末尾单换行。
