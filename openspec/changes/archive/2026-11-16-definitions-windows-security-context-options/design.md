# definitions.windowsSecurityContextOptions 设计

## 技术目标

- capability：`definitions.windowsSecurityContextOptions`
- artifact-type：共享结构模板
- target：`templates/api-resources/Definitions/_WindowsSecurityContextOptions.tpl`

## 设计决策

### Decision: 按 API 字段顺序逐字段闭环

- requirements：`WindowsSecurityContextOptions 字段片段渲染`
- choice：在同一 `define` 内按 `gmsaCredentialSpec`、`gmsaCredentialSpecName`、`hostProcess`、`runAsUserName` 的官方顺序逐字段完成“取值 → 归一 → 字段生效判断 → `base.field` 渲染”闭环，不引入遍历列表或循环内类型分支。
- rationale：四个字段中 `hostProcess` 与其余字符串字段类型不同，逐字段闭环避免同一次循环内按字段名做互斥类型分支；与同域 `definitions.podSecurityContext` 处理异质字段的既有写法一致。三个字符串字段共用同一闭环形态，差异仅在字段名与变量名。

### Decision: 字符串字段归一与引号输出

- requirements：`WindowsSecurityContextOptions 字段片段渲染`
- choice：字符串字段通过 `base.get` 取值、`base.string.normalize` 解码后 `trim`，结果非空才交给 `base.field` 并以 `quote` 渲染。
- rationale：与同域 `definitions.seLinuxOptions` 保持一致，复用既有取值与标量解码能力；非 string 输入由 `base.string.normalize` 中断；引号输出保证 `on`、`yes`、`true` 等文本不改变 YAML 类型。

### Decision: hostProcess 仅输出 true

- requirements：`hostProcess 布尔语义`
- choice：取 `base.get` 原始输出后先按 `base.env` 的 `SYS.YAML_QUOTED` 剥离 YAML 外层引号并 `trim`，再交给 `base.bool`；仅当结果为 `true` 时通过 `base.field` 输出。
- rationale：`base.bool` 是既有唯一布尔门禁，接受原生布尔与字面量 `"true"`、`"false"`；剥离引号沿用 `definitions.podSecurityContext` 对 `runAsNonRoot` 的既有做法；`false` 表示未启用，按规格不输出。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <上下文 map> "<字段名>"`。
- output：可 `fromYaml` 解析的 YAML 字符串；字段缺失或为 null 时为空内容。
- ownership：`base.get` 负责数据源优先级、同级 `<字段>Alias` 识别与序列化；本模板负责字段顺序、空值判定与输出决策。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 原始输出的 YAML 标量文本。
- output：解码后的 string；空输入返回空字符串；非 string 中断渲染。
- ownership：`base.string.normalize` 负责标量解码与 string 类型门禁；本模板负责空值判定与字段输出。

### Dependency: `base.bool`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：原生布尔或字面量字符串 `"true"`、`"false"`。
- output：`"true"` 或 `"false"`；其他类型或字面量中断渲染。
- ownership：`base.bool` 负责布尔类型门禁；本模板负责仅 `true` 才输出的渲染决策。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [key, 已归一化值, 渲染模板]`；字符串字段使用 `quote`，布尔字段使用 `base.bool`。
- output：单行键值对或块标量 YAML 字符串；值为空时不输出。
- ownership：`base.field` 负责单键渲染与引号处理；本模板负责字段生效判断。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：`""`。
- output：可 `fromYaml` 解析的常量 Map。
- ownership：`base.env` 负责常量定义；本模板只读取 `SYS.YAML_QUOTED`，不新增或改写常量。

## 代码边界

### `templates/api-resources/Definitions/_WindowsSecurityContextOptions.tpl`

- access：`write`
- operations：新增 `define "definitions.windowsSecurityContextOptions"`、整体契约注释、各字段注释与字段处理闭环。
- writable-scopes：整个新增文件，包含上述 `define` 及注释。

### `templates/base/_get.tpl`

- access：`read`
- operations：核对 `base.get` 的入参顺序、别名开关与缺失字段的返回边界。

### `templates/base/_convert.tpl`

- access：`read`
- operations：核对 `base.string.normalize` 的入参形态、空输入返回与失败边界。

### `templates/base/_types.tpl`

- access：`read`
- operations：核对 `base.bool` 接受的布尔形态与失败消息。

### `templates/base/_field.tpl`

- access：`read`
- operations：核对 `base.field` 的参数数量、`quote` 语义与空值输出条件。

### `templates/base/_env.tpl`

- access：`read`
- operations：核对 `SYS.YAML_QUOTED` 的运行时表达式。

## 验证设计

- 最小有效：仅提供 `gmsaCredentialSpecName`，输出只含该字段。
- 较完整有效：四个字段齐全且 `hostProcess` 为 `true`，输出顺序固定，字符串字段为字符串、`hostProcess` 为布尔。
- 空值与缺省：全部缺省时输出空内容；字符串字段为空字符串或纯空白时不产生键。
- 关键失败：`hostProcess` 为 `"yes"` 或数值、字符串字段为 map 时渲染中断。
- 依赖边界：在 `/tmp/` 最小 application Chart 中加载真实 library Chart，`base.*` 使用真实实现，不使用同名 fixture。
