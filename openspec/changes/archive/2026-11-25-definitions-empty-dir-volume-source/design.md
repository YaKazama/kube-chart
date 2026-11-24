# definitions.emptyDirVolumeSource 设计

## 技术目标

- capability：`definitions.emptyDirVolumeSource`
- artifact-type：Helm 命名模板（library Chart）
- target：`templates/api-resources/Definitions/_EmptyDirVolumeSource.tpl`

## 设计决策

### Decision: 复用既有取值能力

- requirements：`上下文兼容`、`空内容与未知键`
- choice：`medium` 与 `sizeLimit` 均通过 `base.get` 取值，并关闭 `<字段>Alias` 识别；未声明的键自然忽略；空 map 得到空取值，不渲染字段。
- rationale：draft 已确认定义外键忽略、空 map 不渲染字段；`base.get` 是既有的跨数据源取值能力；`mediumAlias`、`sizeLimitAlias` 不属于 `EmptyDirVolumeSource` 定义字段，因此不启用别名。

### Decision: medium 严格枚举

- requirements：`medium 取值与校验`
- choice：`medium` 经 `base.string.normalize` 仅做 YAML 标量解码并 trim；非空时交给 `base.field` 的允许值列表 `["Memory"]` 做大小写敏感比较并以 `base.string` 输出；空值跳过。
- rationale：draft 要求仅接受 `""` 与 `Memory`、枚举大小写敏感、空值不渲染；`base.string.normalize` 只还原标量文本，不改变域值；`base.field` 的允许值比较为字符串精确匹配。

### Decision: sizeLimit 按 Quantity 校验

- requirements：`sizeLimit 取值与校验`
- choice：沿用 `definitions.resourceFieldSelector` 中 `divisor` 的处理方式：剥离 YAML 引号并 trim，空值跳过，非空交给 `base.quantity` 校验并经 `base.field` 输出。
- rationale：draft 指定参考 `divisor`；`base.quantity` 接受 int 或 string 并按 Kubernetes Quantity 规范校验。

### Decision: 模板名与父模板分发对齐

- requirements：`上下文兼容`
- choice：定义名固定为 `definitions.emptyDirVolumeSource`，由既有 `definitions.volume` 按 `definitions.<field>VolumeSource` 分发直接调用；本 change 不修改父模板。
- rationale：`definitions.volume` 已按该命名约定分发，并对 `emptyDir` 的 string 形态完成上下文清洗。

### Decision: 固定字段顺序与空输出边界

- requirements：`字段顺序与输出边界`
- choice：先渲染 `medium` 再渲染 `sizeLimit`；模板只返回可作为 `emptyDir` 值解析的合法 YAML 字段片段，无有效内容时输出空内容，不补 `{}` 或父键。
- rationale：draft 要求按 K8s API 字段顺序；`definitions.volume` 已负责把空子模板结果组装为 `emptyDir: {}`。

## 依赖契约

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：空字符串。
- output：可被 `fromYaml` 解析的常量 map；非法常量归该模板负责。
- ownership：提供 `SYS.YAML_QUOTED` 等常量；本模板只读取。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, 键路径, 类型, 合并模式, 必填, 别名]`；本模板将别名参数固定为 `false`。
- output：YAML 序列化文本；缺失值返回空内容。
- ownership：负责上下文优先级与类型序列化；本模板负责字段语义和别名关闭。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：YAML 标量文本。
- output：解码后的 string；空输入返回空字符串；非 string 或非法标量中断。
- ownership：负责 YAML 标量解码；本模板负责枚举校验。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [键名, 值, 渲染模板, 允许值列表]`。
- output：YAML 键值片段；空值不输出；枚举不匹配或渲染失败时中断。
- ownership：负责单字段渲染与枚举比较；本模板负责取值和字段顺序。

### Dependency: `base.quantity`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：string 形式的 Quantity（由 `base.get` 序列化并经 YAML 引号剥离得到）。
- output：校验通过的原始值；不符合 Quantity 规范时中断。
- ownership：负责 Quantity 格式校验；本模板负责空值跳过与字段渲染。

## 代码边界

### `templates/api-resources/Definitions/_EmptyDirVolumeSource.tpl`

- access：`write`
- operations：`add` `definitions.emptyDirVolumeSource`
- writable-scopes：整个新增文件；仅包含 `definitions.emptyDirVolumeSource` 定义及其文档注释。

## 验证设计

- 真实依赖：Helm 4 渲染 library Chart，经 `definitions.volume` 分发到新模板。
- Fixture：`/tmp/sd-kube-chart/` 下新建最小 application Chart，依赖当前 Chart 并通过 `definitions.volume` 渲染 PodSpec 卷。
- 最小有效：`{name: "data", emptyDir: {}}` 输出 `emptyDir: {}`。
- 较完整有效：原生 map 的 `{medium: "Memory", sizeLimit: "1Gi"}` 与父模板清洗 string 形态均输出 `medium`、`sizeLimit`，顺序正确且整体可被 YAML 解析；未知键不输出。
- 关键失败：`medium: memory` 与 `sizeLimit: 1GG` 均中断渲染并报告对应字段错误。
