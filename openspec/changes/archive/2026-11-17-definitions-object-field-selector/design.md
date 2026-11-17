# definitions.objectFieldSelector 设计

## 技术目标

- capability：`definitions.objectFieldSelector`
- artifact-type：Kubernetes 原生 API 同域共享结构模板（`ObjectFieldSelector`）
- target：`templates/api-resources/Definitions/_ObjectFieldSelector.tpl`

## 设计决策

### Decision: 单文件承载并按官方字段顺序渲染

- requirements：`字段渲染顺序与类型`、`fieldPath 必填`、`fieldPath 限制为官方支持的字段路径`
- choice：新建 `templates/api-resources/Definitions/_ObjectFieldSelector.tpl`，只包含 `definitions.objectFieldSelector` 一个 define，按 `apiVersion` → `fieldPath` 顺序处理，各自独立完成取值、归一与渲染闭环。
- rationale：共享结构文件围绕与文件名对应的主模板组织；两个字段无共享中间状态，拆分没有复用收益；官方字段表顺序为 `apiVersion`、`fieldPath`。

### Decision: apiVersion 缺省不输出

- requirements：`字段渲染顺序与类型`
- choice：`apiVersion` 以 `base.get` 取值，经 `base.string.normalize` 解码并 `trim`；为空时不调用 `base.field`，非空时以 `quote` 输出。
- rationale：官方默认值 `v1` 由 API Server 补全，模板不复制该默认值，避免在输出中固化可被 API 演进影响的常量；同时与项目「空值是否输出由调用方决定」的约定一致。

### Decision: fieldPath 自控判空

- requirements：`fieldPath 必填`
- choice：`fieldPath` 以 `base.get` 取值（不启用必填参数），经 `base.string.normalize` 解码并 `trim` 后自行判空；为空时以 `[definitions.objectFieldSelector] fieldPath: required field is missing or empty` 中断。
- rationale：`base.get` 的必填参数失败消息使用 `[base.get]` 前缀，无法满足失败消息统一为 `[模板名] 字段路径: 错误原因`；取值仍由 `base.get` 负责，判空与消息归本层。

### Decision: fieldPath 用新增的 base.env 常量做支持列表校验

- requirements：`fieldPath 限制为官方支持的字段路径`
- choice：在 `templates/base/_env.tpl` 的 `K8S` 下新增 `FIELD_REF` 常量，值为 `^(metadata\.(name|namespace|uid)|metadata\.(labels|annotations)\['[^']+'\]|spec\.(nodeName|serviceAccountName)|status\.(hostIP|podIP|podIPs))$`；模板用 `mustRegexMatch` 消费该常量，未匹配时中断并携带实际取值。
- rationale：项目规则要求固定正则集中定义于 `base.env`，业务模板只能消费常量；表达式按四个字段组分组，`[^']+` 保证括号键非空；使用 `^` 与 `$` 锚定实现完整匹配与大小写敏感。允许列表为 `EnvVarSource.fieldRef` 与 `DownwardAPIVolumeFile.fieldRef` 两处官方路径集的并集，`metadata.uid` 是后者独有的路径。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, 点分路径]`；本能力使用 `apiVersion`、`fieldPath` 两条单层路径，不传强制类型与必填参数。
- output：YAML 字符串；路径缺失时为空输出。
- ownership：取值与别名识别由 `base.get` 负责；必填判空与失败消息由本能力负责。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 的原始输出，不得预先 trim。
- output：解码后的 string；空输入返回空字符串；非 string 标量中断。
- ownership：YAML 标量还原与类型失败由该模板负责；本能力只消费结果并判空。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [键名, 值, "quote"]`。
- output：单字段 YAML 片段，空值不输出。
- ownership：渲染格式与引号由该模板负责；字段生效判断由本能力负责。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`update`
- input：占位空字符串，经 `fromYaml` 恢复常量 Map。
- output：常量 Map；本能力读取 `K8S.FIELD_REF`（新增）。
- ownership：常量定义与结构有效性由该模板负责；本 change 只新增 `K8S.FIELD_REF` 一个键，不改动其他键。

## 代码边界

### `templates/api-resources/Definitions/_ObjectFieldSelector.tpl`

- access：`write`
- operations：add `definitions.objectFieldSelector`
- writable-scopes：整个新建文件

### `templates/base/_env.tpl`

- access：`write`
- operations：add `K8S.FIELD_REF`
- writable-scopes：`K8S` 映射下新增的 `FIELD_REF` 单行键

## 验证设计

- 最小有效：真实 `templates/base/` 与 `_ObjectFieldSelector.tpl` 加载到 `/tmp/` 最小 application Chart，输入 `fieldPath: metadata.name`，断言只输出该字段且为双引号字符串。
- 较完整有效：`apiVersion` 与 `fieldPath` 齐全时按 `apiVersion`、`fieldPath` 顺序输出；`metadata.labels['app']`、`metadata.annotations['note']`、`metadata.uid` 正确输出；含额外键时只输出两个官方字段。
- 关键失败：`fieldPath` 缺失、`fieldPath` 为空白、`fieldPath` 为 `metadata.labels['']`、`fieldPath` 为 `spec.containers[0].name`、`fieldPath` 为 `status.podIPs[0]`、`fieldPath` 为 `metadata.labels`、`fieldPath` 为 `Metadata.Name`、`fieldPath` 为 `metadata.UID`、`fieldPath` 为 `spec.nodename` 均中断，消息含实际取值。
- 忽略边界：`apiVersion` 缺省时只输出 `fieldPath`；额外键不产生输出。
- 正则常量：验证必须加载真实 `templates/base/_env.tpl`，不得用同名 fixture 替代被新增的常量。
