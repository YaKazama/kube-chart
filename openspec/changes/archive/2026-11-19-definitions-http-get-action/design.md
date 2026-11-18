# definitions.httpGetAction 设计

## 技术目标

- capability：`definitions.httpGetAction`
- artifact-type：`Helm named template`
- target：`definitions.httpGetAction`

## 设计决策

### Decision: 字段取值与输出顺序

- requirements：`字段输出与顺序`
- choice：通过 `base.get` 取得各字段，可选字符串字段经 `base.string.normalize` 还原并 trim；按 `host`、`httpHeaders`、`path`、`port`、`scheme` 顺序完成各自闭环并调用 `base.field` 输出。
- rationale：统一继承 `base.get` 的上下文优先级与别名行为，并按官方字段顺序直接渲染。

### Decision: host 联合校验

- requirements：`host 校验`
- choice：扩展 `base.net` 的 `dns` 模式，使用 `NET.IPV4`、`NET.IPV6` 与 `NET.DOMAIN_NAME` 校验严格 IP 地址或域名，拒绝 CIDR；`definitions.httpGetAction` 对非空 `host` 调用该模式。
- rationale：复用公共网络校验能力，并满足 `host` 对 IPv4 与 IPv6 的明确要求。

### Decision: httpHeaders 双形态归一与委托

- requirements：`httpHeaders 解析与委托`
- choice：先以 `fromYamlArray` 恢复并排除解析错误；首个元素为 map 时要求全部为含 `name`、`value` 的 map，首个元素为 string 时要求全部为 string，并以 `SPLIT.SPACE` 拆分且要求恰好两个非空 token；每个 map 传给 `definitions.httpHeader`，恢复输出后排除 YAML 错误并按顺序收集非空 map，最终以 `base.slice` 输出。
- rationale：以单一分支确定数组形态，避免逐元素混合处理；string array 的 `name value` 构造与子模板委托保持顺序稳定。

### Decision: path 绝对 URI 归一

- requirements：`path 校验`
- choice：非空 `path` 委托 `base.path` 的 `uri` 模式，保留其 trim、`.`/`..` 清理与绝对路径门禁。
- rationale：复用既有路径能力，不在本模板复制路径正则或归一化逻辑。

### Decision: port 数值与命名分派

- requirements：`port 校验`
- choice：解析 `base.get` 输出的 YAML 标量；Helm 4 `fromYaml` 返回的无小数 `float64` 归一为 `int`，带小数 `float64` 仍按非法类型中断；归一后的 `int`、`int64` 和纯数字字符串委托 `base.port`，命名端口使用 `K8S.IANA_SVC_NAME`、`K8S.IANA_SVC_NAME_LETTER` 与 15 字符长度上限完成完整规则校验；数值以 `base.int` 输出，名称以带引号字符串输出。
- rationale：数值范围复用既有校验，命名端口按 Kubernetes `IsValidPortName` 完整规则实现；`float64` 归一仅适配 Helm 4 的 YAML 数值表示，并避免 `true`、`on` 等合法端口名被 YAML 解析为其他类型。

### Decision: scheme 大小写归一

- requirements：`scheme 归一化`
- choice：非空 `scheme` 先 trim 再转全大写，随后通过 `base.field` 的允许值列表限制为 `HTTP`、`HTTPS` 并以带引号字符串输出。
- rationale：统一完成大小写归一与枚举门禁，非法值在渲染前中断。

## 依赖契约

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`update`
- input：空字符串 `""`
- output：可由 `fromYaml` 恢复的常量 Map；新增 `SPLIT.SPACE: " +"`、`K8S.IANA_SVC_NAME: "^[a-z0-9]+(-[a-z0-9]+)*$"`、`K8S.IANA_SVC_NAME_LETTER: "[a-z]"`，既有键保持不变
- ownership：本 change 只新增协议分隔与 IANA 端口名常量；模板取值与解析由调用方负责

### Dependency: `base.net`

- availability：`existing`
- source：`templates/base/_validate.tpl`
- operation：`update`
- input：`list [string, "dns"]`
- output：校验通过的原始字符串；IPv4、IPv6 或域名之外的值中断
- ownership：本 change 将 `dns` 模式从 IPv4/CIDR 扩展为严格 IPv4、IPv6 或域名；`ip` 与 `domain` 模式保持不变

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, 点分路径]` 及既有可选参数
- output：YAML 字符串；字段缺失时为空输出
- ownership：依赖层负责上下文优先级、别名与序列化；本模板负责业务字段校验

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 输出的 YAML 标量文本
- output：string；非 string 标量或非法 YAML 中断
- ownership：依赖层负责标量解码；本模板负责 trim 与业务校验

### Dependency: `base.path`

- availability：`existing`
- source：`templates/base/_validate.tpl`
- operation：`consume`
- input：`list [string, "uri"]`
- output：归一化后的绝对路径；相对路径中断
- ownership：依赖层负责路径归一化与绝对路径门禁；本模板只处理空值省略

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
- input：`list [键名, 已归一化值, 渲染模板, 可选允许值列表]`
- output：YAML 键值片段；空值不输出
- ownership：依赖层负责最终字段渲染；本模板负责生效条件与类型归一化

### Dependency: `base.int`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：int 或 int64
- output：十进制整数文本；非法类型中断
- ownership：依赖层只负责整数渲染

### Dependency: `base.slice`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：已校验的 slice
- output：YAML 列表；非 slice 中断
- ownership：依赖层只负责列表渲染

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 返回值
- output：布尔字符串
- ownership：依赖层负责识别解析错误形态

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 返回值
- output：布尔字符串
- ownership：依赖层负责识别数组解析错误形态

### Dependency: `definitions.httpHeader`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：包含 `name` 与 `value` 的 map
- output：HTTPHeader YAML map 片段；非法输入由依赖层中断
- ownership：本 change 只固定调用边界，不创建模板或校验 HTTPHeader 字段

## 代码边界

### `templates/api-resources/Definitions/_HTTPGetAction.tpl`

- access：`write`
- operations：`add definitions.httpGetAction`
- writable-scopes：新文件的完整内容

### `templates/base/_env.tpl`

- access：`write`
- operations：`SPLIT.SPACE`、`K8S.IANA_SVC_NAME`、`K8S.IANA_SVC_NAME_LETTER` 的 add
- writable-scopes：`SPLIT` map 与 `K8S` map 内的上述精确键

### `templates/base/_validate.tpl`

- access：`write`
- operations：`base.net` 注释与 `dns` 分支的 update
- writable-scopes：`base.net` 前置注释块与 `base.net` define 内的 `dns` 分支

### `templates/base/_get.tpl`

- access：`read`
- operations：`base.get`
- writable-scopes：无

### `templates/base/_convert.tpl`

- access：`read`
- operations：`base.string.normalize`、`base.isFromYamlError`、`base.isFromYamlArrayError`
- writable-scopes：无

### `templates/base/_field.tpl`

- access：`read`
- operations：`base.field`
- writable-scopes：无

### `templates/base/_types.tpl`

- access：`read`
- operations：`base.int`、`base.slice`
- writable-scopes：无

## 验证设计

- 在 `/tmp/` 最小 application Chart 中加载当前 library Chart，并提供 fixture `definitions.httpHeader`；fixture 只证明调用方契约，不代表子模板已实现。
- 最小有效场景：仅提供 `port: 8080`，验证唯一输出字段及数值类型。
- 较完整有效场景：提供 IPv6 `host`、原生 HTTPHeader map array、绝对 `path`、命名 `port` 与小写 `scheme`，验证字段顺序、IPv6、委托、命名端口和大写归一。
- 另一完整有效场景：提供域名或 IPv4 `host`、string array `httpHeaders`、纯数字字符串 `port`，验证 space 拆分与数值归一。
- 关键失败场景：缺少端口、端口越界、非法命名端口、CIDR 或非法 host、相对 path、非法 scheme、混用或缺少键的 headers、字符串 token 数不是 2、子模板返回非法 YAML。
- 依赖场景：直接验证 `base.net` 的 `dns` 模式接受 IPv6、拒绝 CIDR，并保持 IPv4 与域名可用。
