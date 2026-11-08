# PodAffinityTerm 共享结构设计

## 技术目标

- capability：`definitions.podAffinityTerm`
- artifact-type：Kubernetes 共享结构命名模板 + Kubernetes 基础值能力
- target：`templates/api-resources/Definitions/_PodAffinityTerm.tpl` 中的 `define "definitions.podAffinityTerm"`；`templates/base/_k8s.tpl` 中的 `define "base.labelKey"`

## 设计决策

### Decision: 目标文件与命名模板归属

- requirements：`渲染 PodAffinityTerm 字段片段`
- choice：新增 `templates/api-resources/Definitions/_PodAffinityTerm.tpl`，文件内只定义 `definitions.podAffinityTerm`；标签键校验能力提升为公共模板 `base.labelKey`，写入 `templates/base/_k8s.tpl`。
- rationale：`PodAffinityTerm` 是 Kubernetes 官方共享结构，只能落在同域共享结构层 `api-resources/Definitions`，该目录现有 `_PodAffinity.tpl`、`_WeightedPodAffinityTerm.tpl` 等沿用 `_<结构名>.tpl` 与 `definitions.<能力>` 命名。标签键语法是与具体资源无关的 Kubernetes 基础值规则，跨 Definitions 复用时应归入 `base` 层；`_k8s.tpl` 已集中承载 `base.name`、`base.rfc`、`base.fieldsV1` 等同类 Kubernetes 值校验能力。

### Decision: 逐字段顺序处理

- requirements：`渲染 PodAffinityTerm 字段片段`
- choice：六个字段各自独立成块，按 `labelSelector`、`matchLabelKeys`、`mismatchLabelKeys`、`namespaceSelector`、`namespaces`、`topologyKey` 的顺序依次完成“取值 → 解析 → 错误保护或类型门禁 → 归一化 → `base.field` 渲染”闭环后再处理下一字段；不使用字段表与 `range` 派发。
- rationale：每个字段的入参类型、失败边界、归一化方式和渲染模板均不相同，逐字段书写使每个字段的可观察行为在一处完整可读，不依赖 `mode` 字符串间接路由；这是 `helm-templates.md` 对字段闭环顺序的直接要求，也避免同一 `range` 体内多分支降低可读性。

### Decision: 选择器字段的取值、委托与空值跳过

- requirements：`渲染 labelSelector 与 namespaceSelector`
- choice：`base.get` 以 `list [上下文, 键名]` 取值并 trim；空输出直接跳过；非空时 `fromYaml` 恢复，`base.isFromYamlError` 判定为错误时 `fail`（不是 map）；恢复后为空 map 跳过；非空 map 只读委托 `definitions.labelSelector`，返回值经 `fromYaml` 与 `base.isFromYamlError` 保护后以 `base.field` 搭配 `base.map` 输出。
- rationale：`base.get` 对空 map 返回可解析的 YAML 文本，因此必须解析后按恢复值判空，不能比较返回字符串。`fromYaml` 成功只保证不是解析错误，标量取值仍可能恢复为 string，因此保留 `kindIs "map"` 判定。委托上下文只读，不使用 `mustDeepCopy`。

### Decision: 标签键校验公共能力

- requirements：`校验 topologyKey`、`渲染 matchLabelKeys 与 mismatchLabelKeys`
- choice：新增 `base.labelKey`，入参为 string；先 `kindOf` 类型门禁，再 `trim`，再按单斜杠 `splitList` 拆分，段数超 2 时 `fail`；用 `base.string.verify` 搭配 `K8S.SELECTOR.KEY_NAME_FOR_APPS` 校验名称段；存在前缀段时用 `base.string.verify` 搭配 `K8S.SELECTOR.KEY_PREFIX_FOR_APPS` 校验并在长度超过 253 时 `fail`；通过后返回 trim 后的原值。
- rationale：`topologyKey`、`matchLabelKeys`、`mismatchLabelKeys` 三处使用同一套标签键规则，而该规则与具体资源无关，提升到 `base` 后同域其他结构也能复用。常量与校验方式复用 `base.env` 既有 `KEY_NAME_FOR_APPS`、`KEY_PREFIX_FOR_APPS` 与 `base.string.verify`，与本项目既有标签键规则一致，不修改 `_env.tpl`；`trim` 下沉到公共能力后调用方不再重复处理首尾空白。

### Decision: topologyKey 必填取值与类型门禁

- requirements：`校验 topologyKey`
- choice：`base.get` 以 `list [上下文, "topologyKey", "", "", true]` 必填取值并保留默认别名识别；trim 后用 `fromYaml (printf "v: %s")` 还原标量类型，取值不是 string 时 `fail`；再用 `SYS.YAML_QUOTED` 剥离外层引号并交由 `base.labelKey` 校验；最后以 `base.field` 搭配 `base.rawString` 输出。
- rationale：必填判定与 `topologyKeyAlias` 识别由 `base.get` 承担；`v: <原文>` 还原是区分“字符串”与“布尔、数值、map、list”的唯一可靠方式，与本项目既有标签键字段处理一致。`base.rawString` 不改写取值；去引号后的 `trim` 由 `base.labelKey` 内部承担，调用方不重复。

### Decision: 键数组的归一化与去重

- requirements：`渲染 matchLabelKeys 与 mismatchLabelKeys`
- choice：`base.get` 取值后 `fromYamlArray` 恢复，`base.isFromYamlArrayError` 判定为错误时 `fail`（不是 array）；逐项 `toString` 后 `trim`，空项跳过，非空项经 `base.labelKey` 校验；结果 `mustUniq` 去重，非空时以 `base.field` 搭配 `base.slice` 输出。
- rationale：`base.get` 对数组返回顶层 YAML 序列，必须用 `fromYamlArray` 与 `base.isFromYamlArrayError` 恢复，不能使用 `fromYaml`。键不允许按分隔符拆分，因此不复用 `base.slice.cleanup` 的拆分能力；调用方先 `trim` 再判空，使纯空白项按空项跳过而不是进入校验失败；去重使用 Spig `mustUniq`，不实现自建算法。

### Decision: namespaces 的拆分、校验与去重

- requirements：`渲染 namespaces`
- choice：`base.get` 取值后 `fromYamlArray` 恢复，`base.isFromYamlArrayError` 判定为错误时 `fail`；先用 `base.slice.cleanup` 的 `list [数据, SPLIT.SPACE_COMMA]` 完成按逗号或空白拆分、逐项 trim、去重与剔除空项；再对清洗结果逐项调用 `base.string.verify` 搭配 `RFC.RFC1123` 校验命名空间名；最后 `mustUniq` 去重并经 `toStrings` 归一为 string 列表（`base.slice.cleanup` 会把纯数字字符串转 int），非空时以 `base.field` 搭配 `base.slice` 输出。
- rationale：`base.slice.cleanup` 内部先拆分、再对每个拆分结果跑校验正则、最后才剔除空项，而 `SPLIT.SPACE_COMMA` 在首尾分隔符处会产生空项，空项无法通过 RFC1123；因此校验必须在其清洗完成之后由本层逐项执行，不能合并为第三个参数。分隔符与去重去空仍由 `base.env` 常量与 `base.slice.cleanup` 提供，本层不内联正则也不自建清洗循环。`toStrings` 只用于修正数字字符串自动转 int 的语义，保证输出为 string array 满足 API 类型。

### Decision: 返回值形态

- requirements：`渲染 PodAffinityTerm 字段片段`
- choice：模板输出由已生效字段组成的 YAML 字段片段，调用方以 `fromYaml` 回收为单个 `PodAffinityTerm` map；字段顺序固定为 `labelSelector`、`matchLabelKeys`、`mismatchLabelKeys`、`namespaceSelector`、`namespaces`、`topologyKey`。
- rationale：调用方 `definitions.podAffinity` 与 `definitions.weightedPodAffinityTerm` 均按 `include ... | fromYaml` 消费本能力并取单项 map；字段顺序与本 change 已确认的 K8s 官方文档字段表顺序一致。

## 依赖契约

### Dependency: `definitions.labelSelector`

- availability：`existing`
- source：`templates/api-resources/Definitions/_LabelSelector.tpl`
- operation：`consume`
- input：`dict`，即 `labelSelector` 或 `namespaceSelector` 原值 map，可含 `matchExpressions`、`matchLabels` 及其同级别名。
- output：可 `fromYaml` 解析为 `LabelSelector` map 的 YAML 字符串；无法解析时本层中断，返回空内容时本层不输出该字段。
- ownership：`matchExpressions` 简写解析、`matchLabels` 校验与内部字段渲染由依赖层负责；本层只负责取值、空值跳过、map 判定、委托与错误保护。

### Dependency: `definitions.podAffinity`

- availability：`existing`
- source：`templates/api-resources/Definitions/_PodAffinity.tpl`
- operation：`consume`
- input：`requiredDuringSchedulingIgnoredDuringExecution` 的单个数组元素，由该层原样委托。
- output：无，本模板只消费其调用契约。
- ownership：字段取值形状与数组遍历由调用方负责；本模板只按 `PodAffinityTerm` 契约渲染传入的 map。

### Dependency: `definitions.weightedPodAffinityTerm`

- availability：`existing`
- source：`templates/api-resources/Definitions/_WeightedPodAffinityTerm.tpl`
- operation：`consume`
- input：`dict`，其中 `podAffinityTerm` 键的取值为本模板的入参 map。
- output：无，本模板只消费其调用契约。
- ownership：`weight` 校验与上下文构造由调用方负责；本模板只渲染 `podAffinityTerm` 内的术语字段。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：两种调用形式：① `list [上下文, 键名]`，非必填并保持别名默认开启；② `list [上下文, "topologyKey", "", "", true]`，必填并保持别名默认开启。
- output：可 `fromYaml` / `fromYamlArray` 解析的 YAML 字符串；路径缺失、为 `null` 或为空字符串时为空输出；必填路径为空时中断。
- ownership：数据源优先级、别名识别、必填校验与序列化由依赖层负责；取值形式选择、空输出判定、类型门禁与失败消息由本层负责。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：`""`
- output：可由 `fromYaml` 解析的常量 Map；本模板直接读取 `SPLIT.SPACE_COMMA`、`RFC.RFC1123`、`SYS.YAML_QUOTED`，`base.labelKey` 另读 `K8S.SELECTOR.KEY_NAME_FOR_APPS`、`K8S.SELECTOR.KEY_PREFIX_FOR_APPS`。
- ownership：常量集中定义由依赖层负责；常量键选择与调用时机由调用方负责。

### Dependency: `base.labelKey`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`add`
- input：string 标签键，可带 `<prefix>/` 前缀；纯空白或空字符串视为不匹配。
- output：`trim` 后且语法校验通过的标签键字符串；非 string、多斜杠、段语法非法或前缀超长时中断渲染。
- ownership：类型门禁、`trim`、单斜杠拆分、名称段与前缀段语法校验、前缀长度上限由依赖层负责；本模板只负责在 `topologyKey` 去引号后与键数组逐项 `trim` 后调用，并依赖其失败中断传播。

### Dependency: `base.slice.cleanup`

- availability：`existing`
- source：`templates/base/_collection.tpl`
- operation：`consume`
- input：`list [namespaces 数组, SPLIT.SPACE_COMMA]`。
- output：按逗号或空白拆分、逐项 trim、去重并剔除空项后的 YAML 列表（纯数字字符串会转为 int）；不执行任何正则校验，因此不会因拆分产生的空项中断。
- ownership：拆分、trim、去重与去空由依赖层负责；分隔符选择、校验时机与结果类型归一由本层负责。

### Dependency: `base.string.verify`

- availability：`existing`
- source：`templates/base/_validate.tpl`
- operation：`consume`
- input：`list [命名空间名, RFC.RFC1123]`，逐个 `namespaces` 清洗结果调用；标签键段校验由 `base.labelKey` 内部承担。
- output：trim 后且匹配的字符串；不匹配或类型非法时中断渲染。
- ownership：trim 与正则匹配由依赖层负责；调用时机与顺序由本层负责。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [键名, 值, 渲染模板]`，`labelSelector` 与 `namespaceSelector` 使用 `base.map`，`matchLabelKeys`、`mismatchLabelKeys`、`namespaces` 使用 `base.slice`，`topologyKey` 使用 `base.rawString`。
- output：`key:` 加换行缩进的字段片段；渲染结果为空时不输出。
- ownership：序列化、枚举校验与空值跳过由依赖层负责；字段生效条件、键名与渲染模板选择由本层负责。

### Dependency: `base.slice`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：已归一化的 string 列表。
- output：YAML 列表字符串；非 slice 输入时中断。
- ownership：slice 类型门禁与序列化由依赖层负责；字段生效条件与输出键名由本层负责。

### Dependency: `base.map`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：`definitions.labelSelector` 的恢复结果。
- output：YAML map 字符串；非 map 输入时中断。
- ownership：map 类型门禁与序列化由依赖层负责；字段生效条件与输出键名由本层负责。

### Dependency: `base.rawString`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：已校验的 `topologyKey` 字符串。
- output：原字符串，不做 trim 或零折叠；非 string 输入时中断。
- ownership：类型门禁与原文输出由依赖层负责；取值校验与键名由本层负责。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 返回值，用于选择器恢复结果与委托返回值。
- output：布尔字符串 `"true"` / `"false"`。
- ownership：错误形态识别由依赖层负责；失败消息与中断决策由本层负责。

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 返回值，用于 `matchLabelKeys`、`mismatchLabelKeys`、`namespaces` 的恢复结果。
- output：布尔字符串 `"true"` / `"false"`。
- ownership：错误形态识别由依赖层负责；失败消息与中断决策由本层负责。

## 代码边界

### `templates/api-resources/Definitions/_PodAffinityTerm.tpl`

- access：`write`
- operations：`add define "definitions.podAffinityTerm"`、`add 紧邻 define 之前的中文整体契约注释`、`add 字段级中文注释`
- writable-scopes：`define "definitions.podAffinityTerm"` 块及其紧邻契约注释

### `templates/base/_k8s.tpl`

- access：`write`
- operations：`add define "base.labelKey"`、`add 紧邻 define 之前的中文契约注释`
- writable-scopes：`define "base.labelKey"` 块及其紧邻契约注释

### `templates/api-resources/Definitions/_LabelSelector.tpl`

- access：`read`
- operations：`consume definitions.labelSelector 的入参边界、必填 matchLabels 约束与返回值形态`

### `templates/api-resources/Definitions/_PodAffinity.tpl`

- access：`read`
- operations：`consume definitions.podAffinity 对 definitions.podAffinityTerm 的调用契约`

### `templates/api-resources/Definitions/_WeightedPodAffinityTerm.tpl`

- access：`read`
- operations：`consume definitions.weightedPodAffinityTerm 对本模板的调用契约`

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume base.get 的调用形式、必填语义、别名开关与空输出边界`

### `templates/base/_env.tpl`

- access：`read`
- operations：`consume SPLIT.SPACE_COMMA、RFC.RFC1123、SYS.YAML_QUOTED 的运行时表达式`

### `templates/base/_collection.tpl`

- access：`read`
- operations：`consume base.slice.cleanup 的入参形态、拆分与去重去空顺序、数字字符串转 int 行为`

### `templates/base/_validate.tpl`

- access：`read`
- operations：`consume base.string.verify 的 trim、类型与正则失败行为`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume base.field 的调用形式、渲染模板路由与空值输出行为`

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume base.slice 与 base.map 的类型门禁与序列化行为`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume base.rawString、base.isFromYamlError、base.isFromYamlArrayError 的返回形态`

## 验证设计

- 依赖边界：`definitions.labelSelector`、`base.labelKey` 均为当前工作区真实实现，验证在 `/tmp/` 最小 application Chart 中装载真实模板文件，不使用 fixture；`definitions.podAffinity` 与 `definitions.weightedPodAffinityTerm` 不作为本模板的调用依赖参与验证。
- 最小有效输入：只提供 `topologyKey: zone`，验证输出只含 `topologyKey`。
- 较完整有效输入：提供用户示例中的六字段，验证输出顺序为 `labelSelector`、`matchLabelKeys`、`mismatchLabelKeys`、`namespaceSelector`、`namespaces`、`topologyKey`；`namespaces` 的 `aaa bbb` 拆分为 `aaa`、`bbb`；`matchLabelKeys: []` 不输出。
- 选择性有效输入：分别验证 `labelSelector`/`namespaceSelector` 缺失、`null`、空 map 时不输出；`matchLabelKeys`/`mismatchLabelKeys` 重复项与空字符串项被去重去空；`namespaces` 逗号分隔、首尾与中间空白项、重复项被正确清洗；`topologyKeyAlias` 覆盖 `topologyKey`、空 `labelSelectorAlias` 回退 `labelSelector`；`topologyKey` 带首尾空白时输出 trim 后的值。
- 关键失败输入：`topologyKey` 缺失、`null`、空字符串、布尔、数值、map、list、`-zone`、`zone-`、`Zone Key`、`a/b/c`、名称段 64 字符；`labelSelector` 为字符串或 list；`matchLabelKeys` 为字符串或 map、含 `-app` 或 `a/b/c`；`namespaces` 为字符串或 map、含 `Bad_Name` 或 `-bad`，逐一验证渲染中断并断言错误前缀包含 `[base.get]`、`[base.labelKey]`、`[base.string.verify]` 或 `[definitions.podAffinityTerm]` 与字段名。
- 静态检查：两个写入文件均无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、字段注释紧邻对应处理闭环、文件末尾单换行。
