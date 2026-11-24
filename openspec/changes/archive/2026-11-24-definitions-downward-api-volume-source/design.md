# definitions.downwardAPIVolumeSource 设计

## 技术目标

- capability：`definitions.downwardAPIVolumeSource`
- artifact-type：Helm library Chart 命名模板
- target：`definitions.downwardAPIVolumeSource`

## 设计决策

### Decision: defaultMode 归一化

- requirements：`downwardAPI 卷源 defaultMode 与 items 输入`
- choice：用 `base.get` 读取 `defaultMode`，`trim` 后用 `SYS.YAML_QUOTED` 剥离引号；非空值交给 `base.fileMode` 归一化，再以 `base.field` 的 `base.int` 渲染。未提供或剥离后为空时省略。
- rationale：与 `definitions.configMapVolumeSource` 的 `defaultMode` 处理一致；`base.fileMode` 已覆盖八进制/十进制范围与非法值，显式 0 在剥离后仍为非空字符串，不会被省略。

### Decision: items 原样委托

- requirements：`downwardAPI 卷源 defaultMode 与 items 输入`、`downwardAPI item 委托与输出`
- choice：用 `fromYamlArray (include "base.get" (list . "items"))` 恢复数组并用 `base.isFromYamlArrayError` 保护；逐元素处理：
  - string：`trim` 后为空则跳过；非空时以 `dict "item" $_element` 原样包装，包装前不改写字符串。
  - map：原样作为子模板上下文，不复制、不增删键。
  - 其他类型：中断。
  - 每个元素调用 `definitions.downwardAPIVolumeFile`；空输出跳过，非法 YAML 或非 map 中断；有效 map 按输入顺序追加，最后用 `base.field` 的 `base.slice` 渲染 `items`。
- rationale：Helm `include` 上下文必须是 map，`item` 键承载原始 string item；map item 已是 `DownwardAPIVolumeFile` 上下文，原样传递即可。source 不解析段位、不构造 item map、不归一化 path，避免与子模板重复解析。

### Decision: 错误消息与输出处理

- requirements：`downwardAPI item 委托与输出`
- choice：`items` 非 array 时消息为 `must be array type`；元素类型非法时消息包含 `kindOf`；string 段位错误不复用 source 消息，交由子模板负责。子模板输出非法 YAML 或非 map 时统一中断。
- rationale：source 只负责容器结构与委托，失败消息必须与其职责一致；段位错误定位由子模板提供。

### Decision: 子模板 unavailable 与验证 fixture

- requirements：`downwardAPI item 委托与输出`
- choice：`definitions.downwardAPIVolumeFile` 标记为 `unavailable`，本 change 不创建。验证在 `/tmp/sd-kube-chart/` 最小 application Chart 中提供同名回显 fixture，按上下文返回原值、空内容或非 map 内容。
- rationale：当前模板清单中没有该 define；fixture 只证明 source 的包装、原样传递与输出边界，不证明段位解析或 path 归一化。

## 依赖契约

### Dependency: `base.env`

- availability：existing
- source：`templates/base/_env.tpl`
- operation：consume
- input：`""`；经 `fromYaml` 恢复常量 map。
- output：常量 map；本模板只读取 `SYS.YAML_QUOTED`。
- ownership：`base.env` 负责常量结构与 YAML 转义；本模板只剥离 `defaultMode` 外层引号。

### Dependency: `base.get`

- availability：existing
- source：`templates/base/_get.tpl`
- operation：consume
- input：`list <上下文> <路径>`。
- output：YAML 字符串；缺失时为空输出。
- ownership：依赖负责数据源优先级与 YAML 序列化；本模板负责 `trim`、解析保护与字段生效判断。

### Dependency: `base.fileMode`

- availability：existing
- source：`templates/base/_validate.tpl`
- operation：consume
- input：剥离 YAML 引号后的 `defaultMode` 字符串。
- output：十进制 int 字符串；范围或格式非法时中断。
- ownership：依赖负责八进制/十进制解析与 0-511 范围；本模板负责空值省略。

### Dependency: `base.field`

- availability：existing
- source：`templates/base/_field.tpl`
- operation：consume
- input：`list <key> <value> <渲染模板>`。
- output：YAML 字段片段；空值不输出。
- ownership：依赖负责字段渲染；本模板负责字段生效判断与值归一化。

### Dependency: `base.int`

- availability：existing
- source：`templates/base/_types.tpl`
- operation：consume
- input：`base.fileMode` 输出或整数输入。
- output：十进制整数字符串；非法输入中断。
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
- output：布尔字符串。
- ownership：依赖负责解析错误识别；本模板负责失败消息与空输出判断。

### Dependency: `base.isFromYamlArrayError`

- availability：existing
- source：`templates/base/_convert.tpl`
- operation：consume
- input：`fromYamlArray` 返回值。
- output：布尔字符串。
- ownership：依赖负责解析错误识别；本模板负责 `items` 数组类型失败消息。

### Dependency: `definitions.downwardAPIVolumeFile`

- availability：unavailable
- source：无
- operation：consume
- input：string item 为 `dict "item" <原始字符串>`；map item 为原始 `DownwardAPIVolumeFile` map。
- output：`DownwardAPIVolumeFile` YAML 字段片段；空输出跳过，非法 YAML 或非 map 中断。
- ownership：子模板负责 string item 段位解析、`path`/`fieldRef`/`resourceFieldRef`/`mode` 构造、`path` 归一化与内部字段校验；本模板只负责数组遍历、空白跳过与原样委托。

## 代码边界

### `templates/api-resources/Definitions/_DownwardAPIVolumeSource.tpl`

- access：write
- operations：新建 `definitions.downwardAPIVolumeSource`，实现 `defaultMode` 归一化、`items` 数组类型门禁、string/map 原样包装、空白 string 跳过、子模板委托与 `items` 渲染。
- writable-scopes：新建文件的契约注释与 `define "definitions.downwardAPIVolumeSource"` 块。

### `templates/base/_env.tpl`

- access：read
- operations：复核 `SYS.YAML_QUOTED`。

### `templates/base/_get.tpl`

- access：read
- operations：复核 `base.get` 的入参、返回值与缺失边界。

### `templates/base/_convert.tpl`

- access：read
- operations：复核 `base.isFromYamlError` 与 `base.isFromYamlArrayError`。

### `templates/base/_validate.tpl`

- access：read
- operations：复核 `base.fileMode` 的数值范围。

### `templates/base/_field.tpl`

- access：read
- operations：复核 `base.field` 的字段渲染与空值省略契约。

### `templates/base/_types.tpl`

- access：read
- operations：复核 `base.int` 与 `base.slice` 的类型门禁。

### `templates/api-resources/Definitions/_Volume.tpl`

- access：read
- operations：复核 downwardAPI 分支传给 `definitions.downwardAPIVolumeSource` 的 `defaultMode` 与 `items` 上下文形状。

## 验证设计

- 最小有效：在 `/tmp/sd-kube-chart/` 新建最小 application Chart，加载 `templates/base/`、`_DownwardAPIVolumeSource.tpl` 与动态调用入口，为 `definitions.downwardAPIVolumeFile` 提供回显上下文的同名 fixture。渲染 `{defaultMode: "0644", items: ["meta 0400 field metadata.name"]}`，确认 `defaultMode: 420`，且子模板收到 `{item: "meta 0400 field metadata.name"}`。fixture 只证明 source 行为。
- 较完整有效：覆盖 map item 原样传递、map 与 string 混合、空白 string 跳过、空 `items`、显式 `defaultMode: 0`，确认不构造 `path`/`fieldRef`/`mode`，顺序保持不变。
- 关键失败：覆盖 `items` 非 array、元素类型非法、子模板输出为空时跳过、子模板输出非法 YAML 或非 map 时中断，以及非法 `defaultMode`。string 段位与 path 失败由子模板负责，不在本 change 验证。
