# PodSecurityContext 共享结构设计

## 技术目标

- capability：`definitions.podSecurityContext`
- artifact-type：Kubernetes 共享结构命名模板
- target：`templates/api-resources/Definitions/_PodSecurityContext.tpl` 中 `define "definitions.podSecurityContext"`

## 设计决策

### Decision: 目标文件与命名模板归属

- requirements：`渲染 PodSecurityContext 字段片段`
- choice：新增 `templates/api-resources/Definitions/_PodSecurityContext.tpl`，文件内定义 `definitions.podSecurityContext` 及其同前缀辅助模板 `definitions.podSecurityContext.struct`。
- rationale：`PodSecurityContext` 是 Kubernetes 官方结构，仅被 `PodSpec.securityContext` 复用，属可跨资源复用的同域共享结构，只能落在 `api-resources/Definitions`；该目录现有 `_PodOS.tpl`、`_ObjectMeta.tpl` 等均沿用 `_<结构名>.tpl` 与 `definitions.<能力>` 命名。`definitions.podSecurityContext` 当前在全 Chart 不存在，属纯新增；既有调用点 `templates/api-resources/Core/_PodSpec.tpl` 已以 `include "definitions.podSecurityContext" $securityContext` 消费，本 change 补齐该定义。

### Decision: os 取值与容错归一

- requirements：`按 os 校验字段适用性`
- choice：以 `base.get` 的 `list [上下文, "os.name"]` 非必填取值；原始输出非空时经 `base.env` 的 `SYS.YAML_QUOTED` 剥离 YAML 引号并 `trim`，再用内置 `lower` 转小写；结果等于 `windows` 时判定为 `windows`，其余全部判定为 `linux`，全程不 `fail`。
- rationale：规格要求 `os` 缺省、非 map、`os.name` 缺失或无法归一化为 string 时都回退 `linux`，因此不能用会在数字与布尔上中断的 `base.string.normalize`。`base.get` 的点分路径在父级不是 map 时按缺失处理，天然覆盖“`os` 不是 map”；`base.get` 对标量返回 `toYamlPretty` 文本，空白与特殊字符串可能被加引号，因此必须先剥离引号再比较。该写法与 `templates/api-resources/Core/_PodSpec.tpl` 归一布尔字段时使用 `SYS.YAML_QUOTED` 的既有模式一致。

### Decision: 适用性前置校验与存在性判定

- requirements：`按 os 校验字段适用性`
- choice：在任何字段输出前，按 `os` 选出禁止字段列表（`windows` 时为 11 个 linux 专属字段，按 `linux` 处理时为 `windowsOptions`），逐项以 `hasKey` 检查规范键与 `<字段>Alias`，命中且值不是 `invalid`（即非 `null`）时以 `[definitions.podSecurityContext] <字段>: cannot be set when os is <os>` 中断。
- rationale：规格要求判定与取值真假无关，而 `base.get` 对空字符串与缺失同样返回空输出，无法区分二者；`hasKey` 加 `kindIs "invalid"` 排除恰好同时满足“空字符串算存在”和“`null` 算不存在”两条边界。判定只读取本模板上下文自身，不读取 `.Context`、`.Values`、`.Values.global`：调用点传入的隔离 map 才是 `securityContext` 的唯一来源，扫描 `.Values` 会把父 Chart 中的同名无关键误判为 `securityContext` 字段。前置校验先于渲染完成，与 `_PodSpec.tpl` 中“跨字段互斥约束在任何字段输出前完成”的既有约定一致。`<字段>Alias` 一并检查，避免 `base.get` 的默认别名识别把禁止字段以别名形式送入渲染。

### Decision: 委托结构字段的辅助模板

- requirements：`委托结构字段`
- choice：新增辅助模板 `definitions.podSecurityContext.struct`，入参为 `dict "key" <输出键名> "define" <子模板名> "raw" <base.get 原始输出>`；模板内依次完成原始输出判空、`fromYaml`、解析错误中断、非 map 中断、空 map 跳过、`include` 子模板、结果 `fromYaml` 与解析错误中断、非空时 `base.field` + `base.map` 输出；子模板输出不可解析时以 `[definitions.podSecurityContext] <key>: invalid YAML output from <define>` 中断，输入不是 map 时以 `[definitions.podSecurityContext] <key>: must be map type` 中断。四个字段各以一行调用该辅助模板。
- rationale：四个字段的闭环完全同构，但其输出位置被 `fsGroup`、`runAsNonRoot`、`supplementalGroups` 等字段分隔，无法合并为单次循环；抽出辅助模板既满足 API 字段顺序，又避免四段重复代码，与既有 `definitions.resourceRequirements.field` 的辅助模板模式一致。委托前必须做 `kindIs "map"` 判定：`fromYaml` 对标量文本会成功返回标量而非错误 map，若不拦截会把标量作为上下文送入子模板，违反“子模板上下文必须是 map”的工程约束。

### Decision: sysctls 清洗链

- requirements：`sysctls 清洗与委托`
- choice：`base.get` 取值后以 `fromYamlArray` 恢复并检查 `base.isFromYamlArrayError`；逐条判定条目是 map，否则中断；`name`、`value` 通过 `get` 读取，`invalid` 归零为 `""`，map 或 slice 中断，其余用 `toString` 归一化后 `trim`；两项都非空时以 `dict "name" ... "value" ...` 投影并追加，随后 `mustUniq` 去重；结果非空时逐条 `include "definitions.sysctl"` 并回收非空解析结果，最后以 `base.field` + `base.slice` 输出。
- rationale：投影后再去重才能让多余键不影响条目同一性，并让同名不同值条目因 `value` 不同而保留；`mustUniq` 按值深比较且保留首次出现顺序，正好对应“完整条目去重、后值由 Kubernetes 侧覆盖”。用 `toString` 而非 `base.string.normalize`：YAML 中 `value: 1` 会被解析为整数标量，规格要求 `"0"` 等取值合法，而 `base.string.normalize` 会拒绝数字与布尔。`base.slice` 负责最终类型门禁，因此不在解析后重复 `kindIs "slice"`。

### Decision: supplementalGroups 清洗链

- requirements：`supplementalGroups 清洗`
- choice：`base.get` 取值后以 `fromYamlArray` 恢复并检查解析错误；逐项跳过 `invalid` 与空字符串，其余用 `base.int` 归一化并 `atoi` 转整数，失败由 `base.int` 中断；`mustUniq` 去重后非空时以 `base.field` + `base.slice` 输出。
- rationale：规格要求 `null` 与空字符串被移除而 `0` 保留，因此不能用按布尔真假过滤的通用清洗函数；`base.int` 已提供整数类型门禁与失败消息，调用方无需重复 `kindIs`。`atoi` 只把 `base.int` 已校验过的数字文本转成 int，保证 `mustUniq` 的深比较在同一类型上进行。

### Decision: 标量字段的取值与渲染

- requirements：`渲染 PodSecurityContext 字段片段`、`枚举与类型校验`
- choice：`fsGroup`、`runAsGroup`、`runAsUser` 以 `base.get` 取值后交给 `base.int` 校验并转 int，再以 `base.field` + `base.int` 输出，显式 `0` 同样输出；`runAsNonRoot` 以 `base.get` 取值后剥离 `SYS.YAML_QUOTED` 引号并 `trim`，非空时以 `base.field` + `base.bool` 输出，显式 `false` 同样输出；`fsGroupChangePolicy`、`seLinuxChangePolicy`、`supplementalGroupsPolicy` 以 `base.string.normalize` 归一并 `trim`，非空时以 `base.field` + `base.string` 加允许值列表输出。
- rationale：字段生效条件由 `base.get` 原始输出是否为空决定，与 `_PodSpec.tpl` 同类字段一致；`base.int`、`base.bool` 是项目唯一的整数与布尔类型门禁，`base.field` 的允许值列表在渲染前完成枚举校验并给出合法范围，满足“枚举失败由 `fail` 中断并给出范围”，无需本模板重复实现比较分支。`runAsNonRoot` 需要剥离引号，因为 `base.get` 对字符串 `"true"` 会输出带引号的标量，而 `base.bool` 只接受布尔值与不带引号的 `true`、`false`。

### Decision: 返回值形态

- requirements：`渲染 PodSecurityContext 字段片段`、`委托结构字段`
- choice：模板只输出字段片段，不输出 `os`、父级 `securityContext` 键、`---`、`apiVersion` 或 `kind`；无任何可输出字段时返回空内容。
- rationale：既有调用点 `core.podSpec` 以 `include "definitions.podSecurityContext" $securityContext | fromYaml` 消费，并按“解析错误或空值则跳过”处理，空内容是其正常分支；`PodSecurityContext` 官方字段表中没有 `os`，该键只作为控制输入。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, "<字段>"]` 形式的非必填取值，`os` 使用点分路径 `"os.name"`；别名保持默认开启。
- output：可由 `fromYaml` 解析的 YAML 字符串；标量经 `toYamlPretty` 序列化，字符串可能带 YAML 引号；路径缺失、为 `null` 或空字符串时为空输出。
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
- input：`list ["<字段名>", 归一化后的值, "base.map" | "base.slice" | "base.int" | "base.bool" | "base.string", 可选允许值列表]`。
- output：值生效时输出字段片段，空值时不输出；渲染模板类型不符时中断；枚举未命中时以 `[base.field]` 前缀中断并给出合法范围。
- ownership：枚举比较、字段输出格式与最终类型门禁由依赖层负责；字段生效条件与归一化结果由本层负责。

### Dependency: `base.map`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：已完成子模板委托并恢复的 map。
- output：`toYamlPretty` 序列化结果；非 map 输入中断。
- ownership：序列化与类型门禁由依赖层负责；委托结果的回收与生效判断由本层负责。

### Dependency: `base.slice`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：已完成清洗并恢复的 slice。
- output：`toYamlPretty` 序列化结果；非 slice 输入中断。
- ownership：序列化与类型门禁由依赖层负责；清洗、去重与回收由本层负责。

### Dependency: `base.int`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：`base.get` 返回的原始文本，或 `fromYamlArray` 恢复后的单个元素。
- output：整数文本；非整数类型或非整数文本中断。
- ownership：整数类型门禁与失败消息由依赖层负责；调用时机与 `atoi` 转换由本层负责。

### Dependency: `base.bool`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：已剥离 YAML 引号并 `trim` 的 `runAsNonRoot` 取值。
- output：`true` 或 `false`；其他类型或非 `true`、`false` 文本中断。
- ownership：布尔类型门禁由依赖层负责；引号剥离与调用时机由本层负责。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 返回的原始文本。
- output：解码后的 string；空输入返回空字符串；非 string 标量中断。
- ownership：YAML 标量解码由依赖层负责；判空与枚举允许值选择由本层负责。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 的返回值。
- output：错误 map 时为 `true`，否则为 `false`。
- ownership：错误形态识别由依赖层负责；中断消息由本层负责。

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 的返回值。
- output：错误 slice 时为 `true`，否则为 `false`。
- ownership：错误形态识别由依赖层负责；中断消息由本层负责。

### Dependency: `definitions.appArmorProfile`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：已通过类型门禁的 `appArmorProfile` map。
- output：可 `fromYaml` 解析为 map 的 AppArmorProfile 字段片段，允许为空内容。
- ownership：本层负责取值、类型门禁、空 map 跳过与结果回收；子模板内部结构由后续 change 实现，本 change 不创建其 `define`。

### Dependency: `definitions.seLinuxOptions`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：已通过类型门禁的 `seLinuxOptions` map。
- output：可 `fromYaml` 解析为 map 的 SELinuxOptions 字段片段，允许为空内容。
- ownership：本层负责取值、类型门禁、空 map 跳过与结果回收；子模板内部结构由后续 change 实现，本 change 不创建其 `define`。

### Dependency: `definitions.seccompProfile`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：已通过类型门禁的 `seccompProfile` map。
- output：可 `fromYaml` 解析为 map 的 SeccompProfile 字段片段，允许为空内容。
- ownership：本层负责取值、类型门禁、空 map 跳过与结果回收；子模板内部结构由后续 change 实现，本 change 不创建其 `define`。

### Dependency: `definitions.sysctl`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：只含 `name` 与 `value` 的非空 map。
- output：可 `fromYaml` 解析为 map 的 Sysctl 字段片段，允许为空内容。
- ownership：本层负责条目清洗、投影、去重与结果回收；子模板内部结构由后续 change 实现，本 change 不创建其 `define`。

### Dependency: `definitions.windowsSecurityContextOptions`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：已通过类型门禁的 `windowsOptions` map。
- output：可 `fromYaml` 解析为 map 的 WindowsSecurityContextOptions 字段片段，允许为空内容。
- ownership：本层负责取值、类型门禁、空 map 跳过与结果回收；子模板内部结构由后续 change 实现，本 change 不创建其 `define`。

## 代码边界

### `templates/api-resources/Definitions/_PodSecurityContext.tpl`

- access：`write`
- operations：`add define "definitions.podSecurityContext"`、`add define "definitions.podSecurityContext.struct"`、`add 两个 define 各自紧邻之前的整体契约注释`、`add 字段级中文注释`
- writable-scopes：文件内 `definitions.podSecurityContext` 与 `definitions.podSecurityContext.struct` 的契约注释及 `define` 块

## 验证设计

- `/tmp/` 最小 application Chart 加载本 change 的目标模板与真实 `base` 依赖，并为 5 个 `unavailable` 子模板提供同名最小 fixture；fixture 只证明本层的取值、清洗、回收与调用行为，不得表述为真实依赖集成通过。
- 最小有效输入：`os.name: linux` 与 `fsGroup: 1000`，断言输出只含 `fsGroup` 且可被 `fromYaml` 回收为 map。
- 较完整有效输入：linux 全字段有效值、windows 下 `windowsOptions` 与 `runAsNonRoot`、`os.name: Windows` 大写、`os.name: darwin`、`os` 缺省、显式 `0` 与 `false`、`sysctls` 与 `supplementalGroups` 的重复与空值组合、范围外键，逐项断言输出字段集合、顺序与取值。
- 关键失败输入：`os.name: windows` 下的 linux 专属字段（含 `{}`、`[]`、`""`、`0` 形式）、按 `linux` 处理时的 `windowsOptions`、非法枚举、非整数整数字段、非布尔 `runAsNonRoot`、结构字段标量输入、`sysctls` 非 map 条目与 map 类型 `name`、`supplementalGroups` 非整数元素，逐项断言渲染中断且失败信息包含字段名。
- 静态检查：目标模板无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、字段注释紧邻对应处理闭环、文件末尾单换行。
