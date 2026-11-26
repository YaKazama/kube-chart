# core.persistentVolumeClaimSpec 设计

## 技术目标

- capability：`core.persistentVolumeClaimSpec`
- artifact-type：Helm 命名模板
- target：`templates/api-resources/Core/_PersistentVolumeClaimSpec.tpl` 中的 `core.persistentVolumeClaimSpec`

## 设计决策

### Decision: 原生 map 与官方字段顺序

- requirements：`PersistentVolumeClaimSpec 字段渲染`
- choice：上下文即 `PersistentVolumeClaimSpec` map，按官方字段表顺序逐字段完成取值、归一化与渲染。
- rationale：draft 明确上下文为原生 map，字段类型与渲染顺序以官方定义为准。

### Decision: accessModes 逐项枚举校验

- requirements：`accessModes 校验`
- choice：恢复为数组后逐项去除首尾空白，校验 string 类型与四个官方枚举值，按输入顺序保留重复项，空数组省略。
- rationale：官方类型为 string array，draft 明确不接受 string 简写。

### Decision: 标量与 volumeMode 处理

- requirements：`PersistentVolumeClaimSpec 字段渲染`、`volumeMode 枚举`、`输入边界`
- choice：标量字符串经 YAML 标量规范化并去除首尾空白；`volumeMode` 使用允许值列表渲染，非法值失败。
- rationale：官方类型为 string，`volumeMode` 具有官方枚举。

### Decision: 子结构委托

- requirements：`子结构委托`
- choice：非空 map 原样作为子模板上下文；子模板输出经 YAML 恢复与错误检查，非空时以 map 渲染，空内容省略。
- rationale：draft 固定四个子模板映射；三个子模板当前不可用且只占位。

### Decision: 空输入输出

- requirements：`PersistentVolumeClaimSpec 字段渲染`
- choice：所有字段无有效内容时输出空内容。
- rationale：draft 已确认该行为。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <上下文 map> <点分路径 string>`；可选参数使用默认值。
- output：YAML 字符串；路径缺失或为空时返回空字符串。
- ownership：`base.get` 负责取值、同级别名识别与序列化；本模板负责字段路径、类型分支与值校验。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list <key string> <value any> <渲染模板 string> <允许值 list>`
- output：YAML 键值对；渲染结果为空时不输出。
- ownership：`base.field` 负责最终键名、枚举与类型渲染；本模板负责字段生效判断。

### Dependency: `base.slice`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：`slice`
- output：YAML 字符串；非 slice 输入时中断。
- ownership：`base.slice` 只负责 slice 类型门禁与序列化；元素语义由本模板校验。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：YAML 标量文本。
- output：解码后的 string；空内容返回空字符串；非 string 标量时中断。
- ownership：`base.string.normalize` 负责 YAML 标量解码；本模板负责 trim、空值判断与字段输出。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 返回值。
- output：布尔字符串。
- ownership：只识别解析错误形态；解析错误的处理由本模板负责。

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 返回值。
- output：布尔字符串。
- ownership：只识别解析错误形态；解析错误的处理由本模板负责。

### Dependency: `definitions.labelSelector`

- availability：`existing`
- source：`templates/api-resources/Definitions/_LabelSelector.tpl`
- operation：`consume`
- input：`LabelSelector` map。
- output：非空 LabelSelector YAML map；`matchLabels` 缺失或非法时中断。
- ownership：子模板负责 `matchLabels`、`matchExpressions` 及其枚举校验；本模板只负责 `selector` 的取值、空值判断与委托。

### Dependency: `definitions.typedLocalObjectReference`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`TypedLocalObjectReference` map。
- output：YAML map；非法 YAML 中断。
- ownership：子模板负责其内部字段，本 change 不创建该模板；本模板只负责 `dataSource` 的取值、空值判断与委托。

### Dependency: `definitions.typedObjectReference`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`TypedObjectReference` map。
- output：YAML map；非法 YAML 中断。
- ownership：子模板负责其内部字段，本 change 不创建该模板；本模板只负责 `dataSourceRef` 的取值、空值判断与委托。

### Dependency: `definitions.volumeResourceRequirements`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`VolumeResourceRequirements` map。
- output：YAML map；非法 YAML 中断。
- ownership：子模板负责其内部字段，本 change 不创建该模板；本模板只负责 `resources` 的取值、空值判断与委托。

## 代码边界

### `templates/api-resources/Core/_PersistentVolumeClaimSpec.tpl`

- access：`write`
- operations：`add` 命名模板 `core.persistentVolumeClaimSpec`。
- writable-scopes：新增文件中的 `core.persistentVolumeClaimSpec` 定义及其中间辅助逻辑。

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume` `base.get`。

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume` `base.field`。

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume` `base.slice`。

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume` `base.string.normalize`、`base.isFromYamlError`、`base.isFromYamlArrayError`。

### `templates/api-resources/Definitions/_LabelSelector.tpl`

- access：`read`
- operations：`consume` `definitions.labelSelector`。

## 验证设计

- 最小有效：仅提供 `accessModes` 时输出单个 `accessModes` 字段；空 map 输出空内容。
- 较完整有效：提供全部九个字段，断言官方字段顺序；三个不可用子模板使用同名最小 fixture，`selector` 使用真实 `definitions.labelSelector` 且 `matchLabels` 非空。
- 关键失败：字符串形式的 `accessModes`、非字符串元素、非法访问模式、非法 `volumeMode`、非字符串标量以及 fixture 返回非法 YAML 均中断渲染。
- 依赖边界：三个 unavailable 子模板的 fixture 只证明本模板的调用与分支行为，不证明真实子模板集成。
