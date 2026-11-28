# definitions.serviceAccountTokenProjection 设计

## 技术目标

- capability：`definitions.serviceAccountTokenProjection`
- artifact-type：`Helm 命名模板`
- target：`templates/api-resources/Definitions/_ServiceAccountTokenProjection.tpl`

## 设计决策

### Decision: 字段顺序与字符串归一化

- requirements：`ServiceAccountTokenProjection 字段渲染`
- choice：按 `audience`、`expirationSeconds`、`path` 顺序处理；`audience` 经 `base.string.normalize` 解码并 trim，非空时以 `quote` 输出；`path` 必填，经 `base.string.normalize` 与 `base.path` 的 `rel` 模式归一化后以 `quote` 输出。
- rationale：官方字段顺序与类型；与 `definitions.keyToPath`、`definitions.podCertificateProjection` 的字符串和路径处理一致。

### Decision: path 逃逸拒绝

- requirements：`ServiceAccountTokenProjection 字段渲染`
- choice：`base.path` 的 `rel` 模式拒绝绝对路径；归一化结果为 `..` 或以 `../` 开头时中断。
- rationale：与 `definitions.keyToPath` 的相对路径边界一致。

### Decision: expirationSeconds 整数与下限

- requirements：`expirationSeconds 取值边界`
- choice：`base.get` 取值后剥离 `SYS.YAML_QUOTED` 并 trim，空值省略；非空经 `base.int` 归一化、`base.int.range` 校验最小 600，再以 `base.int` 输出。
- rationale：官方类型为 integer 且最小 600 秒；与 `definitions.podCertificateProjection` 的 `maxExpirationSeconds` 处理模式一致。

## 依赖契约

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
- output：YAML 常量 Map；本模板读取 `SYS.YAML_QUOTED`
- ownership：base 负责常量声明；本模板负责剥离 `expirationSeconds` 外层引号

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 返回的 YAML 标量文本 string
- output：解码后的 string；非法 YAML 或非 string 标量时中断
- ownership：base 负责标量解码；本模板负责 trim、必填与空值判断

### Dependency: `base.path`

- availability：`existing`
- source：`templates/base/_validate.tpl`
- operation：`consume`
- input：`list [path, "rel"]`
- output：归一化后的相对路径 string；绝对路径时中断
- ownership：base 负责 trim、`.`/`..` 段归一化和绝对路径拒绝；本模板负责逃逸检查与渲染

### Dependency: `base.int`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：int、int64、float64 或整数字符串
- output：整数 string；非法输入时中断
- ownership：base 负责类型归一化；本模板负责空值判断与范围校验调用

### Dependency: `base.int.range`

- availability：`existing`
- source：`templates/base/_validate.tpl`
- operation：`consume`
- input：`list [数值, 600]`
- output：不小于 600 的数值；低于下限时中断
- ownership：base 负责数值区间校验；本模板负责字段输出

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [键名, 已归一化值, 渲染模板]`
- output：YAML 键值对 string；值为空时不输出
- ownership：base 负责序列化；本模板只在字段生效时调用

## 代码边界

### `templates/api-resources/Definitions/_ServiceAccountTokenProjection.tpl`

- access：`write`
- operations：`add` `definitions.serviceAccountTokenProjection`
- writable-scopes：`definitions.serviceAccountTokenProjection` 定义块及其紧邻契约注释

### `templates/api-resources/Definitions/_KeyToPath.tpl`

- access：`read`
- operations：参考相对路径归一化与 `..` 逃逸拒绝语义

### `templates/api-resources/Definitions/_PodCertificateProjection.tpl`

- access：`read`
- operations：参考相对路径与整数范围字段处理模式

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume` `base.get`

### `templates/base/_env.tpl`

- access：`read`
- operations：`consume` `base.env`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume` `base.string.normalize`

### `templates/base/_validate.tpl`

- access：`read`
- operations：`consume` `base.path`、`base.int.range`

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume` `base.int`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume` `base.field`

## 验证设计

- 真实依赖：`base.*` 均存在，不提供同名 fixture。
- 最小有效：`{path: "token"}` 仅输出 `path`。
- 较完整有效：`audience`、`expirationSeconds: 600`、`path` 同时提供，按 `audience`、`expirationSeconds`、`path` 顺序输出。
- 空值：缺失或空字符串的 `audience`、`expirationSeconds` 不输出。
- 归一化：`path` 为 `a/../b` 时输出 `b`，与 `definitions.keyToPath` 一致。
- 关键失败：`path` 缺失、绝对路径、归一化后为 `..` 或 `../` 开头；`expirationSeconds` 小于 600 或非整数；`audience` 非字符串。
- 验证在 `/tmp/sd-kube-chart/` 新建的最小 application Chart 中执行，真实加载上述依赖。
