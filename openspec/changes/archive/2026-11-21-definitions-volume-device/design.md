# 新增 definitions.volumeDevice 模板设计

## 技术目标

- capability：`definitions.volumeDevice`
- artifact-type：Helm library Chart 命名模板与父级 Container 数组处理
- target：`templates/api-resources/Definitions/_VolumeDevice.tpl` 的 `definitions.volumeDevice`，以及 `templates/api-resources/Definitions/_Container.tpl` 的 `definitions.container.array.normalize`、`definitions.container.array` 与 `definitions.container` 的 `volumeDevices` 调用

## 设计决策

### Decision: 父模板空间统一 string 归一化

- requirements：`VolumeDevice 字符串简写`、`volumeDevices 数组归一化、去空与去重`、`直接调用 volumeDevice`
- choice：在 `_Container.tpl` 新增 `definitions.container.array.normalize`，负责用正则把单个 string 解析为含 `name`、`devicePath` 的 YAML map。`definitions.container.array` 新增可选 `normalize` 入参，string 元素先经该模板归一化；`definitions.volumeDevice` 的 string 分支调用同一模板。
- rationale：用户确认 string → map 拆分由父模板执行，且归一化模板使用父模板空间命名；单一解析实现避免父模板与直接调用产生两套规则，符合现有 `definitions.container.array` 的集中式数组处理方式。

### Decision: string 简写解析

- requirements：`VolumeDevice 字符串简写`
- choice：`trim` 后使用 `base.env` 新增的 `K8S.VOLUME_DEVICE` 执行 `mustRegexMatch`，再用 `mustRegexReplaceAll` 按 `$1`、`$2` 提取 `name`、`devicePath`；正则运行时表达式为 `^[,\s]*([^,\s]*)(?:[,\s]+([^,\s]*))?[,\s]*$`。0 段返回两个字段均为空的 map，1 段保留 `devicePath` 为空，2 段按位置赋值；超过 2 个非空段时不匹配，并以 `[definitions.container]` 前缀报告格式错误。
- rationale：固定正则集中定义在 `base.env`，符合项目正则契约；捕获组按位置取值，0、1、2 段行为与既有 spec 一致；不引入 `mustRegexSplit`、`mustWithout` 或 `base.slice.cleanup` 的数值转换。

### Decision: 字段顺序、校验与空值

- requirements：`VolumeDevice 字段渲染`、`name 校验`、`直接调用 volumeDevice`
- choice：map 分支使用 `base.get` 取值并保留默认别名，string 分支调用 `definitions.container.array.normalize`；上下文不是 map 或 string 时以 `[definitions.volumeDevice]` 前缀中断；两个字段都为空时返回空内容；仅一个为空时以 `[definitions.volumeDevice]` 前缀中断；先以 `base.path` 的 `abs` 模式归一化并校验 `devicePath`，再以 `base.rfc` 的 `1123` 模式校验 `name`，按 `devicePath`、`name` 顺序调用 `base.field`。
- rationale：Kubernetes API v1.36 的 `VolumeDevice` 字段表顺序为 `devicePath`、`name`，volume 名称必须是 DNS_LABEL；draft 已确认仅分隔符视为空输入、单字段缺失中断。

### Decision: 父级去空与去重

- requirements：`volumeDevices 数组归一化、去空与去重`
- choice：`definitions.container.array` 新增可选 `dedupe`；渲染结果为空时沿用现有剔除逻辑；`dedupe=true` 时对渲染后的 map 列表执行 `mustUniq`，不新增按 `devicePath` 的去重键。
- rationale：用户确认使用 Helm 内置函数和统一去重规则；与 `core.podSpec` 的 volumes/hostAliases 处理一致；完全重复项保留首个，非完全重复的冲突交给 Kubernetes。

### Decision: 输出形态

- requirements：`VolumeDevice 字段渲染`、`直接调用 volumeDevice`
- choice：只输出当前层 `devicePath` 与 `name`，不输出 `volumeDevices` 父键、`apiVersion` 或 `kind`；无有效内容时返回空内容。
- rationale：`definitions.container.array` 通过 `include ... | fromYaml` 回收子模板结果，输出必须是 YAML map 片段；与现有 `definitions.*` 模板一致。

### Decision: 调用契约

- requirements：`volumeDevices 数组归一化、去空与去重`
- choice：`definitions.container` 的 `volumeDevices` 调用改为传入 `"key" "volumeDevices"`、`"define" "definitions.volumeDevice"`、`"normalize" "definitions.container.array.normalize"`、`"dedupe" true` 与 `"raw"`，不再设置 `allowString`；设置 `normalize` 后 string 元素先归一化，非 map/string 元素继续由 `definitions.container.array` 的现有类型门禁中断。
- rationale：`normalize` 已覆盖 string 元素；`allowString` 继续只服务于直接把 string 传给子模板的既有字段。

## 依赖契约

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`add`
- input：`""`
- output：可由 `fromYaml` 恢复的常量 Map；新增 `K8S.VOLUME_DEVICE`，源文件 YAML 表达式为 `"^[,\\s]*([^,\\s]*)(?:[,\\s]+([^,\\s]*))?[,\\s]*$"`，本模板读取该键。
- ownership：常量集中定义由依赖层负责；正则键选择、匹配与捕获组取值由本层负责。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, "name"]` 与 `list [上下文, "devicePath"]`；别名保持默认开启。
- output：YAML 字符串；路径缺失、为 `null` 或为空字符串时为空输出。
- ownership：数据源优先级、别名识别与标量序列化由依赖层负责；字段生效判断与 `trim` 由本层负责。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 返回的 `name`、`devicePath` 原始文本。
- output：解码后的 string；空输入返回空字符串；非 string 标量中断。
- ownership：YAML 标量解码与 string 类型门禁由依赖层负责；字段存在性与后续校验由本层负责。

### Dependency: `base.rfc`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：`list [name, "1123"]`
- output：校验通过的 `name`；空字符串、非 RFC1123 Label 或超过 63 字符时中断。
- ownership：RFC1123 Label 校验与失败消息由依赖层负责；调用时机与字段顺序由本层负责。

### Dependency: `base.path`

- availability：`existing`
- source：`templates/base/_validate.tpl`
- operation：`consume`
- input：`list [devicePath, "abs"]`
- output：归一化后的绝对路径；非绝对路径或非 string 输入中断。
- ownership：路径 trim、`clean` 与绝对路径门禁由依赖层负责；字段存在性与渲染顺序由本层负责。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list ["devicePath", 归一化路径, "quote"]`、`list ["name", 校验后名称, "quote"]` 与 `list ["volumeDevices", 渲染结果列表, "base.slice"]`。
- output：值生效时输出字段片段，空值时不输出；最终类型不符时中断。
- ownership：字段格式化、引号与枚举校验由依赖层负责；字段生效条件、顺序与渲染模板选择由本层负责。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 的返回值。
- output：错误 map 时为 `true`，否则为 `false`。
- ownership：错误形态识别由依赖层负责；中断消息与处理分支由本层负责。

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 的返回值。
- output：错误 slice 时为 `true`，否则为 `false`。
- ownership：错误形态识别由依赖层负责；数组类型失败消息由本层负责。

### Dependency: `base.slice`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：已完成子模板渲染并去重的 map 列表。
- output：`toYamlPretty` 序列化结果；非 slice 输入中断。
- ownership：最终类型门禁与序列化由依赖层负责；非空判断与去重时机由本层负责。

### Dependency: `definitions.container.array`

- availability：`existing`
- source：`templates/api-resources/Definitions/_Container.tpl`
- operation：`update`
- input：上下文 map，含 `key`、`define`、`raw`，以及可选 `allowString`、`normalize`、`dedupe`。
- output：可嵌入 Container 的单字段 YAML 片段；无有效内容时为空。
- ownership：数组解析、string 归一化钩子、空结果剔除与去重由本层负责；元素渲染由子模板负责。

### Dependency: `definitions.container.array.normalize`

- availability：`existing`
- source：`templates/api-resources/Definitions/_Container.tpl`
- operation：`add`
- input：单个 `<name> <devicePath>` string。
- output：含 `name`、`devicePath` 的 YAML map；空或仅分隔符输入返回两个字段均为空的 map；超过两个非空段时因不匹配而中断。
- ownership：父模板空间的字符串简写解析由本层负责；source 文件已存在，`definitions.container.array.normalize` 由本 change 新增；`name` 与 `devicePath` 的格式校验由 `definitions.volumeDevice` 负责。

## 代码边界

### `templates/api-resources/Definitions/_Container.tpl`

- access：`write`
- operations：`add` `define "definitions.container.array.normalize"` 与紧邻中文契约注释；`update` `define "definitions.container.array"` 的入参解析、元素归一化、去重与契约注释；`update` `define "definitions.container"` 的 `volumeDevices` 字段块与整体契约注释对应行。
- writable-scopes：`definitions.container.array.normalize` 新增区段（读取 `K8S.VOLUME_DEVICE`）；`definitions.container.array` 的 `normalize`、`dedupe` 参数解析、循环内归一化、去重及契约注释；`definitions.container` 的 `volumeDevices` 调用行与整体契约注释中 `volumeDevices`、数组边界相关行。

### `templates/api-resources/Definitions/_VolumeDevice.tpl`

- access：`write`
- operations：`add` 新文件，包含 `define "definitions.volumeDevice"`、紧邻中文整体契约注释与字段级中文注释。
- writable-scopes：新文件全文。

### `templates/base/_env.tpl`

- access：`write`
- operations：`add` `K8S.VOLUME_DEVICE`
- writable-scopes：`K8S.VOLUME_DEVICE` 常量键及其紧邻注释

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume` `base.get`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume` `base.string.normalize`、`base.isFromYamlError`、`base.isFromYamlArrayError`

### `templates/base/_k8s.tpl`

- access：`read`
- operations：`consume` `base.rfc`

### `templates/base/_validate.tpl`

- access：`read`
- operations：`consume` `base.path`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume` `base.field`

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume` `base.slice`

## 验证设计

- 在 `/tmp/sd-kube-chart/` 新建最小 application Chart，依赖当前 library Chart，加载真实 `_Container.tpl`、`_VolumeDevice.tpl` 与 base 模板；由于修改 `_env.tpl`，验证必须加载其真实实现，不得用同名 fixture 替代；父级场景通过真实 `definitions.container` 链路渲染。
- 最小有效：map 输入 `{name: data, devicePath: /dev/xvda}`，确认输出顺序为 `devicePath`、`name`。
- 较完整有效：string、string array、map/string 混合数组、首尾/连续/混用分隔符、`/dev/../dev/xvda` 绝对路径归一化、完全重复项去重、非完全重复项保留、空项与仅分隔符项剔除、全部为空不输出 `volumeDevices`。
- 直接调用：fixture 模板分别以等价 map 和 string 调用 `definitions.volumeDevice`，确认输出一致；map 使用 `nameAlias`、`devicePathAlias` 时按既有别名规则生效。
- 关键失败：单字段缺失、超过两个非空段、非法 `name`、相对 `devicePath`、非数组 `volumeDevices`、非 map/string 数组元素、直接调用时非 map/string 上下文。
- fixture 只用于直接调用入口；父级数组行为必须由真实 `definitions.container` 与 `definitions.container.array` 证明，不得用 fixture 替代。
