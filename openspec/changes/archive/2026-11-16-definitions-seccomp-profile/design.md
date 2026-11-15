# SeccompProfile 共享结构设计

## 技术目标

- capability：`definitions.seccompProfile`
- artifact-type：Kubernetes 共享结构命名模板
- target：`templates/api-resources/Definitions/_SeccompProfile.tpl` 中 `define "definitions.seccompProfile"`

## 设计决策

### Decision: 目标文件与命名模板归属

- requirements：`渲染 SeccompProfile 字段片段`
- choice：新增 `templates/api-resources/Definitions/_SeccompProfile.tpl`，文件内只定义 `definitions.seccompProfile`。
- rationale：`SeccompProfile` 是 Kubernetes 官方结构，v1.36 参考明确其 `Appears In` 为 `PodSecurityContext` 与 `SecurityContext`，属可跨资源复用的同域共享结构，只能落在 `api-resources/Definitions`；该目录的 `_AppArmorProfile.tpl`、`_SELinuxOptions.tpl` 沿用 `_<结构名>.tpl` 与 `definitions.<能力>` 命名。该 `define` 在全 Chart 不存在，属纯新增；既有调用点 `templates/api-resources/Definitions/_PodSecurityContext.tpl` 已以 `dict "key" "seccompProfile" "define" "definitions.seccompProfile"` 委托，本 change 补齐该被委托能力。

### Decision: type 单次归一化并共用

- requirements：`type 必填与枚举校验`
- choice：模板入口以 `base.get` 取 `type`、`base.string.normalize` 解码、`trim` 后赋给 `$type`，该变量供必填判空、`Localhost` 分支判断、枚举校验与最终输出共用。
- rationale：规格要求 `type` 的判空、枚举校验与输出都使用去除首尾空白后的结果，单一变量避免重复取值与重复归一。`base.get` 对标量缺失、`null` 与空字符串统一返回空输出，`base.string.normalize` 对空输入返回空字符串，两者串联使一条判空覆盖三种缺失路径；`normalize` 对数字、布尔与结构输入中断，一条委托即满足“不是 string 时中断”，无需额外 `kindIs`。不使用 `base.get` 的 `required=true`：两者失败场景不完全重叠，本层仍需区分必填缺失与枚举越界。

### Decision: 枚举校验委托 base.field 的允许值列表

- requirements：`type 必填与枚举校验`
- choice：`base.field` 传入第四个参数 `list ["Localhost" "RuntimeDefault" "Unconfined"]`，由依赖层完成枚举校验与失败报错；本层只在该调用前完成必填判空。
- rationale：`base.field` 的允许值列表分支与 `quote` 可以共存。源码中 `quote` 先将 `$isQuote` 置位并把 `$define` 换成 `base.string`，随后允许值列表分支只重写 `$define`、不清除 `$isQuote`，因此 `list [<键>, <值>, "quote", <允许值列表>]` 同时获得枚举校验与双引号输出；实测该组合输出 `type: "RuntimeDefault"`，越界值报 `[base.field] <键>: value '<值>' not in allowed list '<列表>'`。这与 `_AppArmorProfile.tpl` 用允许值列表校验同名字段的既有做法一致，避免在调用方重复一份枚举常量与同义报错。允许值比对使用 `toString` 作用于调用方传入值且不做 `trim`，所以本层必须传入已 `trim` 的 `$type`，不得传 `base.get` 的原始输出。

### Decision: localhostProfile 条件读取

- requirements：`localhostProfile 条件渲染`
- choice：仅在 `$type` 等于 `Localhost` 时，以同一 `base.get` + `base.string.normalize` + `trim` 链路取 `localhostProfile` 并在归一后为空时 `fail`；非 `Localhost` 分支完全不调用取值。
- rationale：把取值放进分支是最直接的“不读取、不校验”表达，避免为跳过校验引入额外条件判断。归一后为空即中断，与规格“空字符串或只含空白时中断”一致，无需区分缺失与空内容。取值缺失时 `base.get` 返回空输出，`normalize` 返回空字符串，`trim` 后仍为空，一条判空覆盖缺失、`null`、空字符串与纯空白。

### Decision: 字段输出顺序与形态

- requirements：`渲染 SeccompProfile 字段片段`、`字段值输出形态`
- choice：`Localhost` 分支先以 `base.field` 的 `list [ "localhostProfile", $localhostProfile, "quote" ]` 输出，随后无条件以 `list [ "type", $type, "quote", <允许值列表> ]` 输出。
- rationale：官方字段表顺序为 `localhostProfile` 在前、`type` 在后，先内层分支后公共字段即可保序，无需中间列表。`quote` 保证 `on`、`yes`、`true` 等文本在父级 `fromYaml` 回收后仍为 string；`quote` 内部经 `base.string`，其零折叠规则对 `0000` 一类极端取值生效，与 `_AppArmorProfile.tpl` 处理同名 `localhostProfile` 的既有做法一致。`localhostProfile` 不传允许值列表：其取值由调用方提供，规格不限定枚举。

### Decision: 返回值形态

- requirements：`渲染 SeccompProfile 字段片段`
- choice：只输出字段片段，不输出父键、`---`、`apiVersion` 或 `kind`；因 `type` 必填，模板恒有非空输出。
- rationale：调用点 `definitions.podSecurityContext.struct` 以 `include $define $_parsed | fromYaml` 回收，并仅在回收结果非空时以 `base.field` + `base.map` 嵌入父字段；恒有输出与该回收契约一致，不会出现结构被静默丢弃的情况。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, "<字段名>"]` 形式的非必填取值，键名取自 `type` 与 `localhostProfile`；别名保持默认开启。
- output：可由 `fromYaml` 解析的 YAML 字符串；标量经 `toYamlPretty` 序列化并带尾随换行，字符串可能带 YAML 引号；路径缺失、为 `null` 或为空字符串时为空输出。
- ownership：数据源优先级、别名识别与标量序列化由依赖层负责；取值路径、判空与后续归一由本层负责。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 返回的原始文本。
- output：解码后的 string；空输入返回空字符串；非 string 标量或非法 YAML 标量中断，且不做 `trim`。
- ownership：YAML 标量解码与 string 类型门禁由依赖层负责；`trim`、判空与条件分支由本层负责。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [<字段名>, 已 trim 的归一化值, "quote", <允许值列表>]`；`type` 传三个允许值，`localhostProfile` 传两个参数形式且不传允许值列表。
- output：值生效时输出带双引号的单行字段片段；渲染结果为空时不输出；多行值退化为块标量，本模板的 `trim` 已保证取值单行；传入允许值列表且值不在列表内时中断，错误消息包含字段名与合法取值。
- ownership：引号处理、输出格式与枚举校验由依赖层负责；取值归一、`trim`、必填判空、字段生效条件与传给枚举校验的已归一值由本层负责。

## 代码边界

### `templates/api-resources/Definitions/_SeccompProfile.tpl`

- access：`write`
- operations：`add define "definitions.seccompProfile"`、`add 紧邻 define 之前的中文整体契约注释`、`add 字段级中文注释`
- writable-scopes：文件内 `definitions.seccompProfile` 的契约注释与 `define` 块

### `templates/api-resources/Definitions/_PodSecurityContext.tpl`

- access：`read`
- operations：`consume 既有委托调用 dict "key" "seccompProfile" "define" "definitions.seccompProfile"`

## 验证设计

- `/tmp/` 最小 application Chart 加载本 change 的目标模板与真实 `base` 依赖（`base.get`、`base.string.normalize`、`base.field` 及其传递依赖），不需要任何 fixture：本模板无 unavailable 依赖，全部场景都是真实依赖集成。
- 最小有效输入：`{type: RuntimeDefault}`，断言输出只含 `type: "RuntimeDefault"` 且可被 `fromYaml` 回收为 map。
- 较完整有效输入：`{type: Localhost, localhostProfile: profiles/a.json}` 断言两字段顺序、`{type: " Localhost ", localhostProfile: "  profiles/a.json  "}` 断言取值已 `trim`、`{type: RuntimeDefault, localhostProfile: 123}` 与 `{type: Unconfined, localhostProfile: {a: b}}` 断言非 `Localhost` 时忽略该字段、`{type: RuntimeDefault, foo: bar}` 断言范围外键忽略、`{type: Localhost, localhostProfile: "on"}` 断言引号与回读类型。
- 关键失败输入：`type` 缺失、`null`、空字符串、纯空白、`localhost`、`RUNTIMEDEFAULT`、`Bogus`、`123`、`true`、`{a: b}`、`[a]`；`type: Localhost` 下 `localhostProfile` 缺失、空字符串、纯空白、`123`、map。逐项断言渲染中断；枚举越界项断言错误消息来自依赖层 `base.field` 且含合法取值。
- 静态检查：目标模板无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、字段注释紧邻对应处理闭环、文件末尾单换行。
