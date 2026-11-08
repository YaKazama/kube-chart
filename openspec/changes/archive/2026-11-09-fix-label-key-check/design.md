# 标签键校验统一设计

## 技术目标

- capability：`base.labelKey`
- artifact-type：Kubernetes 基础值能力 + 共享结构调用方收敛
- target：`templates/base/_k8s.tpl` 中的 `define "base.labelKey"`，以及 `templates/api-resources/Definitions/_NodeSelectorTerm.tpl`、`_LabelSelectorRequirement.tpl`、`_PodAffinityTerm.tpl` 中的标签键校验区段

## 设计决策

### Decision: 统一入口与入参形态

- requirements：`校验标签键语法`
- choice：`base.labelKey` 入参改为 `list [标签键, 调用方模板名, 调用方字段路径]`，三个元素均必填且后两者必须为非空 string；模板开头校验入参为长度为 3 的 slice，标签键为 string。
- rationale：错误前缀必须由发起校验的模板决定，而 `include` 内的 `fail` 无法被调用方捕获改写，只有让校验能力自身持有调用方标识才能满足规格。把模板名与字段路径拆成两个参数，可在能力内部用 `printf "[%s] %s: %s"` 统一表达项目约定的消息格式，避免各调用方自行拼装 `[...]`。调用点共有四处（`definitions.nodeSelectorTerm`、`definitions.labelSelectorRequirement`、`definitions.podAffinityTerm` 的三个字段），统一改为该形态，其余模板不受影响。

### Decision: 校验规则与消息集中实现

- requirements：`校验标签键语法`
- choice：`base.labelKey` 自身完成 `trim`、`splitList "/"` 拆分、段数判断、名称段与前缀段正则校验、前缀 253 字符上限判断，全部失败以 `[<模板名>] <字段路径>: <原因>` 形式 `fail`；不再调用 `base.string.verify`。
- rationale：`base.string.verify` 失败时会输出自身前缀，与规格冲突；由 `base.labelKey` 直接使用 `mustRegexMatch` 搭配 `K8S.SELECTOR.KEY_NAME_FOR_APPS`、`K8S.SELECTOR.KEY_PREFIX_FOR_APPS` 判断，才能让四类失败消息全部归属调用方。原因措辞沿用当前 `definitions.nodeSelectorTerm` 的既有消息，使该模板的消息保持稳定：`'<值>' allows at most one '/' separator`、`'<值>' does not match label key name syntax`、`'<值>' does not match label key prefix syntax`、`prefix '<前缀>' exceeds 253 characters`。

### Decision: definitions.nodeSelectorTerm 收敛

- requirements：`校验 key`
- choice：删除第 141-155 行的 `splitList "/"`、两处 `mustRegexMatch` 与 253 判断，替换为一次 `include "base.labelKey" (list $key "definitions.nodeSelectorTerm" (printf "%s[%d].key" $_name $index))`；保留其前置的 `$key` 为空判断（`required field is missing or empty`）。
- rationale：`$key` 为空时的既有消息描述的是必填缺失而不是语法非法，需在调用校验能力前拦截，否则会被名称段语法消息取代，改变既有失败边界。`$_name` 与 `$index` 已在该作用域内可用，字段路径可精确到 `matchExpressions[0].key` 形式，满足“含字段名与条目下标”。

### Decision: definitions.labelSelectorRequirement 收敛

- requirements：`LabelSelectorRequirement 字段渲染`
- choice：`$key` 改由 `include "base.labelKey" (list (mustRegexReplaceAll $const.SYS.YAML_QUOTED $_keyRaw "$1") "definitions.labelSelectorRequirement" "key")` 产出，删除第 39-50 行的拆分、两次 `base.string.verify` 与 253 判断；后续 `base.field` 继续使用该返回值。
- rationale：`base.labelKey` 内部已 `trim`，去引号后直接入参即可，无需求值方重复 `trim`。该模板不再依赖 `base.string.verify`，其失败消息前缀由被委托能力的 `[base.string.verify]` 变为 `[definitions.labelSelectorRequirement]`，与规格一致。前缀超长场景的字段路径由 `key.prefix` 统一为 `key`，属本次受控的可观察变化。

### Decision: definitions.podAffinityTerm 收敛

- requirements：`校验 topologyKey`、`渲染 matchLabelKeys 与 mismatchLabelKeys`
- choice：`matchLabelKeys` 与 `mismatchLabelKeys` 的循环改为带下标 `range $index, $_item := ...`，调用改为 `include "base.labelKey" (list $_key "definitions.podAffinityTerm" (printf "%s[%d]" $kind $index))`；`topologyKey` 调用改为 `include "base.labelKey" (list (mustRegexReplaceAll $const.SYS.YAML_QUOTED $_topologyKeyRaw "$1") "definitions.podAffinityTerm" "topologyKey")`。
- rationale：该模板已使用 `base.labelKey`，但当前签名不含调用方标识，失败消息前缀为被委托能力名；补齐两个参数即可满足规格，取值、必填、去重与输出逻辑不变。数组字段需要项下标才能满足规格要求的字段路径形态，因此循环补 `$index`。

### Decision: 校验规则来源保持不变

- requirements：`校验标签键语法`
- choice：`base.labelKey` 继续从 `base.env` 读取 `K8S.SELECTOR.KEY_NAME_FOR_APPS` 与 `K8S.SELECTOR.KEY_PREFIX_FOR_APPS`，不新增或修改常量。
- rationale：`_env.tpl` 常量已是项目内标签键语法的既有来源，与其他选择器校验共用；规格只要求统一实现来源，不要求改变正则本身。

## 依赖契约

### Dependency: `base.labelKey`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`update`
- input：`list [标签键, 调用方模板名, 调用方字段路径]`；标签键为 string，可带首尾空白与可选 `<前缀>/`；模板名与字段路径为非空 string。
- output：`trim` 后且语法校验通过的标签键字符串；标签键非 string、多斜杠、名称段非法、前缀段非法或前缀超长时，以 `[<调用方模板名>] <调用方字段路径>: <原因>` 中断渲染。
- ownership：`trim`、拆分、段校验、前缀长度上限与失败消息格式由依赖层负责；调用方只负责提供原始标签键、自身模板名与精确字段路径。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：`""`
- output：可由 `fromYaml` 解析的常量 Map，`base.labelKey` 读取 `K8S.SELECTOR.KEY_NAME_FOR_APPS`、`K8S.SELECTOR.KEY_PREFIX_FOR_APPS`；调用方读取 `SYS.YAML_QUOTED`。
- ownership：常量集中定义由依赖层负责；常量键选择与调用时机由本层负责。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：调用方既有调用形式，本次不改变。
- output：可由 `fromYaml` / `fromYamlArray` 解析的 YAML 字符串；必填路径为空时中断。
- ownership：取值、别名识别与必填校验由依赖层负责；本次只调整取值之后的标签键校验调用。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：调用方既有的 `list [键名, 值, 渲染模板]` 调用形式，本次不改变。
- output：`key:` 加换行缩进的字段片段；渲染结果为空时不输出。
- ownership：序列化与空值跳过由依赖层负责；本次只调整传入 `key` 的取值来源。

### Dependency: `base.rawString`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.labelKey` 返回的标签键字符串。
- output：原字符串，非 string 输入时中断。
- ownership：类型门禁与原文输出由依赖层负责；本次不改变。

### Dependency: `base.slice.cleanup`

- availability：`existing`
- source：`templates/base/_collection.tpl`
- operation：`consume`
- input：`definitions.nodeSelectorTerm` 既有的 `list [values 数组, SPLIT.COMMA]` 调用形式。
- output：清洗后的 YAML 列表。
- ownership：拆分与去重去空由依赖层负责；本次不改变。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 返回值。
- output：布尔字符串 `"true"` / `"false"`。
- ownership：错误形态识别由依赖层负责；本次不改变。

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 返回值。
- output：布尔字符串 `"true"` / `"false"`。
- ownership：错误形态识别由依赖层负责；本次不改变。

### Dependency: `base.string.verify`

- availability：`existing`
- source：`templates/base/_validate.tpl`
- operation：`consume`
- input：本次仅保留 `definitions.podAffinityTerm` 对 `namespaces` 的 `list [命名空间名, RFC.RFC1123]` 调用；标签键校验不再使用本能力。
- output：`trim` 后且匹配的字符串；不匹配或类型非法时中断渲染。
- ownership：`trim` 与正则匹配由依赖层负责；本次不改变其调用形式，也不得让标签键校验经由本能力产生 `[base.string.verify]` 前缀消息。

### Dependency: `definitions.nodeSelectorRequirement`

- availability：`existing`
- source：`templates/api-resources/Definitions/_NodeSelectorRequirement.tpl`
- operation：`consume`
- input：`dict`，含 `key`、`operator` 与可选 `values`。
- output：可 `fromYaml` 解析为单项 map 的 YAML 字符串。
- ownership：条目渲染由依赖层负责；本次不改变委托契约。

## 代码边界

### `templates/base/_k8s.tpl`

- access：`write`
- operations：`update define "base.labelKey"`：入参改为三段 list、自带四类失败消息、移除对 `base.string.verify` 的调用、更新紧邻契约注释
- writable-scopes：`define "base.labelKey"` 块及其紧邻契约注释

### `templates/api-resources/Definitions/_NodeSelectorTerm.tpl`

- access：`write`
- operations：`update key 校验区段`：删除内联 `splitList "/"`、两处 `mustRegexMatch` 与 253 判断，改为调用 `base.labelKey`，保留空 `key` 前置失败，更新该字段注释
- writable-scopes：`if not $skip` 块内 `key（string, 必填）` 注释与其后的标签键校验语句

### `templates/api-resources/Definitions/_LabelSelectorRequirement.tpl`

- access：`write`
- operations：`update key 校验区段`：删除内联拆分、两处 `base.string.verify` 调用与 253 判断，改为由 `base.labelKey` 产出 `$key`，更新该字段注释与整体契约注释中的消息前缀说明
- writable-scopes：`key（string, 必填）` 注释至 `base.field (list "key" ...)` 之间的区段，以及整体契约注释中涉及 `base.string.verify` 前缀的句子

### `templates/api-resources/Definitions/_PodAffinityTerm.tpl`

- access：`write`
- operations：`update 三处 base.labelKey 调用`：`matchLabelKeys`、`mismatchLabelKeys` 的循环补项下标并传入字段路径，`topologyKey` 传自身模板名与字段路径，更新整体契约注释与字段注释中涉及消息前缀的表述
- writable-scopes：`matchLabelKeys`、`mismatchLabelKeys`、`topologyKey` 三个字段处理块内的标签键校验调用，以及整体契约注释中关于标签键校验的句子

### `templates/base/_env.tpl`

- access：`read`
- operations：`consume K8S.SELECTOR.KEY_NAME_FOR_APPS 与 K8S.SELECTOR.KEY_PREFIX_FOR_APPS 的运行时表达式`

## 验证设计

- 依赖边界：全部使用 `/tmp/` 最小 application Chart 装载工作区真实模板（`templates/base/*.tpl`、`_NodeSelectorTerm.tpl`、`_NodeSelectorRequirement.tpl`、`_LabelSelector.tpl`、`_LabelSelectorRequirement.tpl`、`_PodAffinityTerm.tpl`），不使用 fixture。
- 合法输入回归：分别为三个调用方提供合法标签键（无前缀、带前缀、带首尾空白），验证渲染结果与改造前一致，且 `key` 输出为 `trim` 后的原值。
- 消息归属：四个调用点分别构造多斜杠、名称段非法、前缀段非法、前缀超长与非 string 输入，验证失败消息前缀为各自模板名、字段路径为 `matchExpressions[<下标>].key`、`key`、`topologyKey` 或 `<字段名>[<下标>]`，且输出中不含 `[base.labelKey]` 或 `[base.string.verify]`。
- 唯一实现：检索 `templates/`，确认 `splitList "/"` 与 `K8S.SELECTOR.KEY_NAME_FOR_APPS`、`K8S.SELECTOR.KEY_PREFIX_FOR_APPS` 的校验用法仅出现在 `base.labelKey` 内；`templates/base/_env.tpl` 作为常量定义文件与检索排除项。
- 静态检查：四个写入文件均无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、字段注释紧邻对应处理闭环、文件末尾单换行。
