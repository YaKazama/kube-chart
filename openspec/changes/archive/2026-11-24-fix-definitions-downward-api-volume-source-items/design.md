# definitions.downwardAPIVolumeSource items 过滤设计

## 技术目标

- capability：`definitions.downwardAPIVolumeSource`
- artifact-type：Helm library Chart 命名模板
- target：`definitions.downwardAPIVolumeSource`

## 设计决策

### Decision: defaultMode 与既有输出处理保持

- requirements：`downwardAPI 卷源 defaultMode 与 items 输入`、`downwardAPI item 委托与输出`
- choice：`defaultMode` 的 `base.get` 取值、`SYS.YAML_QUOTED` 剥离、`base.fileMode` 归一化、`base.int` 渲染与空值省略保持不变；`items` 的数组解析、逐元素委托、空输出跳过、顺序保持与 `base.slice` 输出保持不变。
- rationale：spec 未变更这两项行为，本 change 只替换 string item 的过滤与上下文构造，其余处理沿用当前实现。

### Decision: string item 形态判定与字段提取

- requirements：`downwardAPI 卷源 defaultMode 与 items 输入`
- choice：逐元素处理时，string item 先 `trim`，为空则跳过。用 `mustRegexMatch` 先匹配 `K8S.VOLUME.DOWNWARD_API_FIELD_ITEM`，未匹配再匹配 `K8S.VOLUME.DOWNWARD_API_RESOURCE_ITEM`；两者都不匹配时 `fail`，消息包含原串与两种形态。匹配后按命中的 `$_pattern` 用 `mustRegexReplaceAll` 按 `1`-`5` 下标提取并 `trim`，构造 `dict "path" $path`；`mode` 捕获非空时写入 `mode`。field 形态把第 3、4 段、resource 形态把第 3、4、5 段经 `mustWithout` 去除空串后 `join " "`，分别写入 `fieldRef` 或 `resourceFieldRef`，保持 string 类型。
- rationale：两个表达式均来自 `base.env`，已锚定全量输入并以 `[^\s,]+` 或 `\S+` 捕获，捕获段不含空白；按正则契约在提取后执行的 `trim` 不改变取值，不属于规格禁止的额外清洗。`*Ref` 保持 string，使子模板成为唯一解析入口，避免与本模板重复实现孙模板调用。

### Decision: map item 直传

- requirements：`downwardAPI 卷源 defaultMode 与 items 输入`
- choice：map item 直接作为 `definitions.downwardAPIVolumeFile` 上下文，不 `mustDeepCopy`、不遍历、不增删键；既不是 map 也不是 string 的元素 `fail`。
- rationale：规格要求原生 map 原样传递；只读透传不复制符合状态隔离规则，后续字段处理由子模板负责。

### Decision: 子模板委托与 items 输出

- requirements：`downwardAPI item 委托与输出`
- choice：沿用现有实现：每个 item 调用 `include "definitions.downwardAPIVolumeFile"`，`fromYaml` 恢复后用 `base.isFromYamlError` 保护；输出为空时跳过，非空 map 用 `mustAppend` 累积，最后以 `base.field` 的 `base.slice` 渲染 `items`。`definitions.downwardAPIVolumeFile` 保持 unavailable，本 change 不创建。
- rationale：spec 已固定子模板边界与输出顺序；fixture 回显只证明本模板的构造、委托与空输出处理，不代表真实依赖集成。

### Decision: 失败消息与契约注释

- requirements：`downwardAPI 卷源 defaultMode 与 items 输入`、`downwardAPI item 委托与输出`
- choice：形态不匹配统一中断，消息为 `[definitions.downwardAPIVolumeSource] items: '<text>' does not match '<path> [mode] field <fieldPath> [apiVersion]' or '<path> [mode] resource <resource> [containerName] [divisor]'`。同步更新文件头契约注释的 items 行为、边界、入参说明与示例，删除 `dict "item"` 包装和“由子模板解析段位”的旧描述。
- rationale：失败消息必须能定位输入；契约注释是模板的唯一说明，必须与规格一致。

## 依赖契约

### Dependency: `base.env`

- availability：existing
- source：`templates/base/_env.tpl`
- operation：consume
- input：`""`；经 `fromYaml` 恢复常量 map。
- output：常量 map；本模板只读取 `SYS.YAML_QUOTED`、`K8S.VOLUME.DOWNWARD_API_FIELD_ITEM` 与 `K8S.VOLUME.DOWNWARD_API_RESOURCE_ITEM`。
- ownership：`base.env` 负责常量结构、转义层与表达式内容；本模板只按已锁定键读取，不内联、不覆盖正则，也不新增平行表达式。

### Dependency: `base.get`

- availability：existing
- source：`templates/base/_get.tpl`
- operation：consume
- input：`list <上下文> <路径>`，路径为 `defaultMode` 与 `items`。
- output：YAML 字符串；路径缺失时为空输出。
- ownership：依赖负责数据源优先级、别名识别与 YAML 序列化；本模板负责 `trim`、解析保护、类型分支与字段生效判断。

### Dependency: `base.fileMode`

- availability：existing
- source：`templates/base/_validate.tpl`
- operation：consume
- input：剥离 YAML 引号后的 `defaultMode` 数值或字符串。
- output：十进制 int 字符串；格式或范围非法时中断。
- ownership：依赖负责八进制/十进制解析与 0-511 范围；本模板只负责空值省略。

### Dependency: `base.field`

- availability：existing
- source：`templates/base/_field.tpl`
- operation：consume
- input：`list <key> <value> <渲染模板>`。
- output：YAML 字段片段；空值不输出。
- ownership：依赖负责字段渲染与最终类型门禁；本模板负责字段生效判断与值归一化。

### Dependency: `base.int`

- availability：existing
- source：`templates/base/_types.tpl`
- operation：consume
- input：`base.fileMode` 输出的十进制整数字符串。
- output：数字字符串；非法输入中断。
- ownership：依赖负责 int 类型门禁；本模板不重复类型校验。

### Dependency: `base.slice`

- availability：existing
- source：`templates/base/_types.tpl`
- operation：consume
- input：非空 item map 列表。
- output：YAML array 片段；非 slice 输入中断。
- ownership：依赖负责类型门禁与序列化；本模板负责空列表省略。

### Dependency: `base.isFromYamlError`

- availability：existing
- source：`templates/base/_convert.tpl`
- operation：consume
- input：`fromYaml` 返回值。
- output：`"true"` 或 `"false"`。
- ownership：依赖负责解析错误识别；本模板负责失败消息与空输出判断。

### Dependency: `base.isFromYamlArrayError`

- availability：existing
- source：`templates/base/_convert.tpl`
- operation：consume
- input：`fromYamlArray` 返回值。
- output：`"true"` 或 `"false"`。
- ownership：依赖负责解析错误识别；本模板负责 `items` 数组类型失败消息。

### Dependency: `definitions.downwardAPIVolumeFile`

- availability：unavailable
- source：无
- operation：consume
- input：map item 为原始 `DownwardAPIVolumeFile` map；string item 为 `{path, [mode], fieldRef|resourceFieldRef: <string>}`。
- output：`DownwardAPIVolumeFile` YAML 字段片段；空输出跳过，非法 YAML 或非 map 中断。
- ownership：子模板负责 `*Ref` 串的字段拆分、内部字段校验与互斥判定，委托 `definitions.objectFieldSelector`/`definitions.resourceFieldSelector` 渲染这两个字段，并负责 `mode` 归一化与 `path` 校验；本模板只负责过滤、上下文构造、数组遍历与委托。两个孙模板已存在，但不属于本模板的直接依赖。

## 代码边界

### `templates/api-resources/Definitions/_DownwardAPIVolumeSource.tpl`

- access：write
- operations：更新 `items` 的 string 分支为形态判定、捕获提取与 `{path, [mode], *Ref}` 上下文构造；更新文件头契约注释的行为、边界、入参与示例；`defaultMode`、map item 直传、子模板委托与输出处理保持语义不变。
- writable-scopes：文件头契约注释与 `define "definitions.downwardAPIVolumeSource"` 块；`defaultMode` 处理区段保持原样。

### `templates/base/_env.tpl`

- access：read
- operations：复核 `SYS.YAML_QUOTED`、`K8S.VOLUME.DOWNWARD_API_FIELD_ITEM` 与 `K8S.VOLUME.DOWNWARD_API_RESOURCE_ITEM` 的捕获顺序与锚定语义。

### `templates/base/_get.tpl`

- access：read
- operations：复核 `base.get` 的入参、返回值与缺失边界。

### `templates/base/_convert.tpl`

- access：read
- operations：复核 `base.isFromYamlError` 与 `base.isFromYamlArrayError` 的返回形态。

### `templates/base/_validate.tpl`

- access：read
- operations：复核 `base.fileMode` 的数值范围与字符串解析。

### `templates/base/_field.tpl`

- access：read
- operations：复核 `base.field` 的字段渲染、空值省略与 `base.slice` 路由。

### `templates/base/_types.tpl`

- access：read
- operations：复核 `base.int` 与 `base.slice` 的类型门禁。

### `templates/api-resources/Definitions/_Volume.tpl`

- access：read
- operations：复核 downwardAPI 分支传给 `definitions.downwardAPIVolumeSource` 的 `items` 字符串形态。

### `templates/api-resources/Definitions/_ObjectFieldSelector.tpl`

- access：read
- operations：复核孙模板存在性及其接收的 `fieldPath`、`apiVersion` 入参形态。

### `templates/api-resources/Definitions/_ResourceFieldSelector.tpl`

- access：read
- operations：复核孙模板存在性及其接收的 `resource`、`containerName`、`divisor` 入参形态。

## 验证设计

- 最小有效：在 `/tmp/sd-kube-chart/` 新建最小 application Chart，加载 `templates/base/`、`_DownwardAPIVolumeSource.tpl` 与动态调用入口，为 `definitions.downwardAPIVolumeFile` 提供回显上下文的同名 fixture。渲染 `{defaultMode: "0644", items: ["  meta 0400 field metadata.name  "]}`，确认 `defaultMode: 420`，且子模板收到 `{path: "meta", mode: "0400", fieldRef: "metadata.name"}`。
- 较完整有效：覆盖 field 无 mode 带 apiVersion、resource 带 mode/containerName/divisor、map item 原样直传、map 与 string 混合且顺序不变、空白 string 跳过、空 `items`、显式 `defaultMode: 0`。
- 关键失败：覆盖 `items` 非 array、元素类型非法、string 形态不匹配、非法 `defaultMode`、子模板输出为空时跳过、子模板输出非法 YAML 或非 map 时中断。
- fixture 边界：回显 fixture 只证明本模板的过滤、上下文构造与委托；`*Ref` 拆分、孙模板渲染与 `mode`/`path` 归一化由后续 `definitions.downwardAPIVolumeFile` change 验证。
