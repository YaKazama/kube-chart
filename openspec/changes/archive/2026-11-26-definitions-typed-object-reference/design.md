# definitions.typedObjectReference 设计

## 技术目标

- capability：`definitions.typedObjectReference`
- artifact-type：Helm 共享结构命名模板（library Chart）
- target：`templates/api-resources/Definitions/_TypedObjectReference.tpl`

## 设计决策

### Decision: 原生 map 固定顺序渲染

- requirements：`TypedObjectReference 字段渲染`
- choice：以原生 map 为上下文，按 `apiGroup` → `kind` → `name` → `namespace` 的固定顺序逐字段闭环处理，不遍历输入 map 的键。
- rationale：规格要求官方字段顺序且不得按输入键顺序输出；通用规则要求直接渲染 API 字段时按 API 字段顺序实现。

### Decision: 可选字段省略与差异化校验

- requirements：`TypedObjectReference 字段渲染`
- choice：`apiGroup` 缺失、空字符串、仅空白或 `null` 时不输出，非空时原样输出且不校验；`namespace` 同样在空值时不输出，非空时委托 `base.rfc` 的 `1123` 模式校验。
- rationale：draft 已确认 `apiGroup` 不做严格校验，`namespace` 需要校验 Kubernetes namespace 名称格式。

### Decision: 必填失败归属本模板

- requirements：`TypedObjectReference 字段渲染`
- choice：`kind` 与 `name` 经取值、解码、trim 后判空，由本模板以 `[definitions.typedObjectReference]` 前缀中断，不使用 `base.get` 的必填标志。
- rationale：draft 确认必填字段的失败消息由本 change 维护；工程规则要求失败消息统一为 `[模板名] 字段路径: 错误原因`。

### Decision: 字符串标量稳定输出

- requirements：`TypedObjectReference 字段渲染`
- choice：非空字段统一使用 `base.field` 的 `quote` 模式输出，确保 YAML 解析后仍为字符串。
- rationale：规格要求值保持输入内容且解析后仍为字符串，避免 `on`、`yes` 或数字形态被 YAML 重新解释。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文 map, 点分路径 string]`，使用默认别名识别与非必填行为。
- output：可取值的 YAML 字符串；路径全部缺失时为空输出。
- ownership：`base.get` 负责数据源优先级、同级别名识别与序列化；本模板负责字段存在性、判空与失败消息。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 返回的 YAML 标量文本。
- output：解码后的 string；空输入与 `null` 返回空字符串；非 string 类型中断并保留其自身前缀。
- ownership：`base.string.normalize` 负责 YAML 标量解码与类型门禁；本模板负责 trim 后的必填判空。

### Dependency: `base.rfc`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：`list [namespace string, "1123"]`，仅在 `namespace` 解码后非空时调用。
- output：校验通过的 namespace 字符串；不符合 RFC1123 Label 或超过 63 个字符时中断并保留其自身前缀。
- ownership：`base.rfc` 负责 RFC1123 Label 正则与长度校验；本模板负责空值省略与字段输出。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [key string, value string, "quote"]`。
- output：YAML 键值对；value 为空时为空输出。
- ownership：`base.field` 负责键值对渲染与引号处理；本模板负责只在字段生效时调用。

## 代码边界

### `templates/api-resources/Definitions/_TypedObjectReference.tpl`

- access：`write`
- operations：`add definitions.typedObjectReference`
- writable-scopes：新增文件的整体契约注释与 `define` 块。

### `templates/api-resources/Core/_PersistentVolumeClaimSpec.tpl`

- access：`read`
- operations：`consume dataSourceRef 对 definitions.typedObjectReference 的既有委托调用契约`

## 验证设计

- 最小有效输入：仅传入 `kind` 与 `name`，输出只含这两个字段且顺序为 `kind`、`name`。
- 较完整有效输入：传入第三方 `apiGroup`、`kind`、`name` 与合法 `namespace`，输出四字段顺序与输入值均保持。
- 可选字段省略：缺少 `apiGroup` 与 `namespace` 时两个字段均不输出。
- 关键失败场景：空 map、`name` 仅空白、非法或超长 `namespace`、`apiGroup` 为整数类型，均中断渲染；必填失败消息以 `[definitions.typedObjectReference]` 开头。
- 依赖边界：`/tmp/sd-kube-chart/` 最小 Chart 加载真实 `base.get`、`base.string.normalize`、`base.rfc` 与 `base.field`，不提供同名 fixture。
