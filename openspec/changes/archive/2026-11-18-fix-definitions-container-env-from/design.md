# definitions.container envFrom 输入设计

## 技术目标

- capability：`definitions.container`
- artifact-type：Helm 命名模板（library Chart）
- target：`templates/api-resources/Definitions/_Container.tpl` 中 `definitions.container` 的 `envFrom` 字段块，以及 `templates/base/_env.tpl` 中 `base.env` 的 `K8S.ENV_FROM` 常量

## 设计决策

### Decision: envFrom 取值来源与数组类型门禁

- requirements：`envFrom 数组元素归一化`
- choice：保留现有 `envFromFileRefs` > `envFrom` 取值块不变；取得原始输出后立即 `fromYamlArray`，用 `base.isFromYamlArrayError` 排除解析错误，错误时以 `[definitions.container] envFrom: must be array type` 中断。
- rationale：`base.get` 与 `base.fileRefs` 返回的都是 YAML 文本，array 只能经 `fromYamlArray` 恢复；规格要求非 array 立即失败，该消息与 `definitions.container.array` 对同一字段的既有措辞一致，避免同一字段出现两套错误文本。`base.get` 对缺失键与 `null` 均返回空输出，因此现有 `if $_envFromSource` 判空天然覆盖“未提供”分支。

### Decision: 元素类型分支与归一化回收

- requirements：`envFrom 数组元素归一化`
- choice：以 `range` 遍历恢复后的数组，用 `kindIs "map"` 原样回收，用 `kindIs "string"` 进入字符串简写解析，其余类型以 `[definitions.container] envFrom: each item must be string or object type` 中断；回收结果写入由 `list` 起的 `$envFromItems`。
- rationale：数组元素未经结构恢复，`kindIs` 正是规则允许的多类型分支判据；恢复后的列表已由 `fromYamlArray` 保证为 list，不再重复类型判断。归一化在调用 `definitions.container.array` 之前完成，因此该模板入参始终是全 map 数组。

### Decision: 字符串简写由单一捕获组正则解析

- requirements：`envFrom 字符串简写解析`
- choice：在 `base.env` 的 `K8S` 段新增 `ENV_FROM`；运行时表达式为 `^((?i:cm|configmap|secret))[,\s]+([^,\s]+)(?:[,\s]+([^,\s]+))?(?:[,\s]+([^,\s]+))?$`，依次捕获关键字、`name`、可选 `prefix`、可选 `optional`；模板先 `mustRegexMatch` 确认匹配，再用 `mustRegexReplaceAll` 以 `$1`、`$2`、`$3`、`$4` 取值并逐项 `trim`。
- rationale：规格要求正则提供捕获组、Helm 函数按捕获组取值，并要求段位固定；单条锚定表达式同时约束段数 2 至 4 与关键字范围，少于 2 段、多于 4 段和未知关键字都落到同一次不匹配，不需要额外的段数或关键字分支。分隔符 `[,\s]+` 与 `SPLIT.SPACE_COMMA` 的匹配集合等价（空白与逗号），但正则契约要求固定表达式集中定义且禁止模板内拼接，因此该表达式作为独立常量维护，模板不拼接 `SPLIT.SPACE_COMMA`。`_env.tpl` 源码位于 YAML 双引号字符串内，源码写作 `\\s`，运行时以 `base.env | fromYaml` 恢复后的 `\s` 为准。
- 已验证的语义边界：RE2 的贪婪匹配会先满足 `$3`，因此 `cm app-config true` 的第三段落入 `prefix` 而非 `optional`；把 `optional` 组提前或限定为 `true|false` 会反过来破坏 `cm app-config /app true`，而 RE2 不支持 `(?=)`/`(?!)`，无法写出“`prefix` 不得为布尔词”。规格已锁定为“3 段输入的第三段一律为 `prefix`”，与本实现一致。

### Decision: 关键字映射与大小写边界

- requirements：`envFrom 字符串简写解析`
- choice：正则只用 `(?i:…)` 局部标志放开关键字段大小写；捕获结果经 `lower` 作为键，从 `dict "cm" "configMapRef" "configmap" "configMapRef" "secret" "secretRef"` 取值；`name`、`prefix`、`optional` 保持捕获原文。
- rationale：`definitions.envVar` 对 `valueFrom` 关键字已采用同一 `dict` + `lower` 写法，同域保持一致；局部标志只放开关键字，其余段仍大小写敏感。正则已限定关键字范围，映射必然命中，因此不添加空值分支。

### Decision: 归一化元素构造

- requirements：`envFrom 字符串简写解析`
- choice：引用值为 `trim (printf "%s %s" <name> <optional>)`，`optional` 捕获为空时结果自然等于 `<name>`；元素先构造 `dict <refKey> <ref>`，`prefix` 捕获非空时以 `set` 追加 `prefix` 键，不使用占位默认值。
- rationale：规格要求 ref 值以 string 向下传递，并由下游从 `<name> [optional]` 拆分，`printf` + `trim` 直接得到该形态且不引入 `optional` 键；`prefix` 捕获为空即未提供，一次判空即可决定是否写键，避免输出空 `prefix`。`name`、`optional` 不在本层校验，构造中不加入字符集或布尔处理。

### Decision: 归一化结果交回 definitions.container.array

- requirements：`envFrom 数组元素归一化`
- choice：回收完成后用 `mustToJson` 把 `$envFromItems` 序列化为文本，作为 `definitions.container.array` 的 `raw` 入参；`definitions.container.array` 与其字段输出逻辑保持现状。
- rationale：规格要求解析在调用 `definitions.container.array` 之前完成，而该模板的入参形态是 `raw` 文本；JSON 是 `fromYamlArray` 可直接恢复的合法 YAML，序列化由既有入参形态决定，不是为缩短代码引入的额外转换。map 元素经同一次文本往返后内容不变，避免为纯 map 输入保留第二条分支。

### Decision: 失败边界与消息

- requirements：`envFrom 数组元素归一化`、`envFrom 字符串简写解析`
- choice：非 array → `[definitions.container] envFrom: must be array type`；元素类型非法 → `[definitions.container] envFrom: each item must be string or object type`；字符串不匹配 → `[definitions.container] envFrom: invalid item '<原文>'`。
- rationale：工程规则要求失败消息统一为“模板名 + 字段路径: 原因”，三条消息都保留 `envFrom` 定位；段数越界与关键字非法由同一条正则不匹配覆盖，不拆分为独立分支，也不为 `optional`、`name` 增加本层校验消息。

## 依赖契约

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`add`
- input：空 string `""`
- output：可由 `fromYaml` 恢复的常量 map；本 change 新增 `K8S.ENV_FROM`，运行时值为 `^((?i:cm|configmap|secret))[,\s]+([^,\s]+)(?:[,\s]+([^,\s]+))?(?:[,\s]+([^,\s]+))?$`
- ownership：负责集中常量的结构、类型与存储位置；本模板负责匹配、按捕获组取值与失败

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <当前上下文> "envFrom"` 与 `list <当前上下文> "envFromFileRefs"`
- output：YAML 文本；缺失、`null` 与空字符串标量为空输出
- ownership：负责多层取值、别名默认语义与序列化；本模板负责来源优先级、数组恢复与元素归一化

### Dependency: `base.fileRefs`

- availability：`existing`
- source：`templates/base/_fileRefs.tpl`
- operation：`consume`
- input：`list <当前上下文> <envFromFileRefs 原始文本>`
- output：合并后内容的 YAML 文本；无有效项时为空内容
- ownership：负责 Chart 内路径校验、文件读取与字段合并；本模板只消费其结果并执行同一套归一化

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：任意 `fromYamlArray` 返回值
- output：string boolean，仅错误 slice 返回 `"true"`
- ownership：识别 Helm 数组解析错误形态；本模板负责在错误时中断

### Dependency: `definitions.container.array`

- availability：`existing`
- source：`templates/api-resources/Definitions/_Container.tpl`
- operation：`consume`
- input：`dict "key" "envFrom" "define" "definitions.envFromSource" "raw" <全 map 数组的序列化文本>`
- output：可嵌入 Container 的单字段 YAML 片段；元素全部渲染为空时为空内容
- ownership：负责数组解析、元素 map 门禁、逐项委托与 `envFrom` 字段输出；本模板负责元素归一化、来源优先级与失败文本

### Dependency: `definitions.envFromSource`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：单个 `EnvFromSource` 形状的 map，元素归一化结果形如 `{configMapRef: "<name>"}`、`{configMapRef: "<name> <optional>", prefix: "<prefix>"}` 或对应的 `secretRef` 形态
- output：可 `fromYaml` 解析为 map 的字段片段，允许为空内容；无效 YAML 由 `definitions.container.array` 中断
- ownership：负责 `configMapRef`/`secretRef` 的渲染、ref 字符串的 `name` 与 `optional` 拆分、`prefix` 输出顺序与 `optional` 布尔语义；本 change 不创建该模板，其实现由 `openspec/changes/definitions-env-from-source/` 负责

## 代码边界

### `templates/api-resources/Definitions/_Container.tpl`

- access：`write`
- operations：update `definitions.container` 整体契约注释中的 `envFrom` 行；update `definitions.container` 内 `envFrom` 字段注释与其后的字段块（保留 `envFromFileRefs` > `envFrom` 取值、新增数组恢复、元素类型分支、字符串解析与 `definitions.container.array` 调用）
- writable-scopes：`definitions.container` 契约注释的 `envFrom` 行；`definitions.container` 内 `envFrom` 字段注释及其后完整的 `envFrom` 字段块

### `templates/base/_env.tpl`

- access：`write`
- operations：add `base.env` 的 `K8S.ENV_FROM` 常量及其紧邻注释
- writable-scopes：`base.env` 内 `K8S.ENV_FROM` 键与紧邻该键的注释行

### `templates/base/_get.tpl`

- access：`read`
- operations：consume `base.get`

### `templates/base/_fileRefs.tpl`

- access：`read`
- operations：consume `base.fileRefs`

### `templates/base/_convert.tpl`

- access：`read`
- operations：consume `base.isFromYamlArrayError`

## 验证设计

- 在 `/tmp/` 最小 application Chart 中加载真实 `_Container.tpl`、`_env.tpl`、`_get.tpl`、`_convert.tpl`、`_field.tpl`、`_types.tpl` 与 `_fileRefs.tpl` 及其必要依赖 `_validate.tpl`、`_collection.tpl`，`definitions.envFromSource` 用同名 fixture 回显上下文；不宣称真实子模板集成通过。
- 最小有效场景：`envFrom` 为单个 map 元素的数组，确认 map 元素原样输出。
- 较完整有效场景：`configMap`、`cm`、`secret` 与大小写变体；2 段、3 段、4 段输入；空白、逗号及混用分隔；string 与 map 混合数组；`envFromFileRefs` 提供内容时的优先级与同一套归一化。
- 边界场景：`prefix` 与 `optional` 捕获为空、`optional` 为非布尔 token、`name` 含大小写与下划线仍在本层通过。
- 关键失败场景：`envFrom` 为单个 string、map 或标量；元素为数字或布尔；1 段与 5 段输入；关键字为 `env`、`config`、`secretKey`。
- 未提供场景：`envFrom` 缺失与为 `null` 时不输出该字段且不失败。
- fixture 只证明本模板自身的分支与返回边界；静态检查只覆盖两个 write boundary 的空白、冲突标记、Go Template 结构与文件末尾单一换行。
