# definitions.secretKeySelector 设计

## 技术目标

- capability：`definitions.secretKeySelector`
- artifact-type：Kubernetes 原生 API 同域共享结构模板（`SecretKeySelector`）
- target：`templates/api-resources/Definitions/_SecretKeySelector.tpl`

同时统一 Secret 与 ConfigMap 的 data key 字符集校验，统一 `secretKeyRef`、`configMapKeyRef`、`fileKeyRef` 三个选择器的 `optional` 取值规则，并把 `definitions.envVarSource` 的 `secretKeyRef` 必需段数修正为 2。

## 设计决策

### Decision: 单文件承载并按官方字段顺序输出

- requirements：`字段渲染顺序与类型`
- choice：新建 `templates/api-resources/Definitions/_SecretKeySelector.tpl`，只包含 `definitions.secretKeySelector` 一个 define，按 `key` → `name` → `optional` 的官方顺序输出。
- rationale：共享结构文件围绕与文件名对应的主模板组织；三个字段各自独立，无需拆分辅助模板。

### Decision: name 与 key 各自独立取值并各自收口校验

- requirements：`name 必填与 DNS subdomain 校验`、`key 必填与字符集校验`
- choice：`name` 以 `base.get` 取值、`base.string.normalize` 解码并 `trim`，自判空后委托 `base.rfc` 的 `1123sub` 模式校验；`key` 同链路取值并自判空，再用新增的 `K8S.DATA_KEY` 校验字符集。两者均以 `quote` 输出。
- rationale：两个字段的错误消息需要各自的字段路径，且校验规则不同（长度上限与字符集），合并会引入条件分支而不减少重复；`base.rfc` 已提供 Subdomain 正则与 253 上限，无需在业务模板内联。

### Decision: data key 字符集正则集中在 base.env 并由两个选择器共用

- requirements：`key 必填与字符集校验`、`configMapKeySelector 的 key 字符集校验`
- choice：在 `base.env` 的 `K8S` 下新增 `DATA_KEY`（`^[-._a-zA-Z0-9]+$`），`definitions.secretKeySelector` 与 `definitions.configMapKeySelector` 分别读取同一键执行校验。
- rationale：官方对 `Secret.data` 与 `ConfigMap.data` 的键约束是同一句话，共用常量可保证两个选择器行为一致；该键不归入 `K8S.SELECTOR`，因为 label 与 field selector 的键语法与本规则无关。

### Decision: configMapKeySelector 的 key 校验就地补强

- requirements：`configMapKeySelector 的 key 字符集校验`
- choice：在 `_ConfigMapKeySelector.tpl` 现有的 `key` 判空与输出之间插入一次 `K8S.DATA_KEY` 校验，失败消息沿用该模板前缀；其余字段处理不变。
- rationale：该能力已有独立文件与既有调用方，补强只需一处判断；新建跨文件辅助模板会违反同域共享结构「辅助模板不跨文件复用」的约定，而重复的只是常量引用而非正则本身。

### Decision: envVarSource 的 secretKeyRef 必需段数改为 2

- requirements：`envVarSource 的 secretKeyRef 字符串简写必需段数`
- choice：把 `templates/api-resources/Definitions/_EnvVarSource.tpl` 中 `secretKeyRef` 配置项的 `required` 由 `1` 改为 `2`，`slots` 保持 `name`、`key`、`optional`。
- rationale：`key` 已是必填，字符串简写只有 1 段时无法组成合法选择器；改为 2 段后与 `configMapKeyRef` 的必需段数语义一致，且遵循既有约定——段数不足时不组装字段而不是中断渲染。第三段在 `optional` 能接受字符串布尔后正常生效，不再中断。

### Decision: optional 剥离 YAML 引号后交给 base.bool

- requirements：`optional 接受布尔值与字符串 true/false`、`configMapKeySelector 的 optional 取值`、`fileKeySelector 的 optional 取值`
- choice：以 `base.get` 取值并 `trim`，非空时先用 `SYS.YAML_QUOTED` 剥离外层引号，再交给 `base.field` 的 `base.bool` 输出；`definitions.secretKeySelector`、`definitions.configMapKeySelector` 与 `definitions.fileKeySelector` 采用同一写法。
- rationale：`base.get` 对标量返回的 YAML 文本会为字符串保留外层引号，`base.bool` 只认识裸 `true`／`false`，这层引号必须由调用方担掉，否则字符串简写组装出的 `optional` 永远无法通过。剥离后原生布尔与字符串 `true`／`false` 均落入 `base.bool` 的合法分支，数字与 map 等其他形态仍被拒；该写法与 `definitions.resourceFieldSelector` 处理 `divisor` 的方式一致。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, 点分路径]`；本能力使用 `key`、`name`、`optional` 三条单层路径，不传强制类型与必填参数。
- output：可 `fromYaml` 解析的 YAML 字符串；路径缺失时为空输出。
- ownership：取值与别名识别由 `base.get` 负责；必填判空与失败消息由本能力负责。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 的原始输出，不得预先 trim。
- output：解码后的 string；空输入返回空字符串；非 string 标量中断。
- ownership：YAML 标量还原与类型失败由该模板负责；本能力只消费结果并判空。

### Dependency: `base.rfc`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：`list [name, "1123sub"]`。
- output：校验通过返回原值；非法时中断，失败消息使用 `[base.rfc]` 前缀；长度上限 253。
- ownership：DNS Subdomain 正则与长度校验由该模板负责；本能力只传递已归一化的 `name`。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [键名, 值, 渲染模板]`；`key` 与 `name` 使用 `quote`，`optional` 使用 `base.bool`。
- output：单字段 YAML 片段，空值不输出。
- ownership：渲染格式与引号由该模板负责；字段生效判断由本能力负责。

### Dependency: `base.bool`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：已剥离 YAML 外层引号的 `true` 或 `false` 文本。
- output：布尔标量文本；其他取值中断。
- ownership：布尔取值门禁由该模板负责；引号剥离与字段生效判断由本能力负责。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`update`
- input：占位空字符串，经 `fromYaml` 恢复常量 Map。
- output：常量 Map；本 change 新增 `K8S.DATA_KEY`。`definitions.secretKeySelector`、`definitions.configMapKeySelector` 与 `definitions.fileKeySelector` 均读取该键与既有的 `SYS.YAML_QUOTED`，后者用于剥离 data key 与 `optional` 的外层引号。
- ownership：常量定义与结构有效性由该模板负责；本 change 只新增一个键，不改动其他键。

## 代码边界

### `templates/base/_env.tpl`

- access：`write`
- operations：add `K8S.DATA_KEY`
- writable-scopes：`K8S` 映射下新增的一行键

### `templates/api-resources/Definitions/_SecretKeySelector.tpl`

- access：`write`
- operations：add `definitions.secretKeySelector`
- writable-scopes：整个新建文件

### `templates/api-resources/Definitions/_ConfigMapKeySelector.tpl`

- access：`write`
- operations：update `key` 的校验分支，追加 `K8S.DATA_KEY` 字符集判断；update `optional` 的取值分支，改为剥离 YAML 引号后交给 `base.bool`
- writable-scopes：`definitions.configMapKeySelector` 中 `key` 与 `optional` 字段的处理闭环

### `templates/api-resources/Definitions/_EnvVarSource.tpl`

- access：`write`
- operations：update `$sources` 中 `secretKeyRef` 配置项的 `required`
- writable-scopes：`definitions.envVarSource` 内 `$sources` 的 `secretKeyRef` 条目

### `templates/api-resources/Definitions/_FileKeySelector.tpl`

- access：`write`
- operations：update `optional` 的取值分支，改为剥离 YAML 引号后交给 `base.bool`
- writable-scopes：`definitions.fileKeySelector` 中 `optional` 字段的处理闭环

## 验证设计

- 最小有效：真实 `templates/base/` 与 `_SecretKeySelector.tpl` 加载到 `/tmp/` 最小 application Chart，输入 `key: password`、`name: db-creds`，断言按 `key`、`name` 顺序输出且均为双引号字符串，不含 `optional`。
- 较完整有效：`optional` 为原生 `true`／`false` 与字符串 `"true"`／`"false"` 时均输出布尔标量；`name` 的 `1secret`、`app.config`、63 字符单段、253 字符多段通过；`key` 的 `LOG_LEVEL`、`app.key`、字符串 `"1"`、`.key`、`key.`、`_key`、`-key` 通过；含额外键时只输出三个官方字段。
- 关键失败：`key` 缺失、`key` 为空白、`key` 为原生数字与布尔、`key` 为 `k ey`、`k/ey`、`k:ey`；`name` 缺失、`name` 为空白、`name` 为 `My-Secret`、`secret_name`、`.secret`、64 字符单段、254 字符多段；`optional` 为 `1`、`"yes"` 与 map，均中断；`key` 与 `name` 的失败消息含对应字段名或实际取值，`name` 的失败消息由 `base.rfc` 给出，`optional` 的失败消息由 `base.bool` 给出。
- 既有能力回归：`definitions.configMapKeySelector` 对 `key: LOG_LEVEL` 仍通过、对 `key: k/ey` 中断；同一 `key` 在两个选择器下结果一致。
- 父级回归：`definitions.envVarSource` 的 `secretKeyRef` 为 `db-creds` 时不输出内容且不中断，为 `db-creds password` 时输出 `name` 与 `key`，为 `db-creds password true` 与 `db-creds password true extra` 时输出 `optional: true` 且忽略多余段，为 `db-creds password maybe` 时中断。
- 同构回归：`definitions.configMapKeySelector` 与 `definitions.fileKeySelector` 的 `optional` 接受相同的字符串布尔取值，且对 `1` 与 `"yes"` 给出相同的失败边界。
- 隔离要求：各被测模板的渲染必须在各自独立的 `/tmp/` 最小 Chart 中分别执行；同一 Chart 内 `--show-only` 不做执行隔离，其他探针会用同一输入提前中断。
- 正则常量：验证必须加载真实 `templates/base/_env.tpl`，不得用同名 fixture 替代被新增的 `K8S.DATA_KEY`。
