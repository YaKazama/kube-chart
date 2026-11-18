# definitions.envFromSource 设计

## 技术目标

- capability：`definitions.envFromSource`
- artifact-type：Kubernetes 原生 API 同域共享结构模板（`EnvFromSource`）
- target：`templates/api-resources/Definitions/_EnvFromSource.tpl`

## 设计决策

### Decision: 单文件承载并沿用共享结构命名

- requirements：`互斥引用识别与分发`、`原生对象透传`、`引用字符串归一`、`prefix 输出`、`非法值类型中断`、`子模板委托边界`
- choice：新建 `templates/api-resources/Definitions/_EnvFromSource.tpl`，只包含 `definitions.envFromSource` 一个 define，不拆分辅助模板，不创建两个子模板。
- rationale：共享结构文件围绕与文件名对应的主模板组织；两个引用字段的处理链完全同构，单文件即可承载，拆分没有复用收益；未经规格授权的占位 define 不得新增。

### Decision: hasKey 判定互斥并用 ternary 收敛字段与子模板选择

- requirements：`互斥引用识别与分发`
- choice：用 `hasKey` 分别判定 `configMapRef` 与 `secretRef` 是否出现，两个布尔量相同时中断渲染并把实际出现的字段名拼入失败消息；随后用 `ternary` 由同一布尔量派生引用字段名与子模板名。
- rationale：互斥校验必须在任何组装之前完成，否则双字段输入会产出部分结果；`ternary` 把字段名与子模板名的二选一集中一处，避免两段同构分支。

### Decision: 用 get 与 kindIs 区分引用值类型

- requirements：`原生对象透传`、`非法值类型中断`
- choice：用 `get` 读取引用字段的原生值，用 `kindIs` 区分 map、string 与其他类型；其他类型直接以字段名中断。
- rationale：本层是单键访问而非多层路径，`base.get` 会把字段值序列化为 YAML 文本，使数字、布尔与字符串在类型上不可区分，无法实现「非 map 且非 string 中断」；直接读取原生值一次即可同时得到真实类型与内容。

### Decision: 引用字符串使用 base.env 分隔符与位次映射

- requirements：`引用字符串归一`
- choice：对字符串先 `trim`，再用 `SPLIT.SPACE_COMMA` 以 `mustRegexSplit` 全量切分，用 `mustWithout` 丢弃空段；切分结果非空时把第 1 段写入 `name`，存在第 2 段时写入 `optional`，超出部分不读取；没有段时不进入委托。
- rationale：分隔符必须复用 `base.env` 现有常量；空段丢弃与段数判定必须发生在位次映射之前，否则位次会被空段挤偏。

### Decision: 引用与 prefix 先渲染为片段再按官方顺序拼接

- requirements：`原生对象透传`、`引用字符串归一`、`prefix 输出`、`子模板委托边界`
- choice：子模板输出经 `fromYaml` 与 `base.isFromYamlError` 保护，非空时用 `base.field (list <引用字段名> <恢复值> "base.map")` 渲染为片段；`prefix` 经 `base.get` 与 `base.string.normalize` 取值后 `trim`，非空时用 `base.field (list "prefix" <值> "quote")` 渲染为片段；最后按 `configMapRef` 前置、`secretRef` 后置的顺序输出两个片段。
- rationale：官方字段顺序把 `prefix` 夹在两个互斥字段之间，先各自渲染再按布尔量拼接可让顺序与分发解耦，避免在字段处理块内复制顺序判断；`base.map` 与 `quote` 承担最终类型门禁，本能力不重复类型检查。

## 依赖契约

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：占位空字符串，经 `fromYaml` 恢复常量 Map。
- output：常量 Map；本能力只读取 `SPLIT.SPACE_COMMA`。
- ownership：常量定义与结构有效性由该模板负责；本能力不得内联、拼接或改写该表达式。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, "prefix"]`。
- output：YAML 字符串；路径缺失或为空时为空输出。
- ownership：取值优先级、别名识别与序列化由该模板负责；字段生效判断由本能力负责。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 的原始输出，不预先 trim。
- output：解码后的 string；非 string 标量中断，失败消息使用其自身前缀。
- ownership：YAML 标量解码与类型门禁由该模板负责；本能力只负责 `trim` 与生效判断。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [引用字段名, 已恢复的 map, "base.map"]` 与 `list ["prefix", 非空 string, "quote"]`。
- output：单字段 YAML 片段，空值不输出。
- ownership：渲染格式由该模板负责；字段生效判断由本能力负责。

### Dependency: `base.map`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：已恢复的 map。
- output：换行缩进的 YAML 映射；非 map 输入中断。
- ownership：作为 `base.field` 的渲染模板执行最终类型门禁。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 的返回值。
- output：布尔字符串。
- ownership：错误形态识别由该模板负责，本能力只据此在子模板输出非法时中断。

### Dependency: `definitions.configMapEnvSource`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`ConfigMapEnvSource` map，字段为 `name`、`optional`；`optional` 到达时可能为任意 string。
- output：可由 `fromYaml` 解析的 `ConfigMapEnvSource` 字段片段；空结果表示不渲染该字段；失败消息使用其自身前缀。
- ownership：本能力只负责分发、类型区分与字符串位次组装；字段校验、`optional` 布尔语义与缺省处理由该子模板负责，本 change 不实现。

### Dependency: `definitions.secretEnvSource`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`SecretEnvSource` map，字段为 `name`、`optional`；`optional` 到达时可能为任意 string。
- output：可由 `fromYaml` 解析的 `SecretEnvSource` 字段片段；空结果表示不渲染该字段；失败消息使用其自身前缀。
- ownership：同上，本 change 不实现。

## 代码边界

### `templates/api-resources/Definitions/_EnvFromSource.tpl`

- access：`write`
- operations：add `definitions.envFromSource`
- writable-scopes：整个新建文件

### `templates/base/_env.tpl`

- access：`read`
- operations：consume `base.env` 的 `SPLIT.SPACE_COMMA`

### `templates/base/_get.tpl`

- access：`read`
- operations：consume `base.get`

### `templates/base/_convert.tpl`

- access：`read`
- operations：consume `base.string.normalize`、`base.isFromYamlError`

### `templates/base/_field.tpl`

- access：`read`
- operations：consume `base.field`

### `templates/base/_types.tpl`

- access：`read`
- operations：consume `base.map`

### `templates/api-resources/Definitions/_Container.tpl`

- access：`read`
- operations：consume 调用契约（单个 `EnvFromSource` 形状 map、允许空结果、由 `definitions.container.array` 逐项委托）

## 验证设计

- 最小有效：`/tmp/` 最小 application Chart 加载真实 `templates/base/` 与本模板，输入单个 `configMapRef` 原生 map，断言输出以 `configMapRef` 为顶层键。
- 较完整有效：`secretRef` 原生 map 透传；引用字符串 `app-config`、`db-secret true` 的位次归一；逗号与空白混用；多余段忽略；`configMapRef` 与 `secretRef` 分别配 `prefix` 时的字段顺序，以及无 `prefix` 与未校验 `prefix` 的输出。
- 关键失败：两个引用字段并存、无引用字段、引用字段为数字、引用字段为 `null` 四种输入中断，消息包含字段名或指明必须提供一个。
- 忽略边界：空引用字符串与子模板返回空两种输入输出为空且不中断。
- fixture 边界：两个 env 来源子模板当前不可用，验证在 `/tmp/` 以同名最小 fixture 回显上下文，只能证明本能力的分发、归一、顺序与委托行为，不代表真实依赖集成通过。
