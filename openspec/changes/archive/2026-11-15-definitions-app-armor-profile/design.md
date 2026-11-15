# AppArmorProfile 共享结构设计

## 技术目标

- capability：`definitions.appArmorProfile`
- artifact-type：Kubernetes 共享结构命名模板
- target：`templates/api-resources/Definitions/_AppArmorProfile.tpl` 中 `define "definitions.appArmorProfile"`

## 设计决策

### Decision: 目标文件与命名模板归属

- requirements：`渲染 AppArmorProfile 字段片段`
- choice：新增 `templates/api-resources/Definitions/_AppArmorProfile.tpl`，文件内只定义 `definitions.appArmorProfile`。
- rationale：`AppArmorProfile` 是 Kubernetes 官方结构，被 `PodSecurityContext` 与 `SecurityContext` 共用，属可跨资源复用的同域共享结构，只能落在 `api-resources/Definitions`；该目录现有 `_PodOS.tpl`、`_ObjectMeta.tpl` 等沿用 `_<结构名>.tpl` 与 `definitions.<能力>` 命名，新增文件与之保持一致。该 `define` 在全 Chart 不存在，属纯新增；既有调用点 `templates/api-resources/Definitions/_PodSecurityContext.tpl` 已以 `dict "key" "appArmorProfile" "define" "definitions.appArmorProfile"` 委托，本 change 补齐该被委托能力。

### Decision: type 取值与空值判定

- requirements：`type 必填与枚举校验`
- choice：以 `base.get` 的 `list [上下文, "type"]` 非必填取值，结果经 `base.string.normalize` 解码并 `trim` 后赋给 `$type`，空值判定、条件渲染与枚举校验均使用该结果；`$type` 仍为空时以 `[definitions.appArmorProfile] type: required field is missing or empty` 中断。
- rationale：`base.get` 对标量返回 `toYamlPretty` 序列化文本，含首尾空白的字符串会被加上 YAML 引号，空白位于引号内部；`base.string.normalize` 一次解码即同时处理外层引号、纯量、块标量与空输入，再接 `trim` 即满足规格要求的“去除首尾空白后参与判断与输出”。`normalize` 对空输入返回空字符串，但缺失、`null` 与空字符串在 `base.get` 层输出相同，因此必填判空统一由本层完成；不委托 `base.get` 的 `required=true`，避免它只按原始文本判空而放行只含空白的输入并产生第二套同义消息。选择 `normalize` 而非 `base.env` 去引号，是因为它同时承担非 string 类型门禁，一条委托即可满足规格要求的“`type` 不是 string 时中断且不归一化”，与 `localhostProfile` 的归一方式保持一致。

### Decision: type 枚举校验委托 base.field

- requirements：`type 必填与枚举校验`
- choice：以 `base.field` 的 `list ["type", $type, "base.string", (list "Localhost" "RuntimeDefault" "Unconfined")]` 完成枚举校验与输出。
- rationale：归一化已完成解码与 trim，`base.field` 只需承担枚举比较；它在渲染前用 `toString` 与允许值逐个精确比较，天然满足大小写敏感；未命中时以 `[base.field] type: value '<值>' not in allowed list '[Localhost RuntimeDefault Unconfined]'` 中断，满足规格要求的“其他 string 取值失败时给出合法范围”。三个取值都不是 YAML 布尔或数值样式，`base.string` 默认渲染不会产生歧义。

### Decision: localhostProfile 条件渲染

- requirements：`localhostProfile 条件渲染`
- choice：仅在 `$type` 等于 `Localhost` 时进入该字段处理：`base.get` 取原始文本，经 `base.string.normalize` 解码并 `trim` 后为空则中断，非空时以 `trim` 结果配合 `base.field` + `quote` 输出；`$type` 不是 `Localhost` 时完全不取值。
- rationale：`base.string.normalize` 对数字、布尔与结构输入中断，一条委托即满足“非 string 必须失败且不做类型归一化”，无需额外 `kindIs`。`localhostProfile` 是节点上预加载的 profile 名，可能包含 `:`、`on` 等会被 YAML 误解析为映射或布尔的文本，`quote` 保证父级回收后仍是 string。非 `Localhost` 时不取值，使“输入了非法 `localhostProfile` 也不报错”成为取值边界上的自然结果，而不是额外的分支判断。

### Decision: 返回值形态

- requirements：`渲染 AppArmorProfile 字段片段`
- choice：模板只输出字段片段，不输出父级 `appArmorProfile` 键、`---`、`apiVersion` 或 `kind`；因 `type` 必填，模板恒有输出，不返回空内容。
- rationale：既有调用点 `definitions.podSecurityContext.struct` 以 `include $define $_parsed | fromYaml` 回收，并在结果非空时以 `base.field` + `base.map` 嵌入父字段；本模板恒输出 `type`，与该回收契约一致。若返回空内容，调用方按“不输出该字段”处理，因此恒有输出不会破坏其边界。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, "type"]` 与 `list [上下文, "localhostProfile"]` 形式的非必填取值，别名保持默认开启。
- output：可由 `fromYaml` 解析的 YAML 字符串；标量经 `toYamlPretty` 序列化并带尾随换行，字符串可能带 YAML 引号；路径缺失、为 `null` 或为空字符串时为空输出。
- ownership：数据源优先级、别名识别与标量序列化由依赖层负责；取值路径、判空与后续归一由本层负责。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 对 `type` 与 `localhostProfile` 返回的原始文本。
- output：解码后的 string；空输入返回空字符串；非 string 标量或非法 YAML 标量中断，且不做 `trim`。
- ownership：YAML 标量解码与 string 类型门禁由依赖层负责；`trim`、判空与失败消息由本层负责。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list ["type", $type, "base.string", (list "Localhost" "RuntimeDefault" "Unconfined")]` 与 `list ["localhostProfile", $localhostProfile, "quote"]`。
- output：值生效时输出字段片段；枚举未命中时以 `[base.field]` 前缀中断并给出合法范围；`quote` 对单行值输出带双引号的标量。
- ownership：枚举比较、引号处理与类型门禁由依赖层负责；字段生效条件与归一化结果由本层负责。

## 代码边界

### `templates/api-resources/Definitions/_AppArmorProfile.tpl`

- access：`write`
- operations：`add define "definitions.appArmorProfile"`、`add 紧邻 define 之前的中文整体契约注释`、`add 字段级中文注释`
- writable-scopes：文件内 `definitions.appArmorProfile` 的契约注释与 `define` 块

## 验证设计

- `/tmp/` 最小 application Chart 加载本 change 的目标模板与真实 `base` 依赖，不需要任何 fixture：本模板无 unavailable 依赖，全部场景都是真实依赖集成。
- 最小有效输入：`{type: RuntimeDefault}`，断言输出只含 `type: RuntimeDefault` 且可被 `fromYaml` 回收为 map。
- 较完整有效输入：`{type: Localhost, localhostProfile: k8s-apparmor-example-deny-write}`、`{type: Unconfined}`、附加范围外键、含 `:` 的 profile 名、`{type: "  Localhost  "}` 与 `{type: Localhost, localhostProfile: "  prof  "}`，断言字段顺序、取值已去除外层引号与首尾空白。
- 关键失败输入：`type` 缺失、`null`、空字符串、`"   "`、`Localhost` 大小写变体、`Disabled`、`{type: 123}`、`{type: true}`、`{type: Localhost}`、`{type: Localhost, localhostProfile: null}`、`{type: Localhost, localhostProfile: ""}`、`{type: Localhost, localhostProfile: "   "}`、`{type: Localhost, localhostProfile: 123}`，逐项断言渲染中断；其中空白串断言按必填失败处理，string 枚举失败断言错误信息包含三个合法取值，非 string 类型仅断言中断。
- 反向边界输入：`{type: RuntimeDefault, localhostProfile: prof}` 与 `{type: Unconfined, localhostProfile: 123}`，断言渲染成功且输出只含 `type`。
- 静态检查：目标模板无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、字段注释紧邻对应处理闭环、文件末尾单换行。
