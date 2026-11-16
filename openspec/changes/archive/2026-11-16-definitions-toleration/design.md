# definitions.toleration 设计

## 技术目标

- capability：`definitions.toleration`
- artifact-type：共享结构模板
- target：`templates/api-resources/Definitions/_Toleration.tpl`

## 设计决策

### Decision: 先统一归一全部字符串字段，再做互斥校验

- requirements：`Toleration 字段片段渲染`、`key、operator 与 value 互斥校验`
- choice：在渲染任何字段之前，先用 `base.get` + `base.string.normalize` + `trim` 取得 `effect`、`key`、`operator`、`value` 四个归一值，再用一次 `if or $key $operator $value` 判定是否执行互斥校验，最后按 API 顺序逐字段输出。
- rationale：互斥规则同时依赖三个字段的归一结果，先归一可让校验只写一次；把校验放在输出之前，避免已输出字段后才发现组合非法。

### Decision: 互斥校验按官方字段说明逐条展开

- requirements：`key、operator 与 value 互斥校验`
- choice：在互斥校验块内依次判断三条规则：`key` 为空时 `operator` 必须为 `Exists`；`operator` 为 `Exists` 时 `value` 必须为空；`operator` 为 `Gt`、`Lt` 时 `value` 必须非空。三条规则互不嵌套，各自独立 `fail`。
- rationale：三条规则对应官方 `key` 与 `value` 字段说明的原文推理结论，逐条独立判断便于与规格 Scenario 一一对应；规则间不存在需要合并的等价分支。

### Decision: 枚举校验交由 base.field 允许值列表

- requirements：`Toleration 字段片段渲染`
- choice：`effect` 与 `operator` 在非空时通过 `base.field` 的允许值列表完成枚举校验并以 `quote` 输出；`key` 与 `value` 只需 `quote`。
- rationale：`base.field` 的允许值列表使用精确字符串比较，天然满足大小写敏感要求，并在失败消息中给出合法范围；`quote` 保证枚举与普通字符串都输出为 YAML 字符串，避免 `on`、`yes` 等文本被父级回收时改变类型。

### Decision: tolerationSeconds 直接使用 base.get 原始输出

- requirements：`Toleration 字段片段渲染`
- choice：`tolerationSeconds` 以 `base.get` 原始输出非空为生效条件，直接交给 `base.field` 与 `base.int` 渲染，不做 `base.string.normalize` 解码。
- rationale：该字段是整数，原生整数经 `base.get` 序列化为不带引号的数字文本，可直接通过 `base.int`；整数型字符串会被序列化为带引号文本，从而由 `base.int` 中断，达成“不做类型归一化”的类型门禁，也与同域 `definitions.podSecurityContext` 处理 `fsGroup` 的方式一致。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <上下文 map> "<字段名>"`。
- output：可 `fromYaml` 解析的 YAML 字符串；字段缺失或为 null 时为空内容。
- ownership：`base.get` 负责数据源优先级、同级 `<字段>Alias` 识别与序列化；本模板负责字段顺序、空值判定、互斥校验与输出决策。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 原始输出的 YAML 标量文本。
- output：解码后的 string；空输入返回空字符串；非 string 中断渲染。
- ownership：`base.string.normalize` 负责标量解码与 string 类型门禁；本模板负责 `trim`、空值判定与互斥校验。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [key, 已归一化值, 渲染模板, 允许值列表]`；字符串与枚举字段使用 `quote`，`effect` 与 `operator` 附带允许值列表，`tolerationSeconds` 使用 `base.int`。
- output：单行键值对 YAML 字符串；值为空时不输出；枚举越界时中断并给出合法范围。
- ownership：`base.field` 负责单键渲染、引号处理与枚举校验；本模板负责字段生效判断与互斥校验。

### Dependency: `base.int`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：`int`、`int64`、`float64` 或整数字符串。
- output：十进制数字字符串；其他类型中断渲染。
- ownership：`base.int` 负责整数类型门禁与十进制输出；本模板负责生效判断。

## 代码边界

### `templates/api-resources/Definitions/_Toleration.tpl`

- access：`write`
- operations：新增 `define "definitions.toleration"`、整体契约注释、各字段注释与字段处理闭环。
- writable-scopes：整个新增文件，包含上述 `define` 及注释。

### `templates/base/_get.tpl`

- access：`read`
- operations：核对 `base.get` 的入参顺序、别名开关与缺失字段的返回边界。

### `templates/base/_convert.tpl`

- access：`read`
- operations：核对 `base.string.normalize` 的入参形态、空输入返回与失败边界。

### `templates/base/_field.tpl`

- access：`read`
- operations：核对 `base.field` 的参数数量、`quote` 与允许值列表的组合语义，以及空值输出条件。

### `templates/base/_types.tpl`

- access：`read`
- operations：核对 `base.int` 接受的类型与失败边界。

### `templates/api-resources/Core/_PodSpec.tpl`

- access：`read`
- operations：核对 `tolerations` 调用 `definitions.toleration` 的入参形态、空内容判定与结果回收方式。

## 验证设计

- 最小有效：仅提供 `key`，输出只含 `key`。
- 较完整有效：五个字段齐全且组合合法，输出顺序为 `effect`、`key`、`operator`、`tolerationSeconds`、`value`，四个字符串字段为字符串、`tolerationSeconds` 为整数。
- 空值与缺省：全部缺省时输出空内容；`effect`、`key`、`operator`、`value` 为空字符串或纯空白时不产生对应键。
- 边界有效：`operator: Exists` 且无 `value`；`operator: Gt` 且 `value` 为数字字符串；`key` 非空且 `operator` 省略；`tolerationSeconds` 为 `0` 与负数。
- 关键失败：`key` 为空且 `operator` 为 `Equal`；`key` 为空且 `operator` 省略；`operator: Exists` 且 `value` 非空；`operator: Gt` 且 `value` 为空；`operator` 为 `exists`；`effect` 为 `Noschedule`；`tolerationSeconds` 为字符串或布尔。
- 依赖边界：在 `/tmp/` 最小 application Chart 中加载真实 library Chart，`base.*` 使用真实实现，不使用同名 fixture；另以真实 `core.podSpec` 的 `tolerations` 入口做一次集成渲染。
