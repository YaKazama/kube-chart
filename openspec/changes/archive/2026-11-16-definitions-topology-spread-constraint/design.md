# definitions.topologySpreadConstraint 设计

## 技术目标

- capability：`definitions.topologySpreadConstraint`
- artifact-type：共享结构模板
- target：`templates/api-resources/Definitions/_TopologySpreadConstraint.tpl`

## 设计决策

### Decision: 按 API 字段顺序逐字段闭环

- requirements：`TopologySpreadConstraint 字段片段渲染`
- choice：在同一 `define` 内按 `labelSelector`、`matchLabelKeys`、`maxSkew`、`minDomains`、`nodeAffinityPolicy`、`nodeTaintsPolicy`、`topologyKey`、`whenUnsatisfiable` 的官方顺序逐字段完成“取值 → 解析 → 校验 → `base.field` 渲染”闭环，不设集中校验区段。
- rationale：`matchLabelKeys` 的依赖判定需要 `labelSelector` 的结果，而 `labelSelector` 在 API 顺序中位于其前，逐字段闭环可直接复用该结果，无需跨区段中间变量；`fail` 会中断整个渲染，字段输出先后不影响最终是否产生部分资源。

### Decision: labelSelector 结构与内容全部委托子模板

- requirements：`TopologySpreadConstraint 字段片段渲染`
- choice：`labelSelector` 的原始输出经 `fromYaml` 恢复并排除解析错误后，原样作为上下文调用 `definitions.labelSelector`，回收结果排除解析错误后以 `base.field` 与 `base.map` 输出；本模板不读取其内部任何字段。
- rationale：规格只要求透传与回收，子模板自有 `matchLabels` 必填等契约；与 `definitions.podSecurityContext.struct`、`_PodAffinityTerm.tpl` 处理嵌套结构的既有做法一致。

### Decision: matchLabelKeys 组合公共清洗能力与元素类型门禁

- requirements：`matchLabelKeys 与 labelSelector 的依赖关系`
- choice：`base.get` 原始输出经 `fromYamlArray` 并排除解析错误后，先逐项用 `kindIs "string"` 完成类型门禁，再交给 `base.slice.cleanup` 按 `SPLIT.SPACE_COMMA` 拆分、剔除空项并去重，最后 `toStrings` 归一为字符串数组输出。
- rationale：`base.slice.cleanup` 能把纯数字字符串折叠为 int，若先清洗再判类型会丢失原始类型事实，因此类型门禁必须前置；`SPLIT.SPACE_COMMA` 只按空白与逗号拆分，标签键本身不包含这两类字符，不会切碎合法键。`base.string` 虽然内置 string 类型门禁，但对空字符串强制失败，与“剔除空项”冲突，不能用于逐项校验。

### Decision: 数值边界复用 base.int 与 base.int.range

- requirements：`maxSkew 与 minDomains 数值边界`
- choice：`maxSkew`、`minDomains` 的原始输出经 `base.int` 完成整数类型门禁，再经 `base.int.range` 以最小 `1` 校验下限，最后以 `base.field` 与 `base.int` 渲染。
- rationale：`base.int.range` 只接受数值且只做区间判断，`base.int` 负责把整数文本规范化为十进制并拒绝非整数；两者组合即可同时满足“整数类型”与“非正取值中断”，与 `_PodSpec.tpl` 对 `terminationGracePeriodSeconds` 的既有写法同源。

### Decision: 枚举与标签键校验复用既有能力

- requirements：`TopologySpreadConstraint 字段片段渲染`
- choice：`whenUnsatisfiable`、`nodeAffinityPolicy`、`nodeTaintsPolicy` 在 `base.string.normalize` 与 `trim` 后，非空时以 `base.field` 的允许值列表校验并加引号输出；`topologyKey` 以 `base.get` 必填取值、`base.string.normalize` 解码后交给 `base.labelKey`，失败消息携带本模板名与字段路径。
- rationale：`base.field` 的允许值列表使用精确字符串比较，天然满足大小写敏感；`base.labelKey` 是项目内标签键语法的唯一实现，`_PodAffinityTerm.tpl` 的 `topologyKey` 已是同构写法。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <上下文 map> "<字段名>"`；`topologyKey` 与 `maxSkew` 追加必填标记。
- output：可 `fromYaml` 解析的 YAML 字符串；字段缺失或为 null 时为空内容，必填时中断。
- ownership：`base.get` 负责数据源优先级、同级 `<字段>Alias` 识别、必填校验与序列化；本模板负责字段顺序、空值判定、依赖校验与输出决策。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 原始输出的 YAML 标量文本。
- output：解码后的 string；空输入返回空字符串；非 string 中断渲染。
- ownership：`base.string.normalize` 负责标量解码与 string 类型门禁；本模板负责 `trim`、空值判定与输出决策。

### Dependency: `base.labelKey`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：`list [标签键, 调用方模板名, 调用方字段路径]`。
- output：`trim` 后且校验通过的标签键；语法非法时中断并携带调用方模板名与字段路径。
- ownership：`base.labelKey` 负责标签键语法校验；本模板负责必填取值与输出。

### Dependency: `base.int`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：`int`、`int64`、`float64` 或整数字符串。
- output：十进制数字字符串；其他类型中断渲染。
- ownership：`base.int` 负责整数类型门禁与十进制输出；本模板负责范围校验与输出决策。

### Dependency: `base.int.range`

- availability：`existing`
- source：`templates/base/_validate.tpl`
- operation：`consume`
- input：`list [数值, 最小值]`；两项均为 int、int64 或 float64。
- output：校验通过的数值；低于下限时中断渲染。
- ownership：`base.int.range` 负责数值区间校验；本模板负责提供下限 `1`。

### Dependency: `base.slice.cleanup`

- availability：`existing`
- source：`templates/base/_collection.tpl`
- operation：`consume`
- input：`list [数据, 拆分正则]`，拆分正则为 `SPLIT.SPACE_COMMA`。
- output：YAML 列表；默认剔除空字符串并去重。
- ownership：`base.slice.cleanup` 负责拆分、剔除空项与去重；本模板负责元素类型门禁与字符串归一。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [key, 已归一化值, 渲染模板, 允许值列表]`；枚举字段使用 `quote` 并附带允许值列表，数值字段使用 `base.int`，`labelSelector` 使用 `base.map`，数组字段使用 `base.slice`。
- output：单行键值对或缩进 YAML 片段；值为空时不输出；枚举越界时中断并给出合法范围。
- ownership：`base.field` 负责单键渲染、引号处理与枚举校验；本模板负责字段生效判断。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：`""`。
- output：可 `fromYaml` 解析的常量 Map。
- ownership：`base.env` 负责常量定义；本模板只读取 `SPLIT.SPACE_COMMA`，不新增或改写常量。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 返回值。
- output：布尔字符串，标识是否为解析错误形态。
- ownership：`base.isFromYamlError` 负责错误形态识别；本模板负责在排除错误后继续处理。

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 返回值。
- output：布尔字符串，标识是否为解析错误形态。
- ownership：`base.isFromYamlArrayError` 负责错误形态识别；本模板负责在排除错误后继续处理。

### Dependency: `definitions.labelSelector`

- availability：`existing`
- source：`templates/api-resources/Definitions/_LabelSelector.tpl`
- operation：`consume`
- input：已通过 `fromYaml` 恢复并确认非空的 `labelSelector` map。
- output：可 `fromYaml` 解析为 map 的 LabelSelector 字段片段；内部字段非法时中断，`matchLabels` 缺失或为空时中断。
- ownership：子模板负责 `labelSelector` 的全部内部结构与校验；本模板只传递上下文、回收结果并渲染。

## 代码边界

### `templates/api-resources/Definitions/_TopologySpreadConstraint.tpl`

- access：`write`
- operations：新增 `define "definitions.topologySpreadConstraint"`、整体契约注释、各字段注释与字段处理闭环。
- writable-scopes：整个新增文件，包含上述 `define` 及注释。

### `templates/base/_get.tpl`

- access：`read`
- operations：核对 `base.get` 的入参顺序、必填标记与缺失字段的返回边界。

### `templates/base/_convert.tpl`

- access：`read`
- operations：核对 `base.string.normalize` 的入参形态与失败边界，以及两个 YAML 解析错误 helper 的判据。

### `templates/base/_k8s.tpl`

- access：`read`
- operations：核对 `base.labelKey` 的入参形态、失败消息归属与返回边界。

### `templates/base/_types.tpl`

- access：`read`
- operations：核对 `base.int` 接受的类型与失败边界。

### `templates/base/_validate.tpl`

- access：`read`
- operations：核对 `base.int.range` 的下限语义与失败消息。

### `templates/base/_collection.tpl`

- access：`read`
- operations：核对 `base.slice.cleanup` 的拆分、数字折叠、剔空与去重行为。

### `templates/base/_field.tpl`

- access：`read`
- operations：核对 `base.field` 的参数数量、`quote` 与允许值列表的组合语义以及空值输出条件。

### `templates/base/_env.tpl`

- access：`read`
- operations：核对 `SPLIT.SPACE_COMMA` 的运行时表达式与 `K8S` 常量分组。

### `templates/api-resources/Definitions/_LabelSelector.tpl`

- access：`read`
- operations：核对 `definitions.labelSelector` 的入参形态、`matchLabels` 必填契约与返回边界。

### `templates/api-resources/Core/_PodSpec.tpl`

- access：`read`
- operations：核对 `topologySpreadConstraints` 调用 `definitions.topologySpreadConstraint` 的入参形态与空内容回收方式。

## 验证设计

- 最小有效：只提供 `maxSkew`、`topologyKey`、`whenUnsatisfiable`，输出只含这三个字段且顺序正确。
- 较完整有效：八个字段齐全，输出顺序为 `labelSelector`、`matchLabelKeys`、`maxSkew`、`minDomains`、`nodeAffinityPolicy`、`nodeTaintsPolicy`、`topologyKey`、`whenUnsatisfiable`，`labelSelector` 为对象、`matchLabelKeys` 为字符串数组、两个数值字段为整数。
- 枚举有效与失败：`DoNotSchedule`、`ScheduleAnyway`、`Honor`、`Ignore` 正常输出；`donotschedule`、`DoNotSchedule ` 之外的形式、`honor` 中断并给出合法范围。
- 数值边界：`maxSkew` 为 `1` 通过、为 `0` 中断；`minDomains` 为 `1` 通过、为 `0` 与负数中断、缺省不输出。
- 依赖关系：`labelSelector` 与 `matchLabelKeys` 同时提供时通过；仅有 `matchLabelKeys` 时中断；`matchLabelKeys` 含空项被剔除、含重复项去重、含数值元素中断。
- 标签键：`topology.kubernetes.io/zone` 通过；`a/b/c`、`-zone` 中断并携带本模板名。
- 关键失败：三个必填字段任一缺失、字符串字段为 map、`matchLabelKeys` 为字符串或对象。
- 依赖边界：在 `/tmp/` 最小 application Chart 中加载真实 library Chart，`base.*` 与 `definitions.labelSelector` 均使用真实实现，不使用同名 fixture；另以真实 `core.podSpec` 的 `topologySpreadConstraints` 入口做一次集成渲染。
