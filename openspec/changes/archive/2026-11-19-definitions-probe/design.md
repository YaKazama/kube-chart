# definitions.probe 设计

## 技术目标

- capability：`definitions.probe`
- artifact-type：`Helm named template`
- target：`definitions.probe`

## 设计决策

### Decision: 动作键收集与互斥

- requirements：`动作互斥`
- choice：在固定顺序 `exec`、`grpc`、`httpGet`、`tcpSocket` 上以 `hasKey` 收集存在的键，数量大于 1 时中断，数量为 1 时取该键为生效动作。
- rationale：draft 已锁定按 key 是否存在判定，`null` 也算已提供；`base.get` 对缺失与 `null` 均返回空输出，无法区分两者，因此动作存在性判定使用原生键检测，与 `definitions.lifecycleHandler` 的动作收集方式一致。动作字段不参与别名识别，规格未定义的字段静默忽略。

### Decision: 生效动作空值与动作值派生

- requirements：`生效动作空值`
- choice：取得生效动作的原始值后，值为 `null` 时中断，值为空 map 时中断，其余情况进入形态归一。
- rationale：`exec: {}`、`grpc: {}` 等空 map 无法构成有效动作；在归一前统一拦截可避免重复分支。

### Decision: 动作形态归一

- requirements：`动作委托与简写解析`
- choice：`map` 原样作为子模板上下文；`exec` 的 string array 校验元素全为 string 后构造 `command`；`grpc`、`httpGet`、`tcpSocket` 的 string 先用对应正则全量匹配，再由捕获组构造上下文 map；其他类型中断。
- rationale：与 `definitions.lifecycleHandler` 的归一方式保持一致，父层只解析自身声明的简写形态。

### Decision: 动作子模板委托

- requirements：`动作委托与简写解析`
- choice：由同文件私有模板 `definitions.probe.render` 统一执行 `include`、`fromYaml`、`base.isFromYamlError` 判断，并在结果非空时以动作键调用 `base.field` + `base.map` 输出。
- rationale：四个动作的委托出口完全相同，收敛为单处避免四份等价分支。

### Decision: grpc 简写解析

- requirements：`动作委托与简写解析`
- choice：使用 `base.env` 新增的 `K8S.GRPC_ACTION` 单条全量正则捕获可选 `service` 与必填 `port`，分隔符为空格或逗号，语义对齐既有 `SPLIT.SPACE_COMMA` 的 `[,\s]+`；解析结果构造 `dict "service" ... "port" ...`，`service` 缺失时传入空字符串，由其子模板决定是否输出。
- rationale：draft 锁定的格式为 `[service] <port>`，分隔符为空格或逗号，与既有 `SPLIT.SPACE_COMMA` 语义一致；`service` 与 `port` 同时传入可对齐 `definitions.tcpSocketAction` 对可选字段的处理方式。

### Decision: httpGet 与 tcpSocket 简写复用既有常量

- requirements：`动作委托与简写解析`
- choice：复用 `K8S.LIFECYCLE_HANDLER.HTTP_GET`、`K8S.LIFECYCLE_HANDLER.TCP_SOCKET`、`SPLIT.COMMA`、`SPLIT.SPACE_COMMA`，不复制或改写表达式；`headers` 的逗号分组与空格分词与 `definitions.lifecycleHandler` 保持一致。
- rationale：动作简写格式与 `definitions.lifecycleHandler` 完全相同，重复定义同一表达式违反正则集中原则。

### Decision: integer 字段闭环

- requirements：`integer 字段`
- choice：`base.get` 取值并 `trim`；`fromYaml (printf "v: %s" ...)` 回读原生类型；`kindOf` 只允许 `int`、`int64`、`float64`；`float64` 以 `floor` 等值判定整数语义；最终 `base.field` + `base.int` 输出十进制整数。六个字段由同文件私有模板 `definitions.probe.integer` 复用。
- rationale：`base.int` 接受整数字符串并对 `float64` 四舍五入，不能作为整数类型门禁，因此类型与小数判定前置；`float64` 分支直接交给 `base.int` 渲染，不额外转 `int` 以避免精度截断。

### Decision: 字段顺序

- requirements：`字段输出与顺序`
- choice：主模板按 `exec`、`failureThreshold`、`grpc`、`httpGet`、`initialDelaySeconds`、`periodSeconds`、`successThreshold`、`tcpSocket`、`terminationGracePeriodSeconds`、`timeoutSeconds` 顺序逐块书写，整数字段块调用 `definitions.probe.integer`。
- rationale：按官方字段顺序直接渲染，动作与阈值交错，无法用单次 `range` 表达。

## 依赖契约

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`update`
- input：空字符串 `""`
- output：可由 `fromYaml` 恢复的常量 Map；新增 `K8S.GRPC_ACTION: "^\\s*(?:([^\\s,]+)[,\\s]+)?([^\\s,]+)\\s*$"`，既有键保持不变
- ownership：本 change 只新增 grpc 简写常量；常量读取与匹配由本模板负责

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, 点分路径]`
- output：YAML 字符串；字段缺失时为空输出
- ownership：依赖层负责上下文优先级、别名与序列化；本模板负责 integer 字段的类型与整数语义校验

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 返回值
- output：布尔字符串
- ownership：依赖层负责识别解析错误形态；本模板负责在识别错误后中断

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
- input：int、int64 或 float64
- output：十进制整数文本；非法类型中断
- ownership：依赖层只负责整数渲染；整数语义由本模板前置判定

### Dependency: `definitions.execAction`

- availability：`existing`
- source：`templates/api-resources/Definitions/_ExecAction.tpl`
- operation：`consume`
- input：包含 `command` 的 map 上下文
- output：ExecAction YAML 字段片段；`command` 缺失时中断
- ownership：依赖层负责 `command` 的校验与渲染；本模板只负责动作形态归一与委托

### Dependency: `definitions.httpGetAction`

- availability：`existing`
- source：`templates/api-resources/Definitions/_HTTPGetAction.tpl`
- operation：`consume`
- input：包含 `host`、`httpHeaders`、`path`、`port`、`scheme` 的 map 上下文
- output：HTTPGetAction YAML 字段片段；`port` 缺失或非法时中断
- ownership：依赖层负责各字段校验与渲染；本模板只负责动作形态归一与委托

### Dependency: `definitions.tcpSocketAction`

- availability：`existing`
- source：`templates/api-resources/Definitions/_TCPSocketAction.tpl`
- operation：`consume`
- input：包含 `host` 与 `port` 的 map 上下文
- output：TCPSocketAction YAML 字段片段；`port` 缺失或非法时中断
- ownership：依赖层负责各字段校验与渲染；本模板只负责动作形态归一与委托

### Dependency: `definitions.grpcAction`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：包含 `service` 与 `port` 的 map 上下文
- output：GRPCAction YAML map 片段；非空 map
- ownership：本 change 只固定调用边界，不创建模板或校验 GRPCAction 字段

## 代码边界

### `templates/api-resources/Definitions/_Probe.tpl`

- access：`write`
- operations：`add definitions.probe`、`add definitions.probe.render`、`add definitions.probe.integer`
- writable-scopes：新文件的完整内容

### `templates/base/_env.tpl`

- access：`write`
- operations：`K8S.GRPC_ACTION` 的 add
- writable-scopes：`K8S` map 内新增的 `GRPC_ACTION` 键及其前置注释

### `templates/base/_get.tpl`

- access：`read`
- operations：`base.get`
- writable-scopes：无

### `templates/base/_convert.tpl`

- access：`read`
- operations：`base.isFromYamlError`
- writable-scopes：无

### `templates/base/_field.tpl`

- access：`read`
- operations：`base.field`
- writable-scopes：无

### `templates/base/_types.tpl`

- access：`read`
- operations：`base.int`
- writable-scopes：无

### `templates/api-resources/Definitions/_ExecAction.tpl`

- access：`read`
- operations：`definitions.execAction`
- writable-scopes：无

### `templates/api-resources/Definitions/_HTTPGetAction.tpl`

- access：`read`
- operations：`definitions.httpGetAction`
- writable-scopes：无

### `templates/api-resources/Definitions/_TCPSocketAction.tpl`

- access：`read`
- operations：`definitions.tcpSocketAction`
- writable-scopes：无

## 验证设计

- 最小有效：仅提供 `failureThreshold` 与 `timeoutSeconds`，验证整数渲染与字段省略。
- 较完整有效：`httpGet` 原生 map 与全部整数阈值混用，验证官方字段顺序；`exec` string array、`httpGet` 含 headers 的字符串、`tcpSocket` 字符串、`grpc` 字符串与原生 map 分别验证动作归一与委托。
- 关键失败：多动作并存、`null` 动作与 `null` 参与互斥、空 map 动作、非法简写、非整数类型的阈值。
- 依赖边界：`base.*` 与三个已实现 Action 模板使用真实依赖；`definitions.grpcAction` 当前 `unavailable`，只在 `/tmp/` 最小 application Chart 中提供同名 fixture，验证仅覆盖本模板的调用与形态归一，不作为 GRPCAction 集成通过证据。
