# definitions.envVar 设计

## 技术目标

- capability：`definitions.envVar`
- artifact-type：Kubernetes 原生 API 同域共享结构模板（`EnvVar`）
- target：`templates/api-resources/Definitions/_EnvVar.tpl`

## 设计决策

### Decision: 单文件承载并沿用共享结构命名

- requirements：`EnvVar 基础字段渲染`、`valueFrom 紧凑字符串的第一层解析`、`valueFrom 原生 map 透传`、`无法构成委托上下文时忽略 valueFrom`、`子模板委托边界`
- choice：新建 `templates/api-resources/Definitions/_EnvVar.tpl`，只包含 `definitions.envVar` 一个 define，不拆分辅助模板，不创建 `definitions.envVarSource`。
- rationale：共享结构文件围绕与文件名对应的主模板组织；当前能力只有一个入口和一条处理链，拆分没有复用收益；未经规格授权的占位 define 不得新增。

### Decision: 按 EnvVar API 字段顺序取值并统一由 base.field 输出

- requirements：`EnvVar 基础字段渲染`
- choice：按 `name` → `value` → `valueFrom` 处理；`name` 与 `value` 用 `quote` 渲染，`valueFrom` 用 `base.map` 渲染。
- rationale：项目统一使用 `base.field` 渲染字段；`value` 标识为 `quote` 才能让字符串与非 string 标量统一输出为字符串，符合 EnvVar 的 string 类型。

### Decision: 用 base.get 原始输出是否为空判定字段未提供

- requirements：`EnvVar 基础字段渲染`
- choice：`value`、`valueFrom` 均先取 `base.get` 原始输出并 `trim`；为空即视为未提供。两者都非空时以 `[definitions.envVar] valueFrom: mutually exclusive with 'value'` 中断。
- rationale：`base.get` 对标量空值统一按未命中处理，直接以其空输出作为“未提供”的唯一边界，可避免重复判空与两套空值语义。

### Decision: name 走 base.get 必填与 base.string.normalize

- requirements：`EnvVar 基础字段渲染`
- choice：`name` 使用 `base.get` 的必填参数取值后再经 `base.string.normalize` 归一化；空 `name` 由必填校验中断。
- rationale：`base.get` 负责取值与必填，`base.string.normalize` 负责 YAML 标量还原，两者已覆盖缺失、空值和类型失败边界，本层不重复校验。

### Decision: value 强制转换为字符串后统一带引号输出

- requirements：`EnvVar 基础字段渲染`
- choice：`value` 的 `base.get` 调用传入强制类型 `toString`，使数字与布尔标量在取值阶段已转为字符串；结果再经 `base.string.normalize` 解码，最后以 `quote` 渲染。
- rationale：`base.get` 的 `toString` 只作用于标量、不改变 map 和 list，可用一个参数消除数字与布尔的类型分支；归一后再 `quote` 才能让 `123`、`true` 等文本在输出 YAML 中仍为字符串。

### Decision: value 拒绝对象与数组

- requirements：`EnvVar 基础字段渲染`
- choice：`value` 原始输出分别经 `fromYaml` 与 `fromYamlArray` 解析，并用 `base.isFromYamlError`、`base.isFromYamlArrayError` 判定；任一解析成功即以 `[definitions.envVar] value: must be scalar` 中断，失败消息携带值类型。
- rationale：`EnvVar.value` 是 string，对象与数组无法构成合法值；`base.get` 的 `toString` 不对集合生效，因此必须在渲染前显式排除这两类输入，不得静默转为无效字符串。

### Decision: valueFrom 先做 YAML 恢复再按错误分支判定来源类型

- requirements：`valueFrom 紧凑字符串的第一层解析`、`valueFrom 原生 map 透传`
- choice：对 `base.get` 原始输出执行 `fromYaml`，用 `base.isFromYamlError` 判定；报错即进入字符串分支，未报错即按 map 透传，不再追加类型判断。
- rationale：`fromYaml` 成功已保证结果是 map，重复 `kindIs` 属于冗余类型检查；错误判定是区分 string 与 map 的唯一必需分支。

### Decision: 字符串分支复用 base.env 常量切分两段并映射关键字

- requirements：`valueFrom 紧凑字符串的第一层解析`、`无法构成委托上下文时忽略 valueFrom`
- choice：先用 `SYS.YAML_QUOTED` 剥离外层引号并 `trim`，再用 `SPLIT.SPACE_COMMA` 以 `mustRegexSplit` 限制为 2 段；少于 2 段即跳过。第 1 段经 `lower` 在关键字字典中查找字段名，未命中即跳过；第 2 段 `trim` 后作为值。
- rationale：分隔符必须复用 `base.env` 现有常量；关键字大小写不敏感用 `lower` 加字典即可，不必新增固定正则；只有两段结构，因此限制切分次数一次完成，符合“不解析第二层”的边界。

### Decision: 两种来源归一为同一委托上下文并共用渲染闭环

- requirements：`valueFrom 原生 map 透传`、`子模板委托边界`
- choice：map 来源直接作为委托上下文，字符串来源构造 `dict <字段> <第 2 段原文>`；两者都交给 `definitions.envVarSource`，结果经 `fromYaml` 与 `base.isFromYamlError` 保护后，非空才用 `base.field` 输出。
- rationale：两个来源的差异只在上下文构造，委托、错误保护与空结果跳过完全同构，收敛为一处可消除重复分支。

### Decision: 修正 Container 中错误的委托名

- requirements：`子模板委托边界`
- choice：把 `templates/api-resources/Definitions/_Container.tpl` 中三处 `definitions.enVar` 标识符改为 `definitions.envVar`，字段说明文本同步更新。
- rationale：当前调用名与本能力名不一致，改名后 `env` 才能解析到本能力的 define；改动仅限标识符文本，不涉及该文件的其他逻辑。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, 点分路径, 强制类型, 合并模式, 必填]`；本能力使用 `name`（必填）、`value`、`valueFrom` 三条路径，不传强制类型。
- output：YAML 字符串；路径缺失时为空输出，必填路径缺失时中断。
- ownership：取值、别名、必填校验由 `base.get` 负责；字段生效判断与后续归一化由本能力负责。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 的原始文本，不得预先 trim。
- output：解码后的 string；空输入返回空字符串；非 string 标量中断。
- ownership：YAML 标量还原与类型失败由该模板负责；本能力只消费结果并判断空值。`value` 的 `base.get` 已先以 `toString` 强制类型，因此到达本模板时必为标量字符串。

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 的返回值。
- output：布尔字符串。
- ownership：错误形态识别由该模板负责，本能力只据此判定 `value` 是否为数组。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 的返回值。
- output：布尔字符串。
- ownership：错误形态识别由该模板负责，本能力只据此选择来源类型分支。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [键名, 值, 渲染模板]`；`name`、`value` 使用 `quote`，`valueFrom` 使用 `base.map`。
- output：单字段 YAML 片段，空值不输出。
- ownership：渲染格式与引号由该模板负责；字段生效判断由本能力负责。

### Dependency: `base.map`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：已恢复的 map。
- output：换行缩进的 YAML 映射；非 map 输入中断。
- ownership：作为 `base.field` 的渲染模板执行最终类型门禁。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：占位空字符串，经 `fromYaml` 恢复常量 Map。
- output：常量 Map；本能力只读取 `SPLIT.SPACE_COMMA` 与 `SYS.YAML_QUOTED`。
- ownership：常量定义与结构有效性由该模板负责；本能力不得内联、拼接或改写这两个表达式。

### Dependency: `definitions.envVarSource`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：单键 `EnvVarSource` map；原生 map 来源保持原结构，字符串来源的值为第 2 段原串。
- output：可由 `fromYaml` 解析的 `EnvVarSource` 映射；空结果表示不渲染 `valueFrom`；失败消息使用其自身前缀。
- ownership：本能力只负责关键字映射、上下文构造与委托；字段拆分、校验、缺省与失败由 `definitions.envVarSource` 负责，本 change 不实现。

## 代码边界

### `templates/api-resources/Definitions/_EnvVar.tpl`

- access：`write`
- operations：add `definitions.envVar`
- writable-scopes：整个新建文件

### `templates/api-resources/Definitions/_Container.tpl`

- access：`write`
- operations：rename `definitions.enVar` → `definitions.envVar`（字段说明、字段注释与 `definitions.container.array` 调用共三处）
- writable-scopes：上述三处标识符文本

## 验证设计

- 最小有效：真实 `templates/base/` 与 `_EnvVar.tpl` 加载到 `/tmp/` 最小 application Chart，输入 `name` + `value`，断言只输出 `name` 与带引号的 `value`。
- 较完整有效：字符串来源覆盖全部五个关键字、大小写混写与逗号/空白分隔；map 来源覆盖原样透传与子模板空结果；`value` 覆盖字符串、整数、浮点数与布尔四种标量。
- 关键失败：`name` 缺失、`name` 为空、`value` 为对象或数组、`value` 与 `valueFrom` 并存。
- 忽略边界：只有 `name`、空 `value`、只有关键字、关键字不在映射内、空 `valueFrom` 均只输出 `name` 且不中断。
- fixture 边界：`definitions.envVarSource` 当前不可用，验证在 `/tmp/` 以同名最小 fixture 代替，只能证明本能力的上下文构造与委托行为，不代表真实依赖集成通过。
- Container 回归：加载 `_Container.tpl` 与真实 base 模板，以 `env` 的 `value` 形态渲染，确认 `env` 输出正常且委托名已指向 `definitions.envVar`。
