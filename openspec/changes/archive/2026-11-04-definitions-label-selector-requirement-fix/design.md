# 修正 LabelSelectorRequirement 模板设计

## 技术目标

- capability：`definitions.labelSelectorRequirement` 字段渲染
- artifact-type：Helm 命名模板
- target：`templates/api-resources/Definitions/_LabelSelectorRequirement.tpl`

## 设计决策

### Decision: 子模板改用 base.get 取值

- requirements：`LabelSelectorRequirement 字段渲染`
- choice：`key`、`operator` 使用 `include "base.get" (list . "<字段>" "" "" true)`，取值后经 `SYS.YAML_QUOTED` 剥离 YAML 标量引号并 `trim`；`values` 使用 `include "base.get" (list . "values")` 并经 `fromYamlArray` 恢复，配合 `base.isFromYamlArrayError` 判定数组类型，真值非空时以 `toStrings` 整体转为字符串后渲染。
- rationale：三层字段取值、别名识别与"上下文自身 > .Context > .Values > .Values.global"优先级已由 `base.get` 统一承担；`base.get` 对标量输出 YAML 标量文本，直接 `fromYaml` 会得到错误 map，因此字符串字段必须按既有的引号剥离方式取值；元素类型由 `toStrings` 统一收敛，无需逐项 `kindIs`；必填校验只需 `key`、`operator`，`values` 保持可选，避免为可选字段填充占位参数。

### Decision: 标签键保留分段校验

- requirements：`LabelSelectorRequirement 字段渲染`
- choice：`key` 按 `/` 拆分为最多两段，段数超限由本层报错；名称段与前缀段分别用 `base.env` 既有的 `K8S.SELECTOR.KEY_NAME_FOR_APPS`、`K8S.SELECTOR.KEY_PREFIX_FOR_APPS` 经 `base.string.verify` 校验；前缀段单独比较长度不超过 253。
- rationale：单条 Go RE2 正则无法同时表达分段字符规则与前缀总长上限，分段校验是当前唯一可唯一确定且不新增共享常量的实现。

### Decision: 父级 map 分支统一用 base.get 取值

- requirements：`LabelSelector matchExpressions 项归一化`
- choice：`definitions.labelSelector` 的原生对象分支对 `key`、`operator`、`values` 分别调用 `include "base.get"`，由 `base.get` 内置识别 `keyAlias`、`operatorAlias`、`valuesAlias`；`key`、`operator` 取值后剥离 YAML 标量引号，`values` 经 `fromYamlArray` 恢复；父级只校验取值非空与 `operator` 枚举并归一化为规范大小写，`key` 的标签键语法交给 `definitions.labelSelectorRequirement` 校验。
- rationale：`base.get` 已统一承担多层取值与别名优先规则，逐字段调用即可同时获得别名识别与类型恢复，无需 `pick` 后再自行比较别名；`key` 语法只在自有该结构的子模板校验，避免父子重复实现同一规则；父级仍保留自身失败前缀。

### Decision: values 适用性由父级校验

- requirements：`LabelSelector matchExpressions 项归一化`
- choice：父级按 `operator` 判定 `values`：`In`、`NotIn` 要求非空数组，缺失或空数组均中断；`Exists`、`DoesNotExist` 不接受 `values`，该字段非空时中断，空数组与 `null` 放行。元素类型不重复校验，非空后直接交 `base.slice.cleanup` 与 `toStrings` 收敛。子模板保持不判定适用性。
- rationale：适用性依赖同项的 `operator`，只有同时持有两者的父级能判定；元素类型已由 `base.slice.cleanup` 与 `toStrings` 处理，父级再写 `kindIs` 属于重复校验；子模板仍只负责自身字段渲染，符合现有职责划分。

### Decision: key 还原真实类型后做 string 门禁

- requirements：`LabelSelectorRequirement 字段渲染`、`LabelSelector matchExpressions 项归一化`
- choice：`key` 经 `base.get` 取值后，用 `fromYaml (printf "v: %s" <raw>)` 包装还原 YAML 标量的真实类型，以 `kindIs "string"` 判定；非 string 时本层 `fail`，通过后再用 `SYS.YAML_QUOTED` 剥离外层引号。
- rationale：`base.get` 输出的是 YAML 文本，`app` 与 `42` 的文本无法区分来源类型，包装解析交由 YAML 解析器还原类型，避免逐字符推断；缺失键经点访问得到 `invalid`，与已有必填校验不冲突。

### Decision: values 去除 null 元素与 bool 元素放行

- requirements：`LabelSelectorRequirement 字段渲染`、`LabelSelector matchExpressions 项归一化`
- choice：子模板以 `toStrings` 收敛元素并以其结果判空，使 `[null]` 不输出 `values`；父级取值后用 `mustWithout <list> nil` 剔除 `null`，不用 `compact`；`base.slice.cleanup` 的元素类型白名单新增 `bool`。
- rationale：`null` 转字符串后语义不确定，Helm 与 Kubernetes 均可能误判，按空值拦截更安全；`compact` 会同时剔除 `0` 与 `false`，不符合只排除 `null` 的目标；`bool` 与数值同属可无损转为字符串的标量，与既有 `int`、`int64`、`float64` 分支同组放行。

## 依赖契约

### Dependency: `base.get`

- availability：existing
- source：`templates/base/_get.tpl`
- operation：consume
- input：`list [上下文, 点分路径, 强制类型, 合并模式, 必填校验]`；强制类型与合并模式传空字符串占位。
- output：`toYamlPretty` 的 YAML 字符串；字符串值带 YAML 引号，未命中时为空字符串；`required=true` 且为空时以 `[base.get]` 前缀中断。
- ownership：`base.get` 负责多层取值、别名识别、必填校验；本层负责剥离 YAML 标量引号后执行字段语义校验。

### Dependency: `base.string.verify`

- availability：existing
- source：`templates/base/_validate.tpl`
- operation：consume
- input：`list [待校验字符串, 正则]`。
- output：trim 后的字符串；不匹配或类型非法时以 `[base.string.verify]` 前缀中断。
- ownership：`base.string.verify` 负责 trim 与正则匹配；本层负责传入正确的常量与后续渲染。

### Dependency: `base.env`

- availability：existing
- source：`templates/base/_env.tpl`
- operation：consume
- input：`include "base.env" "" | fromYaml`。
- output：常量 Map。
- ownership：`base.env` 负责常量的结构与转义；本层只读消费既有的两个标签键分段常量与 `SYS.YAML_QUOTED`，不新增、不修改。

### Dependency: `base.field`

- availability：existing
- source：`templates/base/_field.tpl`
- operation：consume
- input：`list [键名, 值, 渲染模板, 允许值列表]`。
- output：`key: value` YAML 摘录；值渲染为空时不输出。
- ownership：`base.field` 负责枚举校验与输出格式；本层负责字段顺序。

### Dependency: `base.slice`

- availability：existing
- source：`templates/base/_types.tpl`
- operation：consume
- input：任意值。
- output：`toYamlPretty` 的列表 YAML；非 slice 时以 `[base.slice]` 前缀中断。
- ownership：`base.slice` 负责 `values` 的类型门禁与序列化。

### Dependency: `base.isFromYamlArrayError`

- availability：existing
- source：`templates/base/_convert.tpl`
- operation：update
- input：`fromYamlArray` 的返回值。
- output：布尔字符串；首元素非 string 时不再中断渲染，而是返回 false。
- ownership：该 helper 只识别解析错误形态；分支选择与失败消息由本层负责。

### Dependency: `base.slice.cleanup`

- availability：existing
- source：`templates/base/_collection.tpl`
- operation：update
- input：`list [数据, 拆分正则]`。
- output：`toYamlPretty` 的列表 YAML；元素非法类型时中断。
- ownership：`base.slice.cleanup` 负责拆分、去空与去重，并放行 `bool`、`int`、`int64`、`float64` 标量元素；父层负责空集合判定。

## 代码边界

### `templates/api-resources/Definitions/_LabelSelectorRequirement.tpl`

- access：write
- operations：update `key`、`operator`、`values` 的取值与校验；update 模板注释入参表
- writable-scopes：`definitions.labelSelectorRequirement` 定义体及其文件头注释

### `templates/api-resources/Definitions/_LabelSelector.tpl`

- access：write
- operations：update `matchExpressions` 原生对象分支的字段取值与校验，以及 `values` 的 `operator` 适用性校验；update 模板注释的原生对象项边界说明
- writable-scopes：`kindIs "map"` 分支与文件头注释的原生对象项边界说明

### `templates/base/_convert.tpl`

- access：write
- operations：update `base.isFromYamlArrayError` 的首元素类型判定与注释
- writable-scopes：`base.isFromYamlArrayError` 定义体及其紧邻注释

### `templates/base/_collection.tpl`

- access：write
- operations：update `base.slice.cleanup` 元素类型白名单，新增 `bool`
- writable-scopes：`base.slice.cleanup` 的 Step 5 元素清洗分支

## 验证设计

- 真实依赖：`kube-chart` 本身以库 Chart 方式被 `/tmp/` 最小 application Chart 依赖，所有 `base.*` 与被改模板均加载真实实现。
- 典型有效：`In` + 两项 `values`；`Exists` 无 `values`；原生对象形式携带 `*Alias`；字符串简写 `app = web`、`k in (a,b)`、`!app`；`operator` 带首尾空白时去除后渲染；子模板 `Exists` 携带非空 `values` 时不判定适用性。
- 边界有效：`values` 为空数组时 `In` 中断、`Exists` 放行不输出该字段；`values` 元素含数字与布尔值时的强制转字符串；`values` 仅含 `null` 时按空数组处理；`key` 名称段 63 字符、前缀段总长 253 字符通过。
- 关键失败：`key` 缺失、`null`、空字符串、非字符串类型；`operator` 缺失或非法；`key` 含两个 `/`；名称段含非法字符；前缀段含大写字母；前缀段总长 254 字符；`In` 缺少 `values`；`Exists`、`DoesNotExist` 携带非空 `values`。
