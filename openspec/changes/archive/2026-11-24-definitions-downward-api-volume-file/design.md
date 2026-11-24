# definitions.downwardAPIVolumeFile 设计

## 技术目标

- capability：`definitions.downwardAPIVolumeFile`
- artifact-type：`Helm 命名模板`
- target：`templates/api-resources/Definitions/_DownwardAPIVolumeFile.tpl`

## 设计决策

### Decision: 引用字段的互斥与类型分派

- requirements：`字段引用解析与委托`、`引用互斥与空值`
- choice：用 `hasKey` 判定 `fieldRef` 与 `resourceFieldRef` 是否存在，两者状态相同即中断；唯一存在的字段用 `get` 读取原始值，`map` 直接作为选择器上下文，`string` 进入位次解析，其他类型中断；`string` 去空白后为空或 `map` 长度为 0 时中断。
- rationale：两个字段是 map|string 联合类型，`base.get` 返回 YAML 字符串会丢失原始类型；`hasKey` + `get` + `kindIs` 与 `definitions.envFromSource`、`definitions.envVarSource` 的既有做法一致。

### Decision: 字符串引用的位次解析

- requirements：`字段引用解析与委托`
- choice：用 `mustRegexSplit $const.SPLIT.SPACE (trim $raw) -1` 后 `mustWithout` 去除空段；`fieldRef` 取第 1 段为 `fieldPath`、第 2 段为 `apiVersion`，`resourceFieldRef` 取第 1 段为 `resource`、第 2 段为 `containerName`、第 3 段为 `divisor`；超出位次的段忽略；切分后无有效段时中断。
- rationale：父模板把捕获段以单个空格连接后传入，`SPLIT.SPACE` 与父模板正则的段边界一致；位次与 `DOWNWARD_API_FIELD_ITEM`、`DOWNWARD_API_RESOURCE_ITEM` 的捕获顺序一致。

### Decision: 引用选择器委托

- requirements：`字段引用解析与委托`
- choice：统一调用 `definitions.objectFieldSelector` 或 `definitions.resourceFieldSelector`；`fromYaml` 恢复后先用 `base.isFromYamlError` 排除解析错误，再用 `base.field` + `base.map` 输出 `fieldRef` 或 `resourceFieldRef`。
- rationale：选择器已负责字段级校验、类型处理和渲染；本模板只承担类型归一与位次组装。

### Decision: path 归一化

- requirements：`path 与 mode 校验`
- choice：`base.get` 取值后交 `base.string.normalize` 解码，再对结果 `trim`；`base.path` 的 `rel` 模式归一化 `.` 与 `..`；结果等于 `..` 或以 `../` 开头时中断；最后用 `base.field` 的 `quote` 渲染。
- rationale：与 `definitions.keyToPath` 的 `path` 规则一致，满足 API 对相对路径的要求。

### Decision: mode 归一化

- requirements：`path 与 mode 校验`
- choice：`base.get` 取值后 `trim`；非空时用 `SYS.YAML_QUOTED` 剥离 YAML 引号并 `trim`，再交 `base.fileMode` 归一化，最后用 `base.field` + `base.int` 输出；空值跳过。
- rationale：与 `definitions.keyToPath`、`definitions.downwardAPIVolumeSource` 的 `mode` 与 `defaultMode` 处理一致。

### Decision: 字段输出顺序

- requirements：`DownwardAPIVolumeFile 字段渲染`
- choice：先完成互斥校验与引用片段构造，再按 `fieldRef`、`mode`、`path`、`resourceFieldRef` 顺序输出已生效片段。
- rationale：本地 Kubernetes API v1.36 参考的字段表顺序，与既有 Definitions 模板一致。

## 依赖契约

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：任意占位值，调用方传 `""`
- output：可 `fromYaml` 恢复的常量 Map；本模板读取 `SPLIT.SPACE` 与 `SYS.YAML_QUOTED`
- ownership：`base.env` 维护常量；本模板只读取已存在的键，不新增或覆盖

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, 点分路径]`
- output：YAML 字符串；路径缺失时为空输出
- ownership：`base.get` 负责多数据源取值、别名与序列化；本模板负责空值与类型判定

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 返回的 YAML 字符串
- output：解码后的 string；非 string 内容中断
- ownership：`base.string.normalize` 负责 YAML 标量解码；本模板负责 `path` 非空与路径规则

### Dependency: `base.path`

- availability：`existing`
- source：`templates/base/_validate.tpl`
- operation：`consume`
- input：`list [path, "rel"]`
- output：归一化后的相对路径；绝对路径时中断
- ownership：`base.path` 负责 `.`、`..` 归一化与绝对路径拒绝；本模板负责归一化结果的 `..`、`../` 拒绝与渲染

### Dependency: `base.fileMode`

- availability：`existing`
- source：`templates/base/_validate.tpl`
- operation：`consume`
- input：已剥离 YAML 引号并 `trim` 的 string
- output：十进制 int；非法格式或越界时中断
- ownership：`base.fileMode` 负责格式与范围校验；本模板负责取值、空值跳过与渲染

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [key, value, renderer]`
- output：带前导换行的 YAML 键值片段；渲染结果为空时不输出
- ownership：`base.field` 负责渲染与引号、复杂类型格式；本模板负责字段生效判断与调用时机

### Dependency: `base.int`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：`base.fileMode` 返回的 int
- output：十进制数字字符串；非整数输入中断
- ownership：`base.int` 负责整数格式校验；本模板只把它作为 `mode` 渲染器

### Dependency: `base.map`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：`fromYaml` 恢复后的 map
- output：YAML map 字符串；非 map 输入中断
- ownership：`base.map` 负责 map 类型门禁与序列化；本模板只把它作为引用片段渲染器

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 的返回值
- output：`"true"` 或 `"false"` 字符串
- ownership：`base.isFromYamlError` 识别解析错误；本模板负责错误中断

### Dependency: `definitions.objectFieldSelector`

- availability：`existing`
- source：`templates/api-resources/Definitions/_ObjectFieldSelector.tpl`
- operation：`consume`
- input：包含 `fieldPath`（必填）与 `apiVersion`（可选）的 map
- output：可嵌入 `fieldRef` 位置的 YAML 字段片段；缺失或不受支持的 `fieldPath`、非法 `apiVersion` 时中断
- ownership：选择器负责 `fieldPath` 校验与字段渲染；本模板负责 map 直传或字符串位次组装

### Dependency: `definitions.resourceFieldSelector`

- availability：`existing`
- source：`templates/api-resources/Definitions/_ResourceFieldSelector.tpl`
- operation：`consume`
- input：包含 `resource`（必填）、`containerName`（可选）与 `divisor`（可选）的 map
- output：可嵌入 `resourceFieldRef` 位置的 YAML 字段片段；缺失或不受支持的 `resource`、非法 `divisor` 时中断
- ownership：选择器负责资源名、`divisor` 校验与字段渲染；本模板负责 map 直传或字符串位次组装

## 代码边界

### `templates/api-resources/Definitions/_DownwardAPIVolumeFile.tpl`

- access：`write`
- operations：`add` 整体契约注释与 `define "definitions.downwardAPIVolumeFile"`
- writable-scopes：新文件全文，包含契约注释与 define 块

### `templates/base/_env.tpl`

- access：`read`
- operations：`consume` `SPLIT.SPACE` 与 `SYS.YAML_QUOTED`

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume` `base.get`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume` `base.string.normalize` 与 `base.isFromYamlError`

### `templates/base/_validate.tpl`

- access：`read`
- operations：`consume` `base.path` 与 `base.fileMode`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume` `base.field`

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume` `base.int` 与 `base.map`

### `templates/api-resources/Definitions/_ObjectFieldSelector.tpl`

- access：`read`
- operations：`consume` `definitions.objectFieldSelector`

### `templates/api-resources/Definitions/_ResourceFieldSelector.tpl`

- access：`read`
- operations：`consume` `definitions.resourceFieldSelector`

### `templates/api-resources/Definitions/_KeyToPath.tpl`

- access：`read`
- operations：`reference` `path` 与 `mode` 的既有归一化规则

### `templates/api-resources/Definitions/_DownwardAPIVolumeSource.tpl`

- access：`read`
- operations：`reference` 字符串引用的输入契约与委托调用

## 验证设计

- 最小有效输入：原生 map，`path` 与 `fieldRef` map（`fieldPath: metadata.name`）；在 `/tmp/sd-kube-chart/` 最小 application Chart 中加载本模板与真实依赖，执行 `helm template`，预期先输出 `fieldRef` 再输出 `path`。
- 较完整有效输入：原生 map，`path`、`mode` 与 `resourceFieldRef` map（`resource`、`containerName`、`divisor`）；以及对应的字符串引用输入（`fieldRef: "metadata.name v1"`、`resourceFieldRef: "limits.cpu app 1m"`）；预期字段顺序与十进制 `mode` 正确。
- 关键失败输入：两个引用并存、两个引用都缺失、引用为空 string 或空 map、`path` 缺失或为绝对路径或存在 `../` 逃逸、`mode` 越界、引用类型非 map/string、`fieldPath` 或 `resource` 不在支持集合；预期渲染中断并包含模板名与字段名。
- 真实依赖：`base.*`、`definitions.objectFieldSelector` 与 `definitions.resourceFieldSelector` 均使用真实模板，不使用同名 fixture。
- fixture 边界：无未实现依赖；`/tmp/sd-kube-chart/` 只承载最小 application Chart 与调用上下文。
