# definitions.csiVolumeSource 定义模板设计

## 技术目标

- capability：`definitions.csiVolumeSource`
- artifact-type：Helm library Chart 命名模板
- target：`templates/api-resources/Definitions/_CSIVolumeSource.tpl`

## 设计决策

### Decision: 按 API 顺序逐字段闭环

- requirements：`CSIVolumeSource 字段渲染`
- choice：按 `driver`、`fsType`、`nodePublishSecretRef`、`readOnly`、`volumeAttributes` 顺序，每个字段独立完成取值、归一/校验、`base.field` 输出，不合并跨字段状态。
- rationale：项目模板规则要求直接渲染 Kubernetes API 字段时按官方字段顺序逐字段闭环；五个字段之间没有关联判定。

### Decision: nodePublishSecretRef 双形态归一与委托

- requirements：`nodePublishSecretRef 双形态`
- choice：用 `get` 读取上下文同名键；string 形态经 `SYS.YAML_QUOTED` 剥离 YAML 引号并 trim，非空时组装 `{name: <值>}`；map 形态只读透传；nil 跳过；其他类型本层中断。归一结果委托 `definitions.localObjectReference`，`fromYaml` 后经 `base.isFromYamlError` 保护，非空结果以 `base.field` + `base.map` 输出。
- rationale：Helm 的 `fromYaml` 只还原 map，`base.get` 输出的 YAML 字符串无法再区分 string 与 map；`definitions.envFromSource`、`definitions.envVarSource` 对同类多类型字段同样直接读取上下文。不做 YAML 标量解码，因为父模板的 csi 简写允许 `true`、`false` 作为 secret 名称原样下传，解码会把它们变成布尔而中断。

### Decision: 委托既有枚举与布尔校验

- requirements：`fsType 枚举`、`readOnly 布尔`
- choice：`fsType` 经 `base.get`、`base.string.normalize` 与 trim 后，非空时交给 `base.field` 的允许值列表（`ext4`、`xfs`、`ntfs`）校验并输出；`readOnly` 经 `base.get`、`SYS.YAML_QUOTED` 剥离与 trim 后，非空时交给 `base.field` + `base.bool`。
- rationale：允许值列表与布尔类型门禁已由 `base.field`、`base.bool` 提供，项目规则禁止在本层内联。`base.get` 会把 string `"false"` 序列化为带引号标量，必须先剥离才能进入 `base.bool`；该处理与 `definitions.secretEnvSource` 的 optional 一致。`fsType` 不做大小写归一，父模板 csi string 分支已输出小写。

### Decision: volumeAttributes 清洗与渲染通道

- requirements：`volumeAttributes 对象`
- choice：`base.get` 取值后 `fromYaml` 并以 `base.isFromYamlError` 排除解析错误；逐值 `kindIs "string"` 校验，非 string 本层中断；非空 map 以 `base.field` + `base.map` 输出，空 map 跳过。
- rationale：`base.map` 会把空 map 渲染为 `{}`，字段生效判定必须在调用前完成；对象键经 YAML 恢复即为 string。清洗与生效判定在本层，最终 map 序列化由 `base.map` 承担。

### Decision: 失败消息边界

- requirements：`CSIVolumeSource 字段渲染`
- choice：本层产生的消息统一为 `[definitions.csiVolumeSource] <字段>: <原因>`；`base.string.normalize`、`base.field`、`base.bool`、`definitions.localObjectReference` 的消息保留其自身前缀。
- rationale：Helm 无法改写被 include 模板的失败消息；`definitions.securityContext` 已采用同一边界。

### Decision: 验证边界

- requirements：`CSIVolumeSource 字段渲染`、`fsType 枚举`、`readOnly 布尔`、`nodePublishSecretRef 双形态`、`volumeAttributes 对象`
- choice：在 `/tmp/sd-kube-chart/` 新建最小 application Chart，加载真实 `_CSIVolumeSource.tpl`、`_LocalObjectReference.tpl` 与 base 依赖，同时通过直接 include 和 `definitions.volume` 的 csi 分支两条入口渲染；全部依赖均为 existing，不使用 fixture。
- rationale：`definitions.localObjectReference` 与 `definitions.volume` 均已实现，可直接验证真实调用契约。

## 依赖契约

### Dependency: `base.get`

- availability：existing
- source：`templates/base/_get.tpl`
- operation：consume
- input：`list <上下文> <点分路径>`，路径为 `driver`、`fsType`、`readOnly`、`volumeAttributes`。
- output：可 `fromYaml` 解析的 YAML 字符串；路径缺失时为空字符串。
- ownership：依赖负责取值、别名识别与跨源合并；本层负责字段生效判定与后续归一化。

### Dependency: `base.string.normalize`

- availability：existing
- source：`templates/base/_convert.tpl`
- operation：consume
- input：`base.get` 返回的 YAML 标量文本。
- output：解码后的 string；空输入返回空字符串；非 string 标量中断。
- ownership：依赖负责 YAML 标量解码与类型门禁；本层负责 trim 与空值跳过。

### Dependency: `base.field`

- availability：existing
- source：`templates/base/_field.tpl`
- operation：consume
- input：`list [key, value, 渲染模板, 允许值列表]`，用于五个字段的输出。
- output：单字段 YAML 片段；值为空时不输出；枚举不匹配时中断。
- ownership：依赖负责字段输出格式、枚举校验与最终类型门禁；本层负责字段生效判定与值归一化。

### Dependency: `base.map`

- availability：existing
- source：`templates/base/_types.tpl`
- operation：consume
- input：已恢复的 map。
- output：`toYamlPretty` 序列化结果；空 map 输出 `{}`；非 map 中断。
- ownership：依赖负责 map 序列化与类型门禁；本层负责空 map 跳过。

### Dependency: `base.bool`

- availability：existing
- source：`templates/base/_types.tpl`
- operation：consume
- input：剥离 YAML 引号后的 `true` / `false` 字符串。
- output：`true` / `false`；其他取值中断。
- ownership：依赖负责布尔表示校验；本层负责引号剥离、trim 与空值跳过。

### Dependency: `base.env`

- availability：existing
- source：`templates/base/_env.tpl`
- operation：consume
- input：`""`；经 `fromYaml` 恢复常量 map。
- output：常量 map；本层只读取 `SYS.YAML_QUOTED`。
- ownership：依赖负责集中常量；本层不得内联等价正则。

### Dependency: `base.isFromYamlError`

- availability：existing
- source：`templates/base/_convert.tpl`
- operation：consume
- input：`fromYaml` 返回值。
- output：布尔字符串。
- ownership：依赖负责识别 Helm 的 YAML 解析错误形态。

### Dependency: `definitions.localObjectReference`

- availability：existing
- source：`templates/api-resources/Definitions/_LocalObjectReference.tpl`
- operation：consume
- input：`nodePublishSecretRef` 归一后的 map，含 `name` 或其同级别名。
- output：`name` 字段片段；`name` 为空时为空内容；名称非法时中断。
- ownership：依赖负责名称校验与输出；本层负责 string 形态清洗、map 透传与空结果跳过。

## 代码边界

### `templates/api-resources/Definitions/_CSIVolumeSource.tpl`

- access：write
- operations：新增 `definitions.csiVolumeSource` 及其整体契约注释，按 API 顺序实现五个字段。
- writable-scopes：文件头整体契约注释与 `definitions.csiVolumeSource` define 块。

### `templates/api-resources/Definitions/_Volume.tpl`

- access：read
- operations：复核 `csi` 分支的调用契约与上下文形态。

### `templates/api-resources/Definitions/_LocalObjectReference.tpl`

- access：read
- operations：复核入参、空输出与失败边界。

### `templates/base/_get.tpl`

- access：read
- operations：复核取值、别名与空输出语义。

### `templates/base/_convert.tpl`

- access：read
- operations：复核 `base.string.normalize` 与 `base.isFromYamlError` 契约。

### `templates/base/_field.tpl`

- access：read
- operations：复核渲染模板、允许值列表与空值输出契约。

### `templates/base/_types.tpl`

- access：read
- operations：复核 `base.map` 与 `base.bool` 契约。

### `templates/base/_env.tpl`

- access：read
- operations：复核 `SYS.YAML_QUOTED` 常量。

## 验证设计

- 最小有效：在新最小 application Chart 中直接 include `definitions.csiVolumeSource` 并传 `{driver: "csi.example.com"}`，输出仅含 `driver: "csi.example.com"`。
- 较完整有效：直接 include 传 `driver`、`fsType: xfs`、string 形态 `nodePublishSecretRef: regcred`、`readOnly: false`、`volumeAttributes`；再传 map 形态 `nodePublishSecretRef` 与 `readOnly: true`。随后经 `definitions.volume` 的 csi string（`driver.example secret ext4 true attr (mode 0777)`）与原生 map 两条分支渲染完整 Volume，确认 `csi` 片段字段与顺序。
- 关键失败：缺少 `driver`、`driver` 非 string、`fsType: EXT4`、`readOnly: yes`、`volumeAttributes` 值非 string、`nodePublishSecretRef` 为数组、string 名称不符合 `definitions.localObjectReference` 规则；确认全部中断且消息前缀归属符合失败消息边界。
