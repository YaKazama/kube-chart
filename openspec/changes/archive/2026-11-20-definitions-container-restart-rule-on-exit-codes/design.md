# definitions.containerRestartRuleOnExitCodes 设计

## 技术目标

- capability：`definitions.containerRestartRuleOnExitCodes`
- artifact-type：`Helm 命名模板`
- target：`templates/api-resources/Definitions/_ContainerRestartRuleOnExitCodes.tpl` 中的 `definitions.containerRestartRuleOnExitCodes`

## 设计决策

### Decision: 在 Definitions 层新增独立结构模板

- requirements：`退出码匹配规则字段片段渲染`
- choice：新增 `templates/api-resources/Definitions/_ContainerRestartRuleOnExitCodes.tpl`，文件只定义 `definitions.containerRestartRuleOnExitCodes`。
- rationale：该结构属于 Kubernetes 原生 API 的共享结构，父级模板已按此名称调用；独立文件符合 Definitions 的文件与命名规则，并避免把子结构逻辑内联到父级。

### Decision: 严格按 map 字段读取并归一化 operator

- requirements：`退出码匹配规则字段片段渲染`
- choice：使用 `base.get` 读取 `operator` 并关闭别名识别；原始 YAML 标量经 `base.string.normalize` 解码后，缺失或空值立即中断。将解码值转为小写，只把 `in` / `notin` 投影为 `In` / `NotIn`；未命中值保持空值并交由 `base.field` 的官方允许值列表中断，命中值通过 `quote` 模式输出。
- rationale：`base.string.normalize` 负责 string 类型门禁与 YAML 标量解码；大小写映射在本模板完成，`base.field` 继续以官方 `In` / `NotIn` 列表承担最终枚举校验与字段渲染。关闭别名识别可避免 `operatorAlias` / `valuesAlias` 隐式生效。

### Decision: 解析 values 后集中校验数量与整数元素

- requirements：`退出码匹配规则字段片段渲染`
- choice：使用 `base.get` 读取 `values` 并关闭别名识别，经 `fromYamlArray` 恢复后先用 `base.isFromYamlArrayError` 排除解析错误；恢复结果长度为 0 或大于 255 时中断。逐个校验元素：`int`、`int64` 原值保留；等于整数的 `float64` 收敛为整数；其余类型及非整数数值中断。最终通过 `base.field` 与 `base.slice` 输出数组。
- rationale：缺失、null 与空数组通过解析错误或数组长度校验中断；非 array 输入由解析错误路径中断。逐个判断整数类型而不使用真值判断，确保显式 `0` 不被丢弃。

### Decision: 只输出当前结构的两个字段

- requirements：`退出码匹配规则字段片段渲染`
- choice：按 API 字段顺序渲染 `operator` 与 `values`，不输出父级键、默认值或其他字段。
- rationale：父级 `definitions.containerRestartRule` 负责 `exitCodes` 父键与整体字段片段组合；本模板只拥有 `ContainerRestartRuleOnExitCodes` 自身的可观察字段。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <上下文> "operator" "" "" false false` 与 `list <上下文> "values" "" "" false false`；关闭默认别名识别。
- output：YAML 文本；字段缺失时为空输出，`operator` 标量由 `base.string.normalize` 解码，`values` 数组由 `fromYamlArray` 恢复。
- ownership：`base.get` 负责取值、数据源优先级、集合序列化与别名开关；本模板负责必填、枚举、类型、数量和元素校验。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 返回的 `operator` 原始 YAML 标量文本。
- output：解码后的 string；空输入或 null 返回空字符串，非 string 标量中断。
- ownership：只负责 YAML 标量解码与 string 类型门禁，不负责枚举大小写归一化。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list "operator" <归一化后的 In 或 NotIn> "quote" (list "In" "NotIn")` 与 `list "values" <整数切片> "base.slice"`。
- output：单字段 YAML 片段；枚举不在允许列表或渲染值非法时中断。
- ownership：只负责单键渲染、官方枚举允许值校验与引号处理。

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`values` 的 `fromYamlArray` 返回值。
- output：布尔字符串；命中 Helm YAML 数组解析错误形态时为 `"true"`。
- ownership：只识别解析错误形态，不负责字段类型、数量或元素语义校验。

### Dependency: `base.slice`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：通过整数元素校验与归一化后的 `values` slice。
- output：YAML 数组文本；非 slice 输入中断。
- ownership：只负责 slice 类型门禁与序列化，不校验元素业务语义。

## 代码边界

### `templates/api-resources/Definitions/_ContainerRestartRuleOnExitCodes.tpl`

- access：`write`
- operations：`add` `definitions.containerRestartRuleOnExitCodes`
- writable-scopes：整个文件

### `templates/api-resources/Definitions/_ContainerRestartRule.tpl`

- access：`read`
- operations：`consume` 既有 `definitions.containerRestartRuleOnExitCodes` 调用契约

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume` `base.get`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume` `base.string.normalize` 与 `base.isFromYamlArrayError`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume` `base.field`

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume` `base.slice`

## 验证设计

- 在 `/tmp/` 最小 application Chart 中加载新模板及真实 `base.get`、`base.string.normalize`、`base.field`、`base.isFromYamlArrayError`、`base.slice`，实际执行 `helm template`；不使用同名 fixture 替代真实基础依赖。
- 最小有效输入覆盖 `operator: In` 与 `values: [0]`，验证输出字段及显式 `0` 保留。
- 较完整有效输入覆盖 `operator` 的 `in`、`notin` 等大小写变体、`NotIn` 输出、1 个元素与 255 个元素，验证归一化和数量上边界。
- 关键失败输入覆盖非 map 上下文、`operator` 缺失/null/空/非 string/非法枚举、`values` 缺失/null/非 array/空数组/非整数元素，以及 256 个元素。
