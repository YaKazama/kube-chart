# definitions.container 设计

## 技术目标

- capability：`definitions.container`
- artifact-type：共享结构模板
- target：`templates/api-resources/Definitions/_Container.tpl`

## 设计决策

### Decision: 按 API 字段顺序逐字段闭环

- requirements：`Container 字段片段渲染`
- choice：在同一 `define` 内按 `args`、`command`、`env`、`envFrom`、`image`、`imagePullPolicy`、`lifecycle`、`livenessProbe`、`name`、`ports`、`readinessProbe`、`resizePolicy`、`resources`、`restartPolicy`、`restartPolicyRules`、`securityContext`、`startupProbe`、`stdin`、`stdinOnce`、`terminationMessagePath`、`terminationMessagePolicy`、`tty`、`volumeDevices`、`volumeMounts`、`workingDir` 的顺序逐字段完成“取值 → 解析 → 校验 → `base.field` 渲染”闭环。
- rationale：25 个字段中 13 个委托子模板、12 个直接渲染，字段间无共享状态；逐字段闭环使顺序与官方文档一一对应，也与同域 `definitions.podSecurityContext`、`definitions.topologySpreadConstraint` 的既有写法一致。

### Decision: image 按 FileRefs、imageRefs、image 三级回退

- requirements：`image 三源解析`
- choice：先取 `imageFileRefs` 经 `base.fileRefs` 合并后的内容：解析为 map 时按 `imageRefs` 规则拼接，否则按标量字符串直接使用；`imageFileRefs` 无有效结果时取 `imageRefs` 拼接；仍为空时回退 `image`；三级结果均为空时 `fail`。
- rationale：draft 指定 `*FileRefs` > `imageRefs` > `image`，并授权参考旧版 `workloads.Container.image`；旧版对文件内容正是“map 走拼接、list 失败、其余当字符串”的三路分支。先判 map 再用 `base.string.normalize` 解码标量，可让 list 形态按标量解码失败而中断。

### Decision: imageRefs 拼接规则

- requirements：`image 三源解析`
- choice：`registry`、`namespace` 去首尾 `/`；`repository` 归一后为空即 `fail`；`tag` 与 `digest` 同时为空时不产生尾缀；`digest` 非空且 `tag` 为空时 `tag` 取 `latest`；`digest` 不以 `sha256` 开头时补 `sha256:`；最终以 `/` 连接 `registry`、`namespace`、`repository`，再按需追加 `:tag` 与 `@digest`。
- rationale：与 draft 的四条 `imageRefs` 规则逐条对应；分段用 `compact` 剔除空段后再连接，可避免缺失 `registry` 或 `namespace` 时产生多余分隔符。

### Decision: 五个 FileRefs 字段统一委托 base.fileRefs 并覆盖内联字段

- requirements：`引用字段优先级`
- choice：`imageFileRefs`、`envFileRefs`、`envFromFileRefs`、`resourcesFileRefs` 取 `base.get` 原始输出后交给 `base.fileRefs`；返回值非空即视为有效结果并取代内联字段，为空时回退内联字段。`imageRefs` 是 map 而非文件引用，按 map 直接拼接。
- rationale：`base.fileRefs` 已承担 `filePath` 必填、Chart 内相对路径校验、根目录逃逸拒绝、文件存在性与 YAML map 解析，以及 `fieldPaths` 默认取文件名；本模板不重复实现路径与读取逻辑。draft 明确 `*FileRefs` 优先于内联字段，故采用覆盖而非追加。

### Decision: 委托字段统一回收流程

- requirements：`Container 字段片段渲染`
- choice：13 个委托字段均按“`base.get` 取原始输出 → 非空才处理 → `fromYaml`/`fromYamlArray` 恢复 → 错误 helper 排除解析错误 → 结果非空才 `include` 子模板 → 回收结果排除解析错误 → 非空时 `base.field` + `base.map`/`base.slice` 输出”执行；`securityContext` 额外把 `os` 合并进子模板上下文。
- rationale：`os` 是 `definitions.securityContext` 判断适用性的输入，draft 要求继续透传；其余流程与 `definitions.podSecurityContext.struct` 的既有结构委托写法同构，可保证子模板返回非法 YAML 时中断而非静默丢弃。

### Decision: 抽取数组与对象委托辅助模板

- requirements：`Container 字段片段渲染`
- choice：把委托回收流程抽成同文件内的三个辅助模板：`definitions.container.array` 承载 7 个数组字段（`env`、`envFrom`、`ports`、`resizePolicy`、`restartPolicyRules`、`volumeDevices`、`volumeMounts`），`definitions.container.struct` 承载 5 个对象字段（`lifecycle`、`livenessProbe`、`readinessProbe`、`resources`、`startupProbe`），`definitions.container.imageRef` 承载镜像拼接并被 `imageFileRefs` 的 map 分支与 `imageRefs` 两处复用；`securityContext` 因需注入 `os` 而在字段闭环内联处理。
- rationale：数组与对象的回收流程除字段名与子模板名外完全相同，抽成接受 `{key, define, raw}` 的单一实现可消除 12 处重复；三个辅助模板沿用 `definitions.container.` 前缀，符合同域共享结构层的命名约束。

### Decision: 直接渲染字段按类型选择渲染模板

- requirements：`Container 字段片段渲染`、`枚举字段校验`
- choice：`args`、`command` 以 `fromYamlArray` 恢复后 `base.slice` 输出；`imagePullPolicy`、`restartPolicy`、`terminationMessagePolicy` 归一后以 `quote` 与允许值列表输出；`stdin`、`stdinOnce`、`tty` 以 `base.bool` 输出；`image`、`name`、`terminationMessagePath`、`workingDir` 以 `quote` 输出。
- rationale：允许值列表使用精确字符串比较，天然满足 draft 的大小写敏感要求并在失败时给出合法范围；`base.bool` 保留显式 `false`，避免布尔假值被当成未设置；字符串统一加引号可防止 `on`、`yes`、`true` 等文本在父级回收时改变类型。

### Decision: name 按 DNS_LABEL 校验

- requirements：`Container 字段片段渲染`
- choice：`name` 以 `base.get` 必填取值、`base.string.normalize` 解码后 `trim`，再交给 `base.rfc` 的 `1123` 模式校验，校验结果以 `quote` 输出；缺失、为空或不符合 RFC1123 label 时中断。
- rationale：`base.rfc` 的 `1123` 模式已实现 RFC1123 正则与 63 字符上限，并在失败消息中给出规则与长度，无需重复实现；draft 明确指定复用该模式，与官方 `Container.name` 的 DNS_LABEL 语义一致。

### Decision: 调用方去掉 containers 包装键

- requirements：`上下文契约`
- choice：`core.podSpec` 的 `containers` 与 `initContainers` 两处调用改为 `mustMerge $_item (dict "os" $os) $containerExtras`，不再构造 `dict "containers" $_item`。
- rationale：draft 明确上下文不含 `containers` 包装键；去掉包装后容器字段位于顶层，`base.get` 可直接命中，也不需要子模板额外解包。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <上下文 map> "<字段名>"`；`name` 追加必填标记。
- output：可 `fromYaml` 解析的 YAML 字符串；字段缺失或为 null 时为空内容，必填时中断。
- ownership：`base.get` 负责数据源优先级、同级 `<字段>Alias` 识别、必填校验与序列化；本模板负责字段顺序、空值判定与输出决策。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 原始输出的 YAML 标量文本。
- output：解码后的 string；空输入返回空字符串；非 string 中断渲染。
- ownership：`base.string.normalize` 负责标量解码与 string 类型门禁；本模板负责 `trim`、空值判定与输出决策。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [key, 已归一化值, 渲染模板, 允许值列表]`。
- output：单行键值对或缩进 YAML 片段；值为空时不输出；枚举越界时中断并给出合法范围。
- ownership：`base.field` 负责单键渲染、引号处理与枚举校验；本模板负责字段生效判断。

### Dependency: `base.bool`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：原生布尔或字面量字符串 `"true"`、`"false"`。
- output：`"true"` 或 `"false"`；其他类型中断渲染。
- ownership：`base.bool` 负责布尔类型门禁；本模板负责空值判定与输出。

### Dependency: `base.fileRefs`

- availability：`existing`
- source：`templates/base/_fileRefs.tpl`
- operation：`consume`
- input：`list [上下文, FileRefs 原始 YAML 字符串]`；上下文需含 `Files`。
- output：合并结果的 YAML 字符串；无有效项时为空内容；路径非法、文件缺失或非 YAML map 时中断。
- ownership：`base.fileRefs` 负责路径校验、文件读取、`fieldPaths` 取值与结果合并；本模板负责优先级判定与结果解释。

### Dependency: `base.rfc`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：`list [name, "1123"]`。
- output：校验通过的字符串；不符合 RFC1123 label 或超过 63 字符时中断，失败消息给出规则与长度。
- ownership：`base.rfc` 负责 RFC1123 正则与长度校验；本模板负责必填取值与输出。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 返回值。
- output：布尔字符串，标识是否为解析错误形态。
- ownership：`base.isFromYamlError` 负责错误形态识别；本模板负责排除错误后继续处理。

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 返回值。
- output：布尔字符串，标识是否为解析错误形态。
- ownership：`base.isFromYamlArrayError` 负责错误形态识别；本模板负责排除错误后继续处理。

### Dependency: `definitions.resourceRequirements`

- availability：`existing`
- source：`templates/api-resources/Definitions/_ResourceRequirements.tpl`
- operation：`consume`
- input：已恢复为 map 的 `resources` 值，不注入 `_kind`，保留容器级资源键与 `claims`。
- output：可 `fromYaml` 解析为 map 的 ResourceRequirements 字段片段，允许为空内容。
- ownership：子模板负责资源键归一、校验与渲染；本模板负责来源选择、上下文传递与结果回收。

### Dependency: `definitions.enVar`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：已恢复为 map 的单个 `env` 元素，或 `envFileRefs` 解析结果中的单个元素。
- output：可 `fromYaml` 解析为 map 的 EnvVar 字段片段，允许为空内容。
- ownership：子模板内部结构由后续 change 实现；本模板负责数组归一、逐项委托与结果回收。

### Dependency: `definitions.envFromSource`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：已恢复为 map 的单个 `envFrom` 元素，或 `envFromFileRefs` 解析结果中的单个元素。
- output：可 `fromYaml` 解析为 map 的 EnvFromSource 字段片段，允许为空内容。
- ownership：子模板内部结构由后续 change 实现；本模板负责数组归一、逐项委托与结果回收。

### Dependency: `definitions.lifecycle`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：已恢复为 map 的 `lifecycle` 值。
- output：可 `fromYaml` 解析为 map 的 Lifecycle 字段片段，允许为空内容。
- ownership：子模板内部结构由后续 change 实现；本模板负责取值、类型门禁与结果回收。

### Dependency: `definitions.probe`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：已恢复为 map 的 `livenessProbe`、`readinessProbe` 或 `startupProbe` 值。
- output：可 `fromYaml` 解析为 map 的 Probe 字段片段，允许为空内容。
- ownership：子模板内部结构由后续 change 实现；本模板负责三种 probe 的取值、类型门禁与结果回收。

### Dependency: `definitions.containerPort`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：已恢复为 map 的单个 `ports` 元素。
- output：可 `fromYaml` 解析为 map 的 ContainerPort 字段片段，允许为空内容。
- ownership：子模板内部结构由后续 change 实现；本模板负责数组归一、逐项委托与结果回收。

### Dependency: `definitions.containerResizePolicy`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：已恢复为 map 的单个 `resizePolicy` 元素。
- output：可 `fromYaml` 解析为 map 的 ContainerResizePolicy 字段片段，允许为空内容。
- ownership：子模板内部结构由后续 change 实现；本模板负责数组归一、逐项委托与结果回收。

### Dependency: `definitions.containerRestartRule`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：已恢复为 map 的单个 `restartPolicyRules` 元素。
- output：可 `fromYaml` 解析为 map 的 ContainerRestartRule 字段片段，允许为空内容。
- ownership：子模板内部结构由后续 change 实现；本模板负责数组归一、逐项委托与结果回收。

### Dependency: `definitions.securityContext`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：已恢复为 map 的 `securityContext` 值与同源 `os`。
- output：可 `fromYaml` 解析为 map 的 SecurityContext 字段片段，允许为空内容。
- ownership：子模板内部结构与 `os` 适用性判断由后续 change 实现；本模板负责注入 `os`、结果回收与输出。

### Dependency: `definitions.volumeDevice`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：已恢复为 map 的单个 `volumeDevices` 元素。
- output：可 `fromYaml` 解析为 map 的 VolumeDevice 字段片段，允许为空内容。
- ownership：子模板内部结构由后续 change 实现；本模板负责数组归一、逐项委托与结果回收。

### Dependency: `definitions.volumeMount`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：已恢复为 map 的单个 `volumeMounts` 元素。
- output：可 `fromYaml` 解析为 map 的 VolumeMount 字段片段，允许为空内容。
- ownership：子模板内部结构由后续 change 实现；本模板负责数组归一、逐项委托与结果回收。

## 代码边界

### `templates/api-resources/Definitions/_Container.tpl`

- access：`write`
- operations：新增 `define "definitions.container"` 与三个辅助 `define`：`definitions.container.array`、`definitions.container.struct`、`definitions.container.imageRef`；含整体契约注释、各字段注释与字段处理闭环。
- writable-scopes：整个新增文件，包含上述 `define` 及注释。

### `templates/api-resources/Core/_PodSpec.tpl`

- access：`write`
- operations：更新 `containers` 与 `initContainers` 两处 `include "definitions.container"` 的上下文构造，去掉 `containers` 包装键。
- writable-scopes：`core.podSpec` 中 `containers` 与 `initContainers` 两处 `include "definitions.container"` 的上下文表达式。

### `templates/base/_get.tpl`

- access：`read`
- operations：核对 `base.get` 的入参顺序、必填标记与缺失字段的返回边界。

### `templates/base/_convert.tpl`

- access：`read`
- operations：核对 `base.string.normalize` 的入参形态、以及两个 YAML 解析错误 helper 的判据。

### `templates/base/_field.tpl`

- access：`read`
- operations：核对 `base.field` 的参数数量、`quote` 与允许值列表的组合语义以及空值输出条件。

### `templates/base/_types.tpl`

- access：`read`
- operations：核对 `base.bool` 接受的类型与失败边界。

### `templates/base/_k8s.tpl`

- access：`read`
- operations：核对 `base.rfc` 的 `1123` 模式正则、63 字符上限与失败消息。

### `templates/base/_fileRefs.tpl`

- access：`read`
- operations：核对 `base.fileRefs` 的入参形态、路径校验、合并语义与空结果边界。

### `templates/api-resources/Definitions/_ResourceRequirements.tpl`

- access：`read`
- operations：核对 `definitions.resourceRequirements` 的入参形态、`_kind` 语义与空结果边界。

## 验证设计

- 最小有效：只提供 `name` 与 `image`，断言输出含 `image` 与 `name` 且顺序为 `image`、`name`。
- 较完整有效：25 个字段齐全（委托字段由 fixture 提供最小实现），断言输出顺序与官方顺序一致。
- image 三源：仅 `image`；`imageRefs` 覆盖 `image`；`imageRefs` 只给 `repository`；`tag`/`digest` 均空；`digest` 有值且 `tag` 空；`digest` 无 `sha256` 前缀；三者均空时失败。
- 引用字段：`envFileRefs` 与 `env` 并存时取 FileRefs；FileRefs 无结果时回退内联；`filePath` 缺失、绝对路径、`../` 逃逸时失败。
- 枚举：三个枚举字段的合法值通过、非法值与大小写变体失败。
- 布尔：`stdin` 为 `false` 时输出 `stdin: false`。
- 关键失败：`name` 缺失；`name` 含大写字母、下划线或超长；`imageRefs` 缺 `repository`。
- 依赖边界：10 个 unavailable 子模板在 `/tmp/` 最小 Chart 中提供同名 fixture，只证明本模板的调用与回收行为；`base.*` 与 `definitions.resourceRequirements` 使用真实实现。另以真实 `core.podSpec` 的 `containers` 与 `initContainers` 入口做集成渲染，fixture 仅覆盖 unavailable 子模板。
