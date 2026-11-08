# definitions.nodeSelectorRequirement 模板设计

## 技术目标

- capability：`definitions.nodeSelectorRequirement`
- artifact-type：Kubernetes 共享结构模板（`api-resources/Definitions`）
- target：`templates/api-resources/Definitions/_NodeSelectorRequirement.tpl` 中的 `define "definitions.nodeSelectorRequirement"`

## 设计决策

### Decision: 空 map 早退

- requirements：`NodeSelectorRequirement 字段片段渲染`
- choice：`define` 主体以 `if .` 包裹，空 map 直接返回空字符串。
- rationale：规格要求空 map 不渲染且不报错；Go Template 无提前返回，包裹主体是唯一不会触发后续必填校验的写法。

### Decision: 字段取值统一委托 base.get

- requirements：`NodeSelectorRequirement 字段片段渲染`、`NodeSelectorRequirement 输入校验`
- choice：`key`、`operator` 均以 `base.get` 的必填模式取值，`values` 以非必填模式取值；三者保持默认别名开启，类型门禁在本层完成：`key`、`operator` 用 `fromYaml` 确认恢复值真实类型为 string，再用 `SYS.YAML_QUOTED` 剥离外层引号并 `trim`。
- rationale：别名识别与必填校验由 `base.get` 统一承担，本层不维护别名映射；`base.get` 的必填只判空不保证类型，因此仍需本层类型门禁。

### Decision: values 归一化

- requirements：`NodeSelectorRequirement 字段片段渲染`、`NodeSelectorRequirement 输入校验`
- choice：`values` 经 `base.get` 的非必填模式取 YAML 文本（别名保持默认开启），用 `fromYamlArray` 恢复、`base.isFromYamlArrayError` 排除解析错误后 `toStrings` 转换元素；不使用 `base.get` 的 `toStrings` 强制类型，也不做去重与拆分。
- rationale：`base.get` 的 `toStrings` 会把标量 `values` 静默包装为单元素数组，与规格「非数组必须失败」冲突；单个数据源命中时 `base.get` 不做合并去重，满足原样输出顺序。

### Decision: 字段渲染与 operator 枚举

- requirements：`NodeSelectorRequirement 字段片段渲染`、`NodeSelectorRequirement 输入校验`
- choice：`key` 交给 `base.field` 以 `base.rawString` 渲染；`operator` 交给 `base.field` 的允许值列表完成校验与渲染；`values` 的渲染入口由下面的 `Decision: values 渲染由 operator 分支决定` 决定。
- rationale：`base.field` 的允许值列表按字符串精确比较，天然大小写敏感并输出合法枚举范围，避免本层重复枚举分支；其枚举失败消息固定为 `[base.field] <key>: value '<值>' not in allowed list '<列表>'`，因此本层不再包装该错误；`base.rawString` 避免 `base.string` 的 trim 与零折叠改写键内容，与 `definitions.labelSelectorRequirement` 的字段渲染约定一致。

### Decision: values 与 operator 一致性校验

- requirements：`NodeSelectorRequirement 输入校验`
- choice：`operator` 校验通过后按 `In`/`NotIn`、`Gt`/`Lt`、其余三类分支处理：`In`、`NotIn` 必须非空；`Gt`、`Lt` 必须恰好一个元素且匹配 `base.env` 的 `TYPES.INT`；`Exists`、`DoesNotExist` 必须为空。
- rationale：规格要求本层重复校验；`TYPES.INT` 是项目统一整数常量，无需新增正则。

### Decision: values 渲染由 operator 分支决定

- requirements：`NodeSelectorRequirement 字段片段渲染`
- choice：同一组 `operator` 分支在完成一致性校验后直接决定 `values` 是否进入 `base.field` 渲染：`In`、`NotIn`、`Gt`、`Lt` 分支内渲染 `values`，`Exists`、`DoesNotExist` 分支不进入渲染路径，不使用 `if $values` 作为输出开关。
- rationale：规格要求 `values` 的缺席由 `operator` 分支显式决定，依赖空集合判空属间接实现，无法区分“该 operator 不输出”与“输入恰好为空”。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <入参 map> "key" "" "" true`、`list <入参 map> "operator" "" "" true`、`list <入参 map> "values"`；均不强制类型，别名保持默认开启。
- output：YAML 字符串；必填模式下路径缺失或为空时失败，错误为 `[base.get] '<路径>': required field is missing or empty`。
- ownership：`base.get` 只负责取值、别名解析、必填校验与序列化；本模板负责类型门禁、引号剥离、数组错误保护、元素字符串化和一致性校验。

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 的返回值。
- output：`"true"` 或 `"false"` 字符串。
- ownership：只识别 Helm 的数组解析错误形态；本模板负责依据结果中断渲染。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list <key> <已归一化 value> [渲染模板] [允许值列表]`，参数数量 2 至 4。
- output：YAML 键值对片段；渲染结果为空时不输出字段；允许值列表不匹配时以 `[base.field] <key>: value '<值>' not in allowed list '<列表>'` 中断渲染。
- ownership：`base.field` 只负责渲染与枚举比较；本模板负责来源解析、类型校验、字段生效判断和值排序，不包装其枚举错误。

### Dependency: `base.rawString`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：string 类型的 `key`。
- output：原字符串，空字符串保留为空；非 string 输入中断渲染。
- ownership：只保留原始字符串；`key` 的类型与必填校验由本模板完成。

### Dependency: `base.slice`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：string 元素列表 `values`。
- output：YAML 序列；非 slice 输入中断渲染。
- ownership：只验证并序列化列表；元素字符串化由本模板完成。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：`""`
- output：常量 Map；本模板读取 `TYPES.INT` 用于 `Gt`、`Lt` 的整数校验，读取 `SYS.YAML_QUOTED` 用于剥离 `key`、`operator` 的 YAML 外层引号。
- ownership：`base.env` 只声明静态常量；整数与引号语义由本模板按规格使用。

## 代码边界

### `templates/api-resources/Definitions/_NodeSelectorRequirement.tpl`

- access：`write`
- operations：新增 `define "definitions.nodeSelectorRequirement"`、整体契约注释、各字段注释与字段处理闭环。
- writable-scopes：整个新增文件，包含上述 `define` 及注释。

### `templates/api-resources/Definitions/_NodeSelectorTerm.tpl`

- access：`read`
- operations：核对既有 `include "definitions.nodeSelectorRequirement"` 的入参形态、返回值解析方式与失败消息约定。

### `templates/api-resources/Definitions/_LabelSelectorRequirement.tpl`

- access：`read`
- operations：核对同类 requirement 子模板的字段取值、渲染模板选择与失败消息约定。

### `templates/base/_get.tpl`

- access：`read`
- operations：核对 `base.get` 的入参顺序、别名开关、标量必填语义与列表合并去重边界。

### `templates/base/_field.tpl`

- access：`read`
- operations：核对 `base.field` 的参数数量、允许值比较方式与空值输出条件。

### `templates/base/_convert.tpl`

- access：`read`
- operations：核对 `base.rawString` 与 `base.isFromYamlArrayError` 的入参和返回边界。

### `templates/base/_types.tpl`

- access：`read`
- operations：核对 `base.slice` 的类型门禁与序列化行为。

### `templates/base/_env.tpl`

- access：`read`
- operations：核对 `TYPES.INT` 的运行时表达式。

## 验证设计

- 最小有效输入：`{key: "kubernetes.io/os", operator: "In", values: ["linux"]}`，断言按 `key`、`operator`、`values` 顺序输出且 `values` 为字符串列表。
- 较完整有效输入：六种 `operator` 各渲染一次；`Gt` 使用整数 `values`；`In` 使用含重复元素的 `values` 断言顺序与重复保留；空 map 断言无字段输出；`DoesNotExist`、`Exists` 断言输出不含 `values`；`keyAlias` 非空时断言覆盖 `key`，`keyAlias` 为空时断言回退 `key`。
- 关键失败输入：缺 `key`、`key` 非 string、`key` 为 `"   "`、缺 `operator`、`operator` 为 `in` 与 `Foo`、`In` 无 `values`、`Exists` 携带 `values`、`Gt` 两个 `values`、`Gt` 单个非整数、`values` 为非数组标量；断言渲染中断，且 `key`、`operator` 缺失报 `[base.get]`、`operator` 不在枚举内报 `[base.field]` 并列出六个合法值、其余报 `[definitions.nodeSelectorRequirement]` 并携带字段名。
- 真实依赖边界：`base.*` 依赖使用 `templates/base/` 的真实实现，不提供同名 fixture；`definitions.nodeSelectorTerm` 为真实调用方，本 change 不修改且不作为验证对象。
- 验证在 `/tmp/` 最小 application Chart 中以 `helm template` 执行，fixture 只承载调用本模板的最小包装与输入值。
