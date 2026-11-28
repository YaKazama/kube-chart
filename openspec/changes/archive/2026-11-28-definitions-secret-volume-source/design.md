# definitions.secretVolumeSource 设计

## 技术目标

- capability：`definitions.secretVolumeSource`
- artifact-type：`Helm 命名模板`
- target：`templates/api-resources/Definitions/_SecretVolumeSource.tpl`

## 设计决策

### Decision: 对齐 ConfigMapVolumeSource 字段处理

- requirements：`SecretVolumeSource 字段渲染`
- choice：按 `defaultMode`、`items`、`optional`、`secretName` 顺序处理；`defaultMode` 剥离 YAML 引号后交给 `base.fileMode`；`optional` 剥离引号并 trim 后省略空值；`secretName` 解码、trim、判空并按 `1123sub` 校验后以 `quote` 输出。
- rationale：两者官方字段结构一致，同域 `definitions.configMapVolumeSource` 已覆盖相同的取值、归一化和失败边界。

### Decision: items 字符串元素清洗与委托

- requirements：`items 解析、委托与去重`
- choice：`items` 经 `base.get` 与 `fromYamlArray` 恢复；逐个元素处理，string 元素 trim 后跳过空白，按 `base.env` 的 `K8S.VOLUME.KEY_TO_PATH_ITEM` 匹配 `<key> <path> [mode]` 并构造 `{key, path, mode?}`；map 元素原样使用；其他类型中断；每个元素委托 `definitions.keyToPath`，输出经 `fromYaml` 解析，空结果剔除，`mustUniq` 去重，非空时用 `base.slice` 输出。
- rationale：`definitions.volume` 的 `secret` 简写把 items 作为原始字符串数组下传；去重去空为当前规格要求，空结果剔除与 `mustUniq` 由 Helm 函数完成。

### Decision: secretName 校验

- requirements：`SecretVolumeSource 字段渲染`
- choice：`secretName` 必填且非空，按 RFC1123 Subdomain 校验，不做小写归一化。
- rationale：与 `definitions.secretProjection`、`definitions.secretEnvSource` 及 `definitions.configMapVolumeSource` 的名称边界一致。

## 依赖契约

### Dependency: `definitions.keyToPath`

- availability：`existing`
- source：`templates/api-resources/Definitions/_KeyToPath.tpl`
- operation：`consume`
- input：原生 map，包含必填 `key`、`path` 和可选 `mode`
- output：YAML 字段片段 string；非法 `key`、`path` 或 `mode` 时中断
- ownership：子模板负责 KeyToPath 字段校验与渲染；本模板负责元素清洗、容器类型、空结果剔除、去重与数组输出

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, 点分路径]`；不传可选参数
- output：可解析的 YAML string；路径缺失时为空输出
- ownership：base 负责多层取值与序列化；本模板负责字段生效判断

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：空字符串占位
- output：YAML 常量 Map；本模板读取 `SYS.YAML_QUOTED` 与 `K8S.VOLUME.KEY_TO_PATH_ITEM`
- ownership：base 负责常量声明；本模板负责剥离引号与匹配 items 字符串格式

### Dependency: `base.fileMode`

- availability：`existing`
- source：`templates/base/_validate.tpl`
- operation：`consume`
- input：八进制/十进制的数值或字符串
- output：十进制 int；非法文件模式时中断
- ownership：base 负责文件权限位校验与归一化；本模板负责空值省略与渲染

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 返回的 YAML 标量文本 string
- output：解码后的 string；非法 YAML 或非 string 标量时中断
- ownership：base 负责标量解码；本模板负责 trim、必填与空值判断

### Dependency: `base.rfc`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：`list [secretName, "1123sub"]`
- output：校验通过的 string；不合法时中断
- ownership：base 负责 RFC1123 Subdomain 与长度校验；本模板负责空值判断与调用顺序

### Dependency: `base.bool`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：bool 或字面量 `"true"`、`"false"`
- output：布尔字符串；其他值中断
- ownership：base 负责类型校验；本模板负责空值省略与显式 `false` 输出

### Dependency: `base.int`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：`base.fileMode` 返回的十进制 int
- output：整数 string；非法输入时中断
- ownership：base 负责整数序列化；本模板通过 `base.field` 选择该渲染模板

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [键名, 已归一化值, 渲染模板]`
- output：YAML 键值对 string；值为空时不输出
- ownership：base 负责序列化；本模板只在字段生效时调用

### Dependency: `base.slice`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：slice
- output：YAML 数组 string；非 slice 时中断
- ownership：base 负责类型门禁与序列化；本模板负责在非空时调用

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 返回值
- output：`"true"` 或 `"false"`
- ownership：base 负责识别 Helm 解析错误形态；本模板负责决定失败

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：任意 `fromYaml` 返回值
- output：`"true"` 或 `"false"`
- ownership：base 负责识别错误 map；本模板负责决定失败

## 代码边界

### `templates/api-resources/Definitions/_SecretVolumeSource.tpl`

- access：`write`
- operations：`add` `definitions.secretVolumeSource`
- writable-scopes：`definitions.secretVolumeSource` 定义块及其紧邻契约注释

### `templates/api-resources/Definitions/_ConfigMapVolumeSource.tpl`

- access：`read`
- operations：参考同域字段处理、string items 解析与失败边界模式

### `templates/api-resources/Definitions/_KeyToPath.tpl`

- access：`read`
- operations：`consume` `definitions.keyToPath`

### `templates/api-resources/Definitions/_Volume.tpl`

- access：`read`
- operations：确认 `secret` 简写向 `definitions.secretVolumeSource` 下传的字段与 items 形态

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume` `base.get`

### `templates/base/_env.tpl`

- access：`read`
- operations：`consume` `base.env`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume` `base.string.normalize`、`base.isFromYamlError`、`base.isFromYamlArrayError`

### `templates/base/_validate.tpl`

- access：`read`
- operations：`consume` `base.fileMode`

### `templates/base/_k8s.tpl`

- access：`read`
- operations：`consume` `base.rfc`

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume` `base.bool`、`base.int`、`base.slice`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume` `base.field`

## 验证设计

- 真实依赖：`definitions.keyToPath` 与全部 `base.*` 均存在，不提供同名 fixture。
- 最小有效：`{secretName: "app-secret"}` 仅输出 `secretName`。
- 完整有效：`defaultMode: "0644"`、string 与 map 混合 items、`optional: false`、合法 `secretName`，按 `defaultMode`、`items`、`optional`、`secretName` 顺序输出。
- 去重去空：重复条目保留首个，空白字符串与空结果剔除；空数组或全空白不输出 `items`。
- 关键失败：`secretName` 缺失或非法；`items` 非数组、元素类型非法、string 格式非法、KeyToPath 字段非法；`optional` 非法。
- 验证在 `/tmp/sd-kube-chart/` 新建的最小 application Chart 中执行，真实加载上述依赖。
