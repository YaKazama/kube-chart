# definitions.labelSelector 设计

## 技术目标

- capability：`definitions.labelSelector`
- artifact-type：Helm 共享结构命名模板与基础正则常量重命名
- target：`templates/api-resources/Definitions/_LabelSelector.tpl#definitions.labelSelector`

## 设计决策

### Decision: 表达式归一化后委托占位模板

- requirements：`matchExpressions 字符串简写归一化`、`matchExpressions 原生字典与 values 规则`、`LabelSelector 渲染顺序与占位边界`
- choice：在 `definitions.labelSelector` 内把每个 string 或 map 元素归一化为 `{key, operator, values?}`，再 `include` `definitions.labelSelectorRequirement`；返回经 `fromYaml`、错误 helper 和非空 map 校验后追加到 `matchExpressions`；`matchExpressions` 为 `null` 时按空列表处理，不输出该字段。本 change 不创建该模板、文件或 `define`。
- rationale：draft 要求把归一化项传给占位模板且不创建实现；该依赖在 design 中标记为 `unavailable`，验证使用同名最小 fixture。

### Decision: 正则常量重命名但内容不变

- requirements：`matchExpressions 字符串简写归一化`
- choice：仅重命名 `base.env` 的 `K8S.SELECTOR` 键为 `EQUALITY_FOR_APPS`、`SET_FOR_APPS`、`EXISTS_FOR_APPS`，正则内容保持 draft 已列出的值；模板一次加载 `base.env` 并复用这三个常量。
- rationale：draft 要求去掉数字并统一 `_FOR_APPS` 后缀，同时显式固定正则，避免后续采用其他表达式。

### Decision: 非法字符串和空集合均失败

- requirements：`matchExpressions 字符串简写归一化`
- choice：string 元素不能匹配三条正则之一，或 `in`、`notin` 的集合清洗后为空时，立即 `fail`；不跳过任何元素。
- rationale：draft 要求所有无法归一化的 string 输入失败，并遵循尽早失败原则。

### Decision: operator 输入大小写不敏感、输出规范大小写

- requirements：`matchExpressions 原生字典与 values 规则`
- choice：原生字典的 `operator` 先做大小写不敏感匹配，再归一化为 `In`、`NotIn`、`Exists`、`DoesNotExist`；字符串集合简写由 `SET_FOR_APPS` 的 `(?i)` 匹配并输出规范值。
- rationale：draft 要求输入不区分大小写，最终输出必须大小写敏感。

### Decision: 仅使用 base.get 内置别名

- requirements：`内置别名解析`
- choice：`definitions.labelSelector` 直接使用 `base.get` 读取 `matchExpressions`、`matchLabels`，由 `base.get` 自动处理 `matchExpressionsAlias`、`matchLabelsAlias`；不实现 `mExprs`、`mLabels` 显式别名。
- rationale：draft 移除显式别名，并明确 `*Alias` 是 `base.get` 的内置默认能力。

### Decision: values 统一清洗并恢复为字符串

- requirements：`matchExpressions 字符串简写归一化`、`matchExpressions 原生字典与 values 规则`
- choice：所有 values 经 `base.slice.cleanup` 清洗后用 `fromYamlArray` 恢复，再用 `toStrings` 输出 string array；`In`、`NotIn` 拒绝清洗后的空列表，`Exists`、`DoesNotExist` 不输出 values。
- rationale：draft 要求 `base.slice.cleanup` 清洗；该模板会把纯数字字符串转为 int、去重并去空，因此需要 `toString` 恢复官方要求的 string array。数字规范化、前导零和显式 `+` 丢失是该组合的确定结果。

### Decision: apps.deploymentSpec 仅透传内置别名

- requirements：`apps.deploymentSpec 内置别名透传`
- choice：在 selector 的 `pick` 列表中加入 `matchExpressionsAlias`、`matchLabelsAlias`，原样传给 `definitions.labelSelector`；不在 `apps.deploymentSpec` 内归一化或改变现有 `matchLabels` 与 `base.labels` 合并顺序。
- rationale：draft 明确只需在 `pick` 时保留并向下传递，别名优先和缺失回退由 `base.get` 处理；`pick` 缺失这两个字段时无需额外逻辑。

### Decision: matchLabels 保持必填和直接渲染

- requirements：`matchLabels 必填与直接渲染`
- choice：用 `base.get` 读取并解析 `matchLabels`（内置别名由其处理），排除 YAML 错误后要求非空，逐值校验 string，再以 `base.field` 和 `base.map` 渲染。
- rationale：draft 要求必填且字段类型以官方 object 定义为基准；别名由 `base.get` 统一回退。

## 依赖契约

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`rename`
- input：`""`
- output：可由 `fromYaml` 恢复的常量 Map；`K8S.SELECTOR` 下三个键名变化，正则内容不变。
- ownership：`base.env` 负责常量类型与结构；本模板只读取已锁定键并使用 `mustRegex*`。

### Dependency: `definitions.labelSelectorRequirement`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：dict，包含 `key`（string）、`operator`（规范大小写 string）和按需的 `values`（string array，仅 `In`/`NotIn`）
- output：可由 `fromYaml` 恢复的 map；空、无效 YAML 或非 map 由调用方失败
- ownership：占位模板负责 requirement 渲染；`definitions.labelSelector` 负责归一化、返回校验和列表回收。本 change 不创建该模板的任何实现或 `define`。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <上下文> <点分路径> [强制类型] [合并模式] [必填] [别名] [调试]`
- output：YAML string；无命中时为空输出，解析错误按调用方 helper 处理。
- ownership：`base.get` 负责数据源优先级和内置 `*Alias`；本模板负责业务类型校验。

### Dependency: `base.slice.cleanup`

- availability：`existing`
- source：`templates/base/_collection.tpl`
- operation：`consume`
- input：`list [数据, 拆分正则, 校验正则, 处理模板, 输出分隔符, 保留空字符串]`
- output：YAML 列表或 join 字符串；按契约拆分、trim、纯数字转 int、去重和去空。
- ownership：依赖负责集合清洗；本模板负责 operator 对应的非空约束和字符串恢复。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list <key> <value> [渲染模板] [允许值列表]`
- output：YAML 键值片段；空渲染值不输出。
- ownership：`base.field` 负责单字段格式化；本模板负责字段生效条件和选择 `base.map` / `base.slice`。

### Dependency: `base.map`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：map
- output：YAML map 字符串；非 map 失败。
- ownership：负责最终 map 类型门禁与序列化。

### Dependency: `base.slice`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：slice
- output：YAML list 字符串；非 slice 失败。
- ownership：负责最终 list 类型门禁与序列化。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：任意解析结果
- output：字符串 `"true"` 或 `"false"`
- ownership：负责识别 `fromYaml` 错误 map。

### Dependency: `base.labels`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：调用上下文
- output：可由 `fromYaml` 恢复的标签 map
- ownership：依赖负责基础标签生成；`apps.deploymentSpec` 负责与 selector 用户标签合并。

## 代码边界

### `templates/base/_env.tpl`

- access：`write`
- operations：`rename` `K8S.SELECTOR.EQUALITY0`、`SET0`、`SET_EXISTS`
- writable-scopes：`K8S.SELECTOR` 下的三个常量键名；表达式保持不变。

### `templates/api-resources/Definitions/_LabelSelector.tpl`

- access：`write`
- operations：`add` `define "definitions.labelSelector"`、`include "definitions.labelSelectorRequirement"` 及紧邻中文契约注释
- writable-scopes：整个新文件。

### `templates/api-resources/Apps/_DeploymentSpec.tpl`

- access：`write`
- operations：`update` selector `pick` 字段列表与透传
- writable-scopes：selector 字段处理块中的 `pick` 调用及其向下传递路径。

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume` `base.get` 入参、内置别名和返回契约。

### `templates/base/_collection.tpl`

- access：`read`
- operations：`consume` `base.slice.cleanup` 清洗与返回契约。

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume` `base.field` 渲染契约。

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume` `base.map`、`base.slice` 类型门禁。

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume` YAML 错误 helper。

### `templates/base/_k8s.tpl`

- access：`read`
- operations：`consume` `base.labels` 输出契约。

## 验证设计

- 最小有效：仅提供 `matchLabels`，输出只含 `matchLabels`。
- 较完整有效：覆盖 `=`、`==`、`!=`、`in`、`notin`、裸 key、`!key`、原生 `in`、原生 `NOTIN`、原生 `Exists`，并验证 `matchLabelsAlias`、`matchExpressionsAlias` 生效；在 `/tmp/` fixture 中提供同名 `definitions.labelSelectorRequirement`，返回归一化 dict 对应的 map。
- 正则边界：key/value 含 `.`、`_`、`-`；操作符两侧必需空白；`in`/`notin` 大小写不敏感；非法字符串和空集合均失败。
- 关键失败：`matchLabels` 缺失、为空 object 或非 map、标签值非 string；`matchExpressions` 非 array 或元素类型非法；原生 operator 不属于四个合法值；`In`/`NotIn` values 缺失、空或非 array；`Exists`/`DoesNotExist` 携带非空 values。
- 占位返回失败：fixture 分别返回空、无效 YAML 和非 map，`definitions.labelSelector` 必须失败并中断；fixture 只证明调用方行为。
- 集成边界：在 `/tmp/` 最小 application Chart 中加载真实 `_env.tpl`、base 模板和 `_LabelSelector.tpl`；`apps.deploymentSpec` 场景用同名 fixture 补齐其现有 `definitions.deploymentStrategy`、`core.podTemplateSpec` 和 `definitions.labelSelectorRequirement` 依赖，只证明 `pick` 保留内置别名并透传，不宣称完整资源集成通过。
- 结构边界：验证空 array 时省略 `matchExpressions`，存在性 operator 永不输出 `values`，显式别名 `mExprs`、`mLabels` 不被读取，`matchExpressions` 为 `null` 时按缺失处理并省略；真实 Chart 在占位模板缺失时不能独立渲染，集成结论仅限 fixture。
