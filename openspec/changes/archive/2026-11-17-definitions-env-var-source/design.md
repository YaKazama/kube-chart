# definitions.envVarSource 设计

## 技术目标

- capability：`definitions.envVarSource`
- artifact-type：Kubernetes 原生 API 同域共享结构模板（`EnvVarSource`）
- target：`templates/api-resources/Definitions/_EnvVarSource.tpl`

## 设计决策

### Decision: 单文件承载并沿用共享结构命名

- requirements：`互斥字段识别与分发`、`原生对象透传`、`紧凑字符串归一`、`非法值类型中断`、`子模板委托边界`
- choice：新建 `templates/api-resources/Definitions/_EnvVarSource.tpl`，只包含 `definitions.envVarSource` 一个 define，不拆分辅助模板，不创建五个选择器子模板。
- rationale：共享结构文件围绕与文件名对应的主模板组织；五个字段的处理链完全同构，单文件即可承载，拆分没有复用收益；未经规格授权的占位 define 不得新增。

### Decision: 用五字段配置表驱动分发

- requirements：`互斥字段识别与分发`、`紧凑字符串归一`
- choice：以一个列表常量声明五个字段，每项含 `key`（`EnvVarSource` 字段名）、`define`（选择器子模板名）、`slots`（字符串位次对应的官方字段名列表）、`required`（必需段数）；遍历该表判断存在性并取唯一项，后续组装与委托都读取同一项。
- rationale：五项差异只在三个数据维度，写成配置表可消除五份重复分支；字段名、子模板名和位次顺序集中在同一处，便于与官方字段表核对。

### Decision: 用 hasKey 与 kindIs 判定存在性和值类型

- requirements：`互斥字段识别与分发`、`非法值类型中断`
- choice：字段存在性用 `hasKey` 判定；值类型用 `kindIs` 区分 map、string 与其他类型，其他类型直接中断。
- rationale：本层是单键访问而非多层路径，`base.get` 会把字段值序列化为 YAML 文本，使「数字、布尔与字符串」在类型上不可区分，无法实现「非 map 且非 string 中断」；直接读取原生值一次即可同时得到存在性与真实类型。

### Decision: 字符串归一使用 base.env 分隔符与位次映射

- requirements：`紧凑字符串归一`
- choice：对字符串先 `trim`，再用 `SPLIT.SPACE_COMMA` 以 `mustRegexSplit` 全量切分，用 `mustWithout` 丢弃空段；段数达到 `required` 后按位次把 `slots` 与段值配对，用 `mustMerge` 汇入新建 map，超出 `slots` 的段自然被忽略。
- rationale：分隔符必须复用 `base.env` 现有常量；空段丢弃与「段数不足不组装」都必须发生在配对之前，否则位次映射会被空段挤偏。

### Decision: 单键选择器结果由 base.field 以 base.map 输出

- requirements：`原生对象透传`、`紧凑字符串归一`、`子模板委托边界`
- choice：组装结果非空时调用对应选择器子模板，返回值经 `fromYaml` 与 `base.isFromYamlError` 保护；恢复结果非空时用 `base.field (list <字段名> <恢复值> "base.map")` 输出，空结果不输出字段。
- rationale：项目统一使用 `base.field` 渲染字段；`base.map` 负责最终类型门禁；空结果不输出与空 map 视为未设置的既有约定一致，且调用方 `definitions.envVar` 已按「空结果不输出 valueFrom」处理。

### Decision: 表驱动的存在性检查与唯一项处理分离

- requirements：`互斥字段识别与分发`
- choice：先遍历配置表收集实际出现的字段到列表，数量大于 1 时中断并列出实际字段名；随后只在存在唯一项时进入组装与委托。
- rationale：互斥校验必须在任何组装之前完成，否则多字段输入会产出部分结果；先收集再处理也让「无字段」自然落到空输出。

## 依赖契约

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：占位空字符串，经 `fromYaml` 恢复常量 Map。
- output：常量 Map；本能力只读取 `SPLIT.SPACE_COMMA`。
- ownership：常量定义与结构有效性由该模板负责；本能力不得内联、拼接或改写该表达式。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [字段名, 已恢复的 map, "base.map"]`。
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

### Dependency: `definitions.configMapKeySelector`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`ConfigMapKeySelector` map，字段为 `name`、`key`、`optional`。
- output：可由 `fromYaml` 解析的 `ConfigMapKeySelector` 字段片段；空结果表示不渲染该字段；失败消息使用其自身前缀。
- ownership：本能力只负责分发、类型区分与字符串位次组装；字段校验与缺省处理由该子模板负责，本 change 不实现。

### Dependency: `definitions.objectFieldSelector`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`ObjectFieldSelector` map，字段为 `fieldPath`、`apiVersion`。
- output：可由 `fromYaml` 解析的 `ObjectFieldSelector` 字段片段；空结果表示不渲染该字段；失败消息使用其自身前缀。
- ownership：同上，本 change 不实现。

### Dependency: `definitions.fileKeySelector`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`FileKeySelector` map，字段为 `volumeName`、`path`、`key`、`optional`。
- output：可由 `fromYaml` 解析的 `FileKeySelector` 字段片段；空结果表示不渲染该字段；失败消息使用其自身前缀。
- ownership：同上，本 change 不实现。

### Dependency: `definitions.resourceFieldSelector`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`ResourceFieldSelector` map，字段为 `resource`、`containerName`、`divisor`。
- output：可由 `fromYaml` 解析的 `ResourceFieldSelector` 字段片段；空结果表示不渲染该字段；失败消息使用其自身前缀。
- ownership：同上，本 change 不实现。

### Dependency: `definitions.secretKeySelector`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`SecretKeySelector` map，字段为 `name`、`key`、`optional`。
- output：可由 `fromYaml` 解析的 `SecretKeySelector` 字段片段；空结果表示不渲染该字段；失败消息使用其自身前缀。
- ownership：同上，本 change 不实现。

## 代码边界

### `templates/api-resources/Definitions/_EnvVarSource.tpl`

- access：`write`
- operations：add `definitions.envVarSource`
- writable-scopes：整个新建文件

### `templates/api-resources/Definitions/_EnvVar.tpl`

- access：`read`
- operations：consume 调用契约（`EnvVarSource` 上下文形状与「空结果不输出 valueFrom」的返回边界）

## 验证设计

- 最小有效：真实 `templates/base/` 与 `_EnvVarSource.tpl` 加载到 `/tmp/` 最小 application Chart，输入单个 `configMapKeyRef` 原生 map，断言输出以 `configMapKeyRef` 为顶层键。
- 较完整有效：五个字段分别覆盖原生 map 透传与字符串位次组装，含单段、可选段原样传递、逗号与空白混用、多余段忽略。
- 关键失败：多字段并存、字段值为数字、字段值为 `null` 三种输入中断，消息包含字段名。
- 忽略边界：无字段、字符串段数不足、选择器子模板返回空三种情况输出为空且不中断。
- 联调回归：加载真实 `_EnvVar.tpl` 与本能力，`valueFrom` 分别取字符串与原生 map，端到端输出以 `valueFrom` 为顶层键。
- fixture 边界：五个选择器子模板当前不可用，验证在 `/tmp/` 以同名最小 fixture 代替，只能证明本能力的类型区分、位次组装与委托行为，不代表真实依赖集成通过。
