# NodeSelectorTerm 共享结构设计

## 技术目标

- capability：`definitions.nodeSelectorTerm`
- artifact-type：Kubernetes 共享结构命名模板（library Chart）
- target：`templates/api-resources/Definitions/_NodeSelectorTerm.tpl`

## 设计决策

### Decision: 目标文件与命名模板归属

- requirements：`渲染 NodeSelectorTerm 字段片段`
- choice：在 `templates/api-resources/Definitions/` 新建 `_NodeSelectorTerm.tpl`，定义 `definitions.nodeSelectorTerm`，紧邻 `define` 之前写入中文整体契约注释。
- rationale：`NodeSelectorTerm` 是 `api-resources/Definitions` 层的可复用嵌套结构，既有消费者 `definitions.preferredSchedulingTerm` 已按 `include "definitions.nodeSelectorTerm"` 调用，命名与目录必须与其契约一致。

### Decision: 新增解析正则常量

- requirements：`解析 string 条目`
- choice：在 `base.env` 的 `K8S.SELECTOR` 下新增两个常量。`NODE_TERM_FOR_APPS` 为 `(?i)^(!?)([^\s()!]+)(?:\s+(notin|in|!=|==|=|>|<)\s+(.+))?$`，四个捕获组依次为 `!` 前缀、`key`、运算符、values 原文；`NODE_TERM_VALUES_FOR_APPS` 为 `^(\([^()]*\)|[^\s,()]+)$`，限定 values 原文只能是括号列表或单个不带空白、逗号与括号的 token。
- rationale：工程规则要求项目内固定解析正则集中在 `base.env`；既有 `EQUALITY_FOR_APPS`、`SET_FOR_APPS`、`EXISTS_FOR_APPS` 都不含 `>`、`<`，无法直接复用。结构切分与 values 形态拆成两个常量后，主正则只表达“`!` + key + 可选运算符 + values 原文”，捕获组由六个降为四个，可读性与单次编译成本同时下降；`key` 取宽松 token，标签键语法不在正则内重复表达，只在 key 校验阶段判定。`(?i)` 前缀承担全表达式大小写不敏感；`notin` 排在 `in` 前、`!=`/`==` 排在 `=` 前，避免短 token 抢先匹配。

### Decision: 字段读取与数组解析

- requirements：`渲染 NodeSelectorTerm 字段片段`、`归一化条目形态`
- choice：按 `list "matchExpressions" "matchFields"` 固定顺序循环，`base.get` 非必填取值并保留默认别名识别；trim 后为空则跳过该字段，否则 `fromYamlArray` 归一化并用 `base.isFromYamlArrayError` 排除解析错误，错误时中断。
- rationale：两个字段处理完全同构，循环避免重复代码；`base.get` 返回 YAML 文本，只有 `fromYamlArray` 成功才保证数组，调用方不重复 `kindIs "slice"`；关闭别名会违反“`*Alias` 由 `base.get` 隐式处理”。

### Decision: string 条目归一化

- requirements：`解析 string 条目`
- choice：`mustRegexMatch` 命中后取四个组；`!` 与运算符同时非空时中断。运算符 token `lower` 后映射为 `In`/`NotIn`/`Gt`/`Lt`，无运算符时按 `!` 前缀映射为 `Exists`/`DoesNotExist`。values 原文先用 `NODE_TERM_VALUES_FOR_APPS` 校验形态；以 `(` 开头时要求运算符 token 属于 `in`/`notin` 并用 `trimPrefix "("` 与 `trimSuffix ")"` 取内文，否则要求 token 不属于 `in`/`notin`；两种形态都交给 `base.slice.cleanup` 并以 `SPLIT.COMMA` 清洗。
- rationale：括号一致判据必须按运算符 token 类别而非归一化后的枚举，因为 `=` 映射为 `In`、`!=` 映射为 `NotIn`，按枚举判定会把 `c = d` 误判为需要括号。形态校验与括号一致性用独立常量与 token 类别表达，使主正则保持纯结构切分；统一走 `base.slice.cleanup` 使 `c = 07` 与 `c in (07)` 结果一致，并复用其去空、去重与数值规范化。

### Decision: 原生 map 条目归一化

- requirements：`归一化条目形态`、`校验 key`、`校验 operator 与 values 的适用关系`
- choice：用 `base.get` 取 `key`、`operator`、`values`；`key` 以 `fromYaml (printf "v: %s" ...)` 还原标量后确认 string，再剥离 `SYS.YAML_QUOTED`；`operator` 同样剥离引号后 `lower` 并按六个规范枚举映射，超出时中断；`values` 经 `fromYamlArray`、`base.isFromYamlArrayError`、`mustWithout ... nil` 后交给 `base.slice.cleanup`。
- rationale：与 `definitions.labelSelector` 的原生 map 分支保持同一形态，避免同一项目出现两套取值与类型判定写法；`base.get` 承担别名识别与序列化，调用方只做必要的标量类型确认与枚举映射。

### Decision: key 语法校验

- requirements：`校验 key`
- choice：`splitList "/"` 拆分后最多允许 2 段；末段用 `mustRegexMatch` 搭配 `K8S.SELECTOR.KEY_NAME_FOR_APPS`，存在前缀段时再搭配 `K8S.SELECTOR.KEY_PREFIX_FOR_APPS` 并校验长度不超过 253；失败消息由本层构造，带 `[definitions.nodeSelectorTerm]` 前缀与字段路径。
- rationale：`definitions.labelSelectorRequirement` 已用同一组常量表达标签键语法；本模板在委托前完成校验，符合“key 由本层清洗校验、子模板不重复 values 处理”的分工。不使用 `base.string.verify`，因为其失败消息固化为自身前缀，无法附上规格要求的字段名与条目下标。段数必须由本层判断，因为常量只覆盖单段语法。主正则只取宽松 key token，标签键语法只在本步判定，不存在第二处重复表达。

### Decision: values 约束校验

- requirements：`校验 operator 与 values 的适用关系`
- choice：清洗后按 `operator` 分派：`In`/`NotIn` 要求非空；`Exists`/`DoesNotExist` 要求没有 `values` 键；`Gt`/`Lt` 要求恰好 1 个元素且匹配 `TYPES.INT`，否则中断。校验通过后仅在有值时把 `values` 写入上下文。
- rationale：`In`/`NotIn` 的数值规范化由 `base.slice.cleanup` 完成，`Gt`/`Lt` 的整数形态由 `TYPES.INT` 判定，二者都用既有常量，不新造规则；`Exists`/`DoesNotExist` 不写 `values` 键直接满足“上下文中不存在 `values`”的规格约束。

### Decision: 去重、委托与输出

- requirements：`归一化条目形态`、`委托 definitions.nodeSelectorRequirement`
- choice：先跳过 `null`、空白字符串与空 map 条目，逐条构造 `dict "key" ... "operator" ...`（有值时补 `values`），对归一化后的 dict 列表使用 `mustUniq` 去重，再逐条 `include "definitions.nodeSelectorRequirement"`，返回值经 `fromYaml` 与 `base.isFromYamlError` 保护后收集。收集结果按字段名存入 `dict`，最后按 `list "matchExpressions" "matchFields"` 顺序用 `base.field` 搭配 `base.slice` 输出。
- rationale：去重发生在子模板调用前，保证重复条目只渲染一次；`mustUniq` 对 dict 使用深比较，满足“交由 Helm 函数处理、不自定义字段全等”；字段名集合与输出顺序分离，避免为两个字段各写一遍归一化与输出代码。

## 依赖契约

### Dependency: `definitions.nodeSelectorRequirement`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`dict`，恒含 `key`(string) 与 `operator`(string)，仅在存在有效值时为 `values`(string array)。
- output：可 `fromYaml` 解析为单个 `NodeSelectorRequirement` map 的 YAML 字符串；无法解析时由本层中断。
- ownership：`values` 的拆分、去空、去重、数值规范化与 `operator` 合法性由本层负责；单个 requirement 的字段渲染由依赖层负责。本 change 只引用该模板，不创建实现。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, "matchExpressions"]`、`list [上下文, "matchFields"]`，以及 `list [条目, "key"]`、`list [条目, "operator"]`、`list [条目, "values"]`；均非必填并保留默认别名识别。
- output：可 `fromYaml`/`fromYamlArray` 解析的 YAML 字符串；路径缺失时为空输出。
- ownership：数据源优先级、别名识别与序列化由依赖层负责；取值形式、空输出判定、类型门禁与失败消息由本层负责。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`update`
- input：`""`
- output：可由 `fromYaml` 解析的常量 Map，本模板读取 `K8S.SELECTOR.NODE_TERM_FOR_APPS`、`K8S.SELECTOR.NODE_TERM_VALUES_FOR_APPS`、`K8S.SELECTOR.KEY_NAME_FOR_APPS`、`K8S.SELECTOR.KEY_PREFIX_FOR_APPS`、`SYS.YAML_QUOTED`、`SPLIT.COMMA`、`TYPES.INT`。
- ownership：常量集中定义与结构有效性由依赖层负责；本 change 只新增 `K8S.SELECTOR.NODE_TERM_FOR_APPS` 与 `K8S.SELECTOR.NODE_TERM_VALUES_FOR_APPS` 两个键，其余键只读消费，不修改既有表达式。

### Dependency: `base.slice.cleanup`

- availability：`existing`
- source：`templates/base/_collection.tpl`
- operation：`consume`
- input：`list [待清洗文本, SPLIT.COMMA]`。
- output：YAML 列表字符串，已去空、去重，纯数字字符串按依赖层规则转数值。
- ownership：拆分、去空、去重与数值规范化由依赖层负责；输入形态选择与清洗后 `toStrings` 回写由本层负责。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [字段名, map 列表, "base.slice"]`。
- output：`key:` 加换行缩进的字段片段；值为空时不输出。
- ownership：序列化与目标类型门禁由依赖层负责；字段生效条件与输出顺序由本层负责。

### Dependency: `base.slice`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：由 `base.field` 传入的 map 列表。
- output：YAML 列表字符串；非 slice 时中断。
- ownership：列表序列化与类型门禁由依赖层负责。

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 的返回值，用于字段数组与 `values`。
- output：布尔字符串 `"true"` / `"false"`。
- ownership：错误形态识别由依赖层负责；失败消息与中断决策由本层负责。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 的返回值，用于子模板输出与 `key` 标量还原。
- output：布尔字符串 `"true"` / `"false"`。
- ownership：错误形态识别由依赖层负责；失败消息与中断决策由本层负责。

## 代码边界

### `templates/base/_env.tpl`

- access：`write`
- operations：`add K8S.SELECTOR.NODE_TERM_FOR_APPS`、`add K8S.SELECTOR.NODE_TERM_VALUES_FOR_APPS`
- writable-scopes：`K8S.SELECTOR` 下的 `NODE_TERM_FOR_APPS` 与 `NODE_TERM_VALUES_FOR_APPS` 两个键及其紧邻中文注释

### `templates/api-resources/Definitions/_NodeSelectorTerm.tpl`

- access：`write`
- operations：`add define "definitions.nodeSelectorTerm"`、`add 紧邻 define 之前的中文整体契约注释`、`add 字段级中文注释`
- writable-scopes：新建文件全部内容

## 验证设计

- 最小有效：`/tmp/` 最小 application Chart，`definitions.nodeSelectorRequirement` 使用同名回显 fixture；`matchExpressions: ["c != d"]` 验证输出只含 `matchExpressions` 且 fixture 收到 `key` `c`、`operator` `NotIn`、`values` `d`。
- 较完整有效：同一 fixture 下提供 `matchExpressions: ["c", "!c", "aa in (xx1, xx2, xx3)", "c > 07"]` 与 `matchFields: [{key: aa, operator: in, values: [xx1, xx2]}]`，验证字段顺序、六个操作符映射、`values` 字符串化与数值规范化、`Exists` 上下文无 `values` 键、string 与 map 混用。
- 去重与去空：重复 string 条目、重复 map 条目、`null`、空白字符串与空 map，验证输出条目唯一且不含空条目。
- 关键失败：字段非数组、条目为数字或布尔、`c != d e`、`c > 1 2`、`c in a`、`c > (7)`、`c != (d, e)`、`c gt 3`、`c lt 5`、`c exists d`、`!c != d`、`c !=`、`c in(a)`、`key` 为空或含两个 `/`、`-abc` 与 `a=b` 的 key 语法失败、`operator` 非枚举、`In` 无值、`Exists` 带值、`Gt` 两值、`Gt` 非整数，逐一验证渲染中断且错误信息含 `[definitions.nodeSelectorTerm]` 与字段路径；另验证 values 原文形态与括号一致性各自产出专属错误消息。
- 依赖边界：`definitions.nodeSelectorRequirement` 当前不可用，全部验证以同名 fixture 提供，fixture 原样回显上下文；只证明本模板的取值、归一化、校验与输出行为，不构成真实依赖集成通过的证据。
