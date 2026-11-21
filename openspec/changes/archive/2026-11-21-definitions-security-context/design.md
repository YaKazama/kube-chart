# SecurityContext 共享结构设计

## 技术目标

- capability：`definitions.securityContext`
- artifact-type：Kubernetes 共享结构命名模板
- target：`templates/api-resources/Definitions/_SecurityContext.tpl` 中 `define "definitions.securityContext"`

## 设计决策

### Decision: 目标文件与命名模板归属

- requirements：`渲染 SecurityContext 字段片段`
- choice：新增 `templates/api-resources/Definitions/_SecurityContext.tpl`，文件内只定义 `definitions.securityContext` 与辅助模板 `definitions.securityContext.struct`。
- rationale：`SecurityContext` 是 Kubernetes 官方结构，v1.36 参考明确其 `Appears In` 为 `Container` 与 `EphemeralContainer`，属可跨资源复用的同域共享结构，只能落在 `api-resources/Definitions`；该目录的 `_PodSecurityContext.tpl`、`_SeccompProfile.tpl` 沿用 `_<结构名>.tpl` 与 `definitions.<能力>` 命名。`definitions.securityContext` 当前在全 Chart 不存在，属纯新增；既有调用点 `templates/api-resources/Definitions/_Container.tpl` 已以 `include "definitions.securityContext"` 消费并注入同源 `os`，本 change 补齐该定义。

### Decision: os 取值与容错归一

- requirements：`按 os 校验字段适用性`
- choice：以 `base.get` 的 `list [上下文, "os.name"]` 非必填取值；原始输出非空时经 `base.env` 的 `SYS.YAML_QUOTED` 剥离 YAML 引号并 `trim`，再用内置 `lower` 转小写；结果等于 `windows` 时判定为 `windows`，其余全部判定为 `linux`，全程不 `fail`。
- rationale：规格要求 `os` 缺省、非 map、`os.name` 缺失或无法归一化为 string 时都回退 `linux`，因此不能用会在数字与布尔上中断的 `base.string.normalize`。`base.get` 的点分路径在父级不是 map 时按缺失处理，天然覆盖“`os` 不是 map”；`base.get` 对标量返回 `toYamlPretty` 文本，空白与特殊字符串可能被加引号，因此必须先剥离引号再比较。该写法与 `templates/api-resources/Definitions/_PodSecurityContext.tpl` 的既有 `os` 归一逻辑一致。

### Decision: 适用性前置校验与存在性判定

- requirements：`按 os 校验字段适用性`
- choice：在任何字段输出前，按 `os` 选出禁止字段列表（`windows` 时为 `allowPrivilegeEscalation`、`appArmorProfile`、`capabilities`、`privileged`、`procMount`、`readOnlyRootFilesystem`、`runAsGroup`、`runAsUser`、`seLinuxOptions`、`seccompProfile`，按 `linux` 处理时为 `windowsOptions`），逐项以 `hasKey` 检查规范键与 `<字段>Alias`，命中且值不是 `invalid`（即非 `null`）时以 `[definitions.securityContext] <字段>: cannot be set when os is <os>` 中断。
- rationale：规格要求判定与取值真假无关，而 `base.get` 对空字符串与缺失同样返回空输出，无法区分二者；`hasKey` 加 `kindIs "invalid"` 排除恰好同时满足“空字符串算存在”和“`null` 算不存在”两条边界。判定只读取本模板上下文自身，不读取 `.Context`、`.Values`、`.Values.global`：调用点传入的隔离 map 才是 `securityContext` 的唯一来源，扫描 `.Values` 会把父 Chart 中的同名无关键误判为 `securityContext` 字段。`<字段>Alias` 一并检查，避免 `base.get` 的默认别名识别把禁止字段以别名形式送入渲染。

### Decision: 委托结构字段的辅助模板

- requirements：`委托已实现的结构字段`、`capabilities 占位委托`
- choice：新增辅助模板 `definitions.securityContext.struct`，入参为 `dict "key" <输出键名> "define" <子模板名> "raw" <base.get 原始输出>`；模板内依次完成原始输出判空、`fromYaml`、`base.isFromYamlError` 中断、空 map 跳过、`include` 子模板、结果 `fromYaml` 与解析错误中断、非空时 `base.field` + `base.map` 输出；输入不是 map 时以 `[definitions.securityContext] <key>: must be map type` 中断，子模板输出不可解析时以 `[definitions.securityContext] <key>: invalid YAML output from <define>` 中断。五个字段各以一行调用该辅助模板。
- rationale：五个字段的闭环完全同构，但其输出位置被 `allowPrivilegeEscalation`、`privileged`、`procMount`、`runAsGroup`、`runAsNonRoot`、`runAsUser` 等标量字段分隔，无法合并为单次循环；抽出辅助模板既满足 API 字段顺序，又避免五段重复代码。`fromYaml` 成功后按核心能力规则不再重复 `kindIs`：当前 Helm 对标量输入返回错误 map，由 `base.isFromYamlError` 拦截；空输入与 `null` 恢复为空 map 并被跳过。`capabilities` 使用同一辅助模板，其 `define` 当前不存在，非空 map 会在 `include` 处中断，符合规格的占位委托边界。

### Decision: 标量字段的取值与渲染

- requirements：`渲染 SecurityContext 字段片段`、`枚举与类型校验`
- choice：`allowPrivilegeEscalation`、`privileged`、`readOnlyRootFilesystem`、`runAsNonRoot` 以 `base.get` 取值并 `trim`，非空时剥离 `SYS.YAML_QUOTED` 引号后以 `base.field` + `base.bool` 输出；`runAsGroup`、`runAsUser` 以 `base.get` 取值并 `trim`，非空时以 `base.field` + `base.int` 输出；`procMount` 以 `base.string.normalize` 归一并 `trim`，非空时以 `base.field` + `base.string` 加 `Default`、`Unmasked` 允许值列表输出。
- rationale：字段生效条件由 `base.get` 原始输出是否为空决定，显式 `0` 与 `false` 的序列化结果非空，因此不会被当作未设置。`base.int`、`base.bool` 是项目唯一的整数与布尔类型门禁，`base.field` 的允许值列表在渲染前完成枚举校验并给出合法范围。`base.bool` 只接受布尔值与不带引号的 `true`、`false`，而 `base.get` 对字符串 `"true"` 会输出带引号的标量，因此必须先剥离 `SYS.YAML_QUOTED`。`procMount` 使用 `base.string.normalize` 拒绝数字与布尔，并解码 YAML 引号。

### Decision: 固定顺序与逐字段直白写法

- requirements：`渲染 SecurityContext 字段片段`
- choice：按官方字段顺序逐字段书写取值、归一、生效判断与 `base.field` 闭环，不使用字段表加 `range` 的间接派发；字段之间以空行分隔。
- rationale：draft 明确要求直白写法；十二个字段包含四种渲染形态（boolean、integer、枚举 string、结构委托），逐字段展开比循环加分支更少配置点，且能让每个字段的中文注释紧邻其处理闭环，满足模板排版规则。

### Decision: 返回值形态

- requirements：`渲染 SecurityContext 字段片段`
- choice：模板只输出字段片段，不输出 `os`、父级 `securityContext` 键、`---`、`apiVersion` 或 `kind`；无任何生效字段时返回空内容。
- rationale：既有调用点 `definitions.container` 以 `include "definitions.securityContext" $_securityContext | fromYaml` 消费，并仅在回收结果非空时以 `base.field` + `base.map` 嵌入 `securityContext`；空内容是其正常分支。`SecurityContext` 官方字段表中没有 `os`，该键只作为控制输入。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, "<字段>"]` 形式的非必填取值，`os` 使用点分路径 `"os.name"`；别名保持默认开启。
- output：可由 `fromYaml` 解析的 YAML 字符串；标量经 `toYamlPretty` 序列化，字符串可能带 YAML 引号；路径缺失、为 `null` 或为空字符串时为空输出。
- ownership：数据源优先级、别名识别与标量序列化由依赖层负责；取值路径、判空与后续归一化由本层负责。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：`""`
- output：可由 `fromYaml` 解析的常量 Map，本模板只读取 `SYS.YAML_QUOTED`。
- ownership：正则常量的集中定义由依赖层负责；常量键选择与去引号时机由本层负责。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list ["<字段名>", 归一化后的值, "base.map" | "base.int" | "base.bool" | "base.string", 可选允许值列表]`。
- output：值生效时输出字段片段，空值时不输出；渲染模板类型不符时中断；枚举未命中时以 `[base.field]` 前缀中断并给出合法范围。
- ownership：枚举比较、字段输出格式与最终类型门禁由依赖层负责；字段生效条件与归一化结果由本层负责。

### Dependency: `base.map`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：已完成子模板委托并恢复的 map。
- output：`toYamlPretty` 序列化结果；非 map 输入中断。
- ownership：序列化与类型门禁由依赖层负责；委托结果的回收与生效判断由本层负责。

### Dependency: `base.int`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：`base.get` 返回并 `trim` 的原始文本。
- output：整数文本；非整数类型或非整数文本中断。
- ownership：整数类型门禁与失败消息由依赖层负责；调用时机与显式 `0` 的生效判断由本层负责。

### Dependency: `base.bool`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：已剥离 YAML 引号并 `trim` 的布尔字段取值。
- output：`true` 或 `false`；其他类型或非 `true`、`false` 文本中断。
- ownership：布尔类型门禁由依赖层负责；引号剥离、调用时机与显式 `false` 的生效判断由本层负责。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 返回的 `procMount` 原始文本。
- output：解码后的 string；空输入返回空字符串；非 string 标量中断。
- ownership：YAML 标量解码与 string 类型门禁由依赖层负责；`trim`、判空与枚举允许值选择由本层负责。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 的返回值。
- output：错误 map 时为 `true`，否则为 `false`。
- ownership：错误形态识别由依赖层负责；中断消息由本层负责。

### Dependency: `definitions.appArmorProfile`

- availability：`existing`
- source：`templates/api-resources/Definitions/_AppArmorProfile.tpl`
- operation：`consume`
- input：已通过类型门禁的 `appArmorProfile` map。
- output：可 `fromYaml` 解析为 map 的 AppArmorProfile 字段片段，允许为空内容；内部类型与枚举失败保留其自身前缀。
- ownership：本层负责取值、类型门禁、空 map 跳过与结果回收；子模板内部结构与校验由依赖层负责。

### Dependency: `definitions.capabilities`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：已通过类型门禁的非空 `capabilities` map，键为 `Capabilities` 的 `add` 与 `drop`。
- output：可 `fromYaml` 解析为 map 的 Capabilities 字段片段，允许为空内容；当前 `define` 不存在，实际调用会中断渲染。
- ownership：本层负责取值、类型门禁、空 map 跳过与结果回收；子模板内部结构由后续 change 实现，本 change 不创建其 `define`。

### Dependency: `definitions.seLinuxOptions`

- availability：`existing`
- source：`templates/api-resources/Definitions/_SELinuxOptions.tpl`
- operation：`consume`
- input：已通过类型门禁的 `seLinuxOptions` map。
- output：可 `fromYaml` 解析为 map 的 SELinuxOptions 字段片段，允许为空内容。
- ownership：本层负责取值、类型门禁、空 map 跳过与结果回收；子模板内部结构与校验由依赖层负责。

### Dependency: `definitions.seccompProfile`

- availability：`existing`
- source：`templates/api-resources/Definitions/_SeccompProfile.tpl`
- operation：`consume`
- input：已通过类型门禁的 `seccompProfile` map。
- output：可 `fromYaml` 解析为 map 的 SeccompProfile 字段片段，允许为空内容。
- ownership：本层负责取值、类型门禁、空 map 跳过与结果回收；子模板内部结构与校验由依赖层负责。

### Dependency: `definitions.windowsSecurityContextOptions`

- availability：`existing`
- source：`templates/api-resources/Definitions/_WindowsSecurityContextOptions.tpl`
- operation：`consume`
- input：已通过类型门禁的 `windowsOptions` map。
- output：可 `fromYaml` 解析为 map 的 WindowsSecurityContextOptions 字段片段，允许为空内容。
- ownership：本层负责取值、类型门禁、空 map 跳过与结果回收；子模板内部结构与校验由依赖层负责。

## 代码边界

### `templates/api-resources/Definitions/_SecurityContext.tpl`

- access：`write`
- operations：`add define "definitions.securityContext"`、`add define "definitions.securityContext.struct"`、`add 两个 define 各自紧邻之前的整体契约注释`、`add 字段级中文注释`
- writable-scopes：文件内 `definitions.securityContext` 与 `definitions.securityContext.struct` 的契约注释及 `define` 块

### `templates/api-resources/Definitions/_Container.tpl`

- access：`read`
- operations：`consume 既有 include "definitions.securityContext" $_securityContext 调用与同源 os 注入契约`

## 验证设计

- `/tmp/sd-kube-chart/` 最小 application Chart 加载本 change 的目标模板、真实 `base` 依赖与 `definitions.appArmorProfile`、`definitions.seLinuxOptions`、`definitions.seccompProfile`、`definitions.windowsSecurityContextOptions` 真实实现；这些场景属于真实依赖集成。
- `definitions.capabilities` 的 unavailable 行为先在不提供同名模板时验证真实渲染中断；另提供同名最小 fixture 验证本层的取值、委托与结果回收，fixture 结果只证明调用方自身行为，不得表述为真实依赖集成通过。
- 最小有效输入：`{os: {name: linux}, runAsNonRoot: true}`，断言输出只含 `runAsNonRoot: true` 且可被 `fromYaml` 回收为 map。
- 较完整有效输入：linux 下除 `capabilities` 外的全部适用字段、windows 下 `windowsOptions` 与 `runAsNonRoot`、`os.name: Windows` 大写、`os.name: darwin`、`os` 缺省、显式 `0` 与 `false`、标量首尾空白、范围外键，逐项断言输出字段集合、顺序与取值。
- 关键失败输入：`os.name: windows` 下的 linux 专属字段（含 `{}`、`[]`、`""`、`0` 形式）、按 `linux` 处理时的 `windowsOptions`、非法 `procMount` 枚举、非 string `procMount`、非布尔布尔字段、非整数整数字段、结构字段标量输入，逐项断言渲染中断且失败信息包含字段名。
- 静态检查：目标模板无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、字段注释紧邻对应处理闭环、文件末尾单换行。
