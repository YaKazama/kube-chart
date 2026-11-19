# definitions.grpcAction 设计

## 技术目标

- capability：`definitions.grpcAction`
- artifact-type：`Helm named template`
- target：`definitions.grpcAction`

## 设计决策

### Decision: 字段取值与输出顺序

- requirements：`字段输出与顺序`
- choice：`port` 经 `base.get` 取值后按 YAML 标量分派，`service` 经 `base.get` 与 `base.string.normalize` 取值并 trim；按 `port`、`service` 顺序完成各自闭环并调用 `base.field` 输出。
- rationale：统一继承 `base.get` 的上下文优先级与别名行为，并按官方字段顺序直接渲染。

### Decision: port 类型分派与命名端口校验

- requirements：`port 校验`
- choice：`base.get` 输出 trim 后为空即中断；否则以 `fromYaml (printf "v: %s" ...)` 回读原生类型，无小数 `float64` 归一为 `int` 后与 `int`、`int64` 一同委托 `base.port` 校验 1-65535 并以 `base.int` 输出；string 分支先判空，纯数字字符串委托 `base.port`，其余按 15 字符上限与 `K8S.IANA_SVC_NAME`、`K8S.IANA_SVC_NAME_LETTER` 校验命名端口并以带引号字符串输出；其他类型中断。
- rationale：`base.port` 只做数值范围校验，不能承担命名端口与类型门禁；`float64` 归一仅适配 Helm 4 的 YAML 数值表示。

### Decision: port 实现同步复现

- requirements：`port 校验`
- choice：在 `definitions.grpcAction` 内以等价语句复现 `definitions.httpGetAction` 的 `port` 处理，只消费 `base.*` 公共能力；不通过 `include` 调用 `definitions.httpGetAction`，不新增共享 base 模板，也不修改已实现的 `definitions.httpGetAction`。
- rationale：`definitions.httpGetAction` 只输出完整 HTTPGetAction 片段，无法单独提供 `port` 供复用；draft 要求复用其实现方式而非调用子模板。

### Decision: service 归一与省略

- requirements：`service 输出`
- choice：`base.get` 取值后经 `base.string.normalize` 还原为 string 并 trim；trim 后为空则不输出，非空时调用 `base.field` 以 `quote` 输出。
- rationale：`base.string.normalize` 把 `null` 与空输入还原为空串、对非 string 的其他标量及结构中断，因此缺失、`null`、空串与纯空白统一按未设置省略，布尔、数值、map、list 由依赖层中断。

## 依赖契约

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：空字符串 `""`
- output：可由 `fromYaml` 恢复的常量 Map；使用既有 `TYPES.POSITIVE_INT`、`K8S.IANA_SVC_NAME`、`K8S.IANA_SVC_NAME_LETTER`，键值保持不变
- ownership：依赖层负责常量集中声明；本模板负责常量读取与业务校验

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, 点分路径]`
- output：YAML 字符串；字段缺失时为空输出
- ownership：依赖层负责上下文优先级、别名与序列化；本模板负责业务字段校验

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 输出的 YAML 标量文本
- output：string；`null` 与空输入返回空串，非 string 标量或非法 YAML 中断
- ownership：依赖层负责标量解码；本模板负责 trim 与省略判断

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 返回值
- output：布尔字符串
- ownership：依赖层负责识别解析错误形态；本模板负责在识别错误后中断

### Dependency: `base.port`

- availability：`existing`
- source：`templates/base/_validate.tpl`
- operation：`consume`
- input：int、int64 或纯数字字符串
- output：位于 1-65535 的 int；非法数值中断
- ownership：依赖层负责数值范围校验；本模板负责类型分派与命名端口校验

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [键名, 已归一化值, 渲染模板]`
- output：YAML 键值片段；空值不输出
- ownership：依赖层负责最终字段渲染；本模板负责生效条件与类型归一化

### Dependency: `base.int`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：int、int64 或整数字符串
- output：十进制整数文本；非法类型中断
- ownership：依赖层只负责整数渲染

## 代码边界

### `templates/api-resources/Definitions/_GRPCAction.tpl`

- access：`write`
- operations：`add definitions.grpcAction`
- writable-scopes：新文件的完整内容

### `templates/base/_env.tpl`

- access：`read`
- operations：`base.env`
- writable-scopes：无

### `templates/base/_get.tpl`

- access：`read`
- operations：`base.get`
- writable-scopes：无

### `templates/base/_convert.tpl`

- access：`read`
- operations：`base.string.normalize`、`base.isFromYamlError`
- writable-scopes：无

### `templates/base/_validate.tpl`

- access：`read`
- operations：`base.port`
- writable-scopes：无

### `templates/base/_field.tpl`

- access：`read`
- operations：`base.field`
- writable-scopes：无

### `templates/base/_types.tpl`

- access：`read`
- operations：`base.int`
- writable-scopes：无

## 验证设计

- 最小有效：仅提供 `port: 8080`，输出只含数值 `port`；`service` 缺失、`null`、空字符串或仅含空白时输出不含 `service` 键。
- 较完整有效：`port` 为命名端口 `grpc` 且提供 `service`，验证 `port` 在前、命名端口为字符串、`service` 输出；`port` 为 `"8080"` 时验证数值归一。
- 关键失败：`port` 缺失、`null`、空字符串、`0`、`65536`、带小数、布尔、map、list、非法命名端口；`service` 为布尔、数值、map、list。
- 依赖边界：`base.*` 均为真实实现，直接在 `/tmp/` 最小 application Chart 中加载当前模板与真实依赖执行 `helm template`，不使用同名 fixture。
