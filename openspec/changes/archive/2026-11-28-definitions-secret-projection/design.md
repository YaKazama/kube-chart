# definitions.secretProjection 设计

## 技术目标

- capability：`definitions.secretProjection`
- artifact-type：`Helm 命名模板`
- target：`templates/api-resources/definitions/_SecretProjection.tpl`

## 设计决策

### Decision: 对齐 ConfigMapProjection 字段处理

- requirements：`SecretProjection 字段渲染`
- choice：按 `definitions.configMapProjection` 的既有模式实现，字段顺序为 `items`、`name`、`optional`，只读取这三个键。
- rationale：两者官方字段集合与类型一致，同域现有实现已覆盖相同的取值、归一化和失败边界。

### Decision: items 委托与集合归一

- requirements：`SecretProjection items 委托与去重`
- choice：`base.get` 取值后经 `fromYamlArray` 恢复并检查 `base.isFromYamlArrayError`；逐项要求原生 map，调用 `definitions.keyToPath`，对输出 `fromYaml` 并检查 `base.isFromYamlError`，剔除空结果，`mustUniq` 去重，非空时用 `base.slice` 输出。
- rationale：规格要求委托、去重、去空和非法中断；`definitions.keyToPath` 已存在并负责条目内字段校验。

### Decision: name 与 optional 归一化

- requirements：`SecretProjection 字段渲染`
- choice：`name` 经 `base.get` 与 `base.string.normalize` 解码、trim、判空，`base.rfc` 的 `1123sub` 校验后以 `quote` 渲染；`optional` 剥离 `SYS.YAML_QUOTED` 并 trim，空值省略，其余交给 `base.bool`，显式 `false` 输出。
- rationale：与 `definitions.secretEnvSource`、`definitions.configMapProjection` 的既有类型与失败边界一致。

## 依赖契约

### Dependency: `definitions.keyToPath`

- availability：`existing`
- source：`templates/api-resources/definitions/_KeyToPath.tpl`
- operation：`consume`
- input：原生 map，包含必填 `key`、`path` 和可选 `mode`
- output：YAML 字段片段 string；非法 `key`、`path` 或 `mode` 时中断
- ownership：子模板负责 KeyToPath 字段校验与渲染；本模板负责 items 容器类型、逐项委托、空结果剔除、去重与数组输出

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, 点分路径]`；不传可选参数
- output：可 `fromYaml` 解析的 YAML string；路径缺失时为空输出
- ownership：base 负责多层取值与序列化；本模板负责字段生效判断

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：空字符串占位
- output：YAML 常量 Map；本模板读取 `SYS.YAML_QUOTED`
- ownership：base 负责常量声明；本模板负责剥离 optional 外层引号

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 返回的 YAML 标量文本 string
- output：解码后的 string；非法 YAML 或非 string 标量时中断
- ownership：base 负责标量解码；本模板负责 trim 与必填判断

### Dependency: `base.rfc`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：`list [name, "1123sub"]`
- output：校验通过的 string；不合法时中断
- ownership：base 负责 RFC1123 Subdomain 与长度校验；本模板负责空值判断与调用顺序

### Dependency: `base.bool`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：bool 或字面量 `"true"`、`"false"`
- output：布尔字符串；其他值中断
- ownership：base 负责类型校验；本模板负责空值省略与显式 `false` 输出

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

### `templates/api-resources/definitions/_SecretProjection.tpl`

- access：`write`
- operations：`add` `definitions.secretProjection`
- writable-scopes：`definitions.secretProjection` 定义块及其紧邻契约注释

### `templates/api-resources/definitions/_KeyToPath.tpl`

- access：`read`
- operations：`consume` `definitions.keyToPath`

### `templates/api-resources/definitions/_ConfigMapProjection.tpl`

- access：`read`
- operations：参考同域字段处理与失败边界模式

### `templates/api-resources/definitions/_VolumeProjection.tpl`

- access：`read`
- operations：确认 `secret` 字段占位与上层包装边界

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume` `base.get`

### `templates/base/_env.tpl`

- access：`read`
- operations：`consume` `base.env`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume` `base.string.normalize`、`base.isFromYamlError`、`base.isFromYamlArrayError`

### `templates/base/_k8s.tpl`

- access：`read`
- operations：`consume` `base.rfc`

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume` `base.bool`、`base.slice`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume` `base.field`

## 验证设计

- 真实依赖：`definitions.keyToPath` 与全部 `base.*` 均存在，不提供同名 fixture。
- 最小有效：`{name: "app-secret"}` 仅输出 `name`。
- 较完整有效：`items` 含两个不同条目、`name` 合法、`optional: false`，按 `items`、`name`、`optional` 顺序输出且 `optional` 为 `false`。
- 去重去空：`items` 含完全重复条目和空结果条目时保留首个并剔除空结果；空数组或全空结果不输出 `items`。
- 关键失败：`items` 非数组、条目非 map、条目 KeyToPath 字段非法、`name` 缺失或非 RFC1123 Subdomain、`optional` 非布尔值时中断。
- 验证在 `/tmp/sd-kube-chart/` 新建的最小 application Chart 中执行，真实加载上述依赖。
