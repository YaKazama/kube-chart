# definitions.containerPort 设计

## 技术目标

- capability：`definitions.containerPort`
- artifact-type：`Helm named template`
- target：`definitions.containerPort`

## 设计决策

### Decision: 上下文双形态分派与字段归一化

- requirements：`string 简写的位置解析`、`map 上下文`
- choice：入参先按 `kindOf` 分派：`string` 进入单正则位置解析，`map` 进入逐字段取值，其他类型以 `[definitions.containerPort] input: must be string or object type` 中断。map 分支用 `base.get` 取 `containerPort`（必填）、`hostIP`、`hostPort`、`name`、`protocol`；`containerPort` 与 `hostPort` 用 `SYS.YAML_QUOTED` 剔引号后 `trim`，其余字符串字段用 `base.string.normalize` 后 `trim`。两个分支归一为同一组 `$containerPort`、`$hostIP`、`$hostPort`、`$name`、`$protocol`，共用单一校验与渲染块。
- rationale：`_Container.tpl` 的 `ports` 一直声明逐项委托 `definitions.containerPort`，而 `definitions.container.array` 的 map 元素直接以该 map 作为子模板上下文，map 形态因此是该调用契约的必要能力；两分支只做取值差异，校验与输出不重复实现。端口用剔引号而非 `base.string.normalize` 是因为 `fromYaml` 会把裸 `80` 解析为数值，`normalize` 会以非 string 中断。

### Decision: 单正则位置解析

- requirements：`string 简写的位置解析`
- choice：在 `base.env` 新增 `K8S.CONTAINER_PORT`，模板以 `include "base.env" "" | fromYaml` 取常量，先用 `mustRegexMatch` 确认整体匹配，再按 `$1`–`$5` 依次 `mustRegexReplaceAll` 提取 `hostIP`、`hostPort`、`containerPort`、`protocol`、`name` 并逐个 `trim`；不匹配时以 `[definitions.containerPort] input: …` 中断。`hostIP` 组限定为「必须含 `.` 或 `:`」的 token，纯数字片段只能落入 `hostPort`；所有 token 统一排除空白、`,`、`/`、`#`。
- rationale：单个全锚定表达式同时表达必填 `containerPort`、位置顺序与空白禁止，避免多段拆分的分支；`hostIP` 形态锚定使 `8080,80` 与 `127.0.0.1,80` 在位置语义下各自唯一。

### Decision: 端口校验复用 base.port

- requirements：`端口校验`
- choice：`containerPort` 与 `hostPort` 在 string 分支取捕获值、在 map 分支取剔引号后的标量文本，统一交由 `base.port` 校验 1-65535，返回值以 `base.field` 的 `base.int` 渲染为 integer。
- rationale：`base.port` 已实现 1-65535 范围校验并接受纯数字字符串，与端口要求完全一致；捕获值经 `base.port` 的 `int` 转换同时消除前导零，无需在模板内重复范围判断。

### Decision: hostIP 内联双正则

- requirements：`hostIP 校验`
- choice：`hostIP` 非空时用 `or (mustRegexMatch $const.NET.IPV4 …) (mustRegexMatch $const.NET.IPV6 …)` 判定，失败以 `[definitions.containerPort] hostIP: …` 中断，通过与 `base.field` 的 `quote` 输出。
- rationale：`base.net` 只有 `ip`（IPv4 可带 CIDR）、`domain`、`dns`（IPv4、IPv6 或域名）三种模式，没有「仅 IPv4 或 IPv6」的模式；`definitions.hostAlias` 已有同一内联写法，复用它既满足严格度也不改动共享能力。

### Decision: name 复用 IANA 常量

- requirements：`name 校验`
- choice：`name` 非空时依次校验 15 字符上限、`K8S.IANA_SVC_NAME`、`K8S.IANA_SVC_NAME_LETTER`，通过后以 `base.field` 的 `quote` 输出；三项校验各自以 `[definitions.containerPort] name: …` 中断。
- rationale：与 `definitions.tcpSocketAction`、`definitions.grpcAction` 的命名端口规则完全一致，直接复用同组既有常量，不新增命名校验能力。

### Decision: protocol 大写归一与枚举

- requirements：`protocol 校验`
- choice：`protocol` 非空时先 `upper`，再交给 `base.field (list "protocol" $protocol "quote" (list "SCTP" "TCP" "UDP"))`；非枚举值由 `base.field` 中断。
- rationale：`base.field` 的枚举参数与 `quote` 可共存，一次调用同时完成枚举校验与带引号输出；大写归一是模板责任，正则本身保持大小写不敏感。

### Decision: 固定顺序与逐字段直白写法

- requirements：`输出字段与顺序`
- choice：按 `containerPort`、`hostIP`、`hostPort`、`name`、`protocol` 顺序各写一段独立闭环，不使用 `range`；可选字段为空时跳过，`protocol` 缺省时不输出。
- rationale：该顺序与官方 `ContainerPort` 字段表一致，满足字母序要求；五个字段形态各异（integer、IP、integer、名称、枚举），直白展开比循环加分支更少配置点。

### Decision: container.array 可选 string 放行

- requirements：`definitions.container 的 ports 集成`
- choice：为 `definitions.container.array` 增加可选入参 `allowString`（默认 `false`）；为 `true` 时元素允许 string 并原样作为子模板上下文，map 元素行为不变，其他类型中断；`definitions.container` 只在 `ports` 调用处传入 `"allowString" true`。
- rationale：`definitions.containerPort` 同时接受 string 与 map，因此 map 元素无需开关即可直通，只有 string 元素需要开关放行；`container.array` 已统一承担数组恢复、逐项委托与空项剔除，扩一个默认关闭的开关比在 `definitions.container` 内新增私有数组逻辑更少重复，且不影响 `env`、`volumeMounts` 等既有字段。

## 依赖契约

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`add`
- input：空字符串 `""`
- output：可由 `fromYaml` 恢复的常量 Map；新增 `K8S.CONTAINER_PORT`，运行时表达式为 `^(?:([^,\s/#]*[.:][^,\s/#]*),)?(?:(\d+),)?(\d+)(?:/([^,\s/#]+))?(?:#([^,\s/#]+))?$`，依次捕获 `hostIP`、`hostPort`、`containerPort`、`protocol`、`name`；既有 `NET.IPV4`、`NET.IPV6` 与 `SYS.YAML_QUOTED` 按原值消费
- ownership：依赖层负责常量集中声明；本模板负责读取常量、整体匹配、按位置提取与剥离端口标量的 YAML 外层引号

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [map 上下文, 点分路径]`；路径仅为 `containerPort`、`hostIP`、`hostPort`、`name`、`protocol`
- output：YAML 字符串；字段缺失与 `null` 返回空输出，因此本模板对必填 `containerPort` 自行判空中断
- ownership：依赖层负责上下文优先级与别名识别；本模板负责字段业务校验

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 输出的 YAML 标量文本
- output：string；非 string 标量或非法 YAML 中断
- ownership：依赖层负责标量解码；本模板负责 `trim` 与业务校验

### Dependency: `base.port`

- availability：`existing`
- source：`templates/base/_validate.tpl`
- operation：`consume`
- input：纯数字字符串
- output：位于 1-65535 的 int；越界或非数字中断
- ownership：依赖层负责端口范围校验与整数转换；本模板负责传入捕获值

### Dependency: `base.int`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：`base.port` 返回的 int
- output：十进制整数文本
- ownership：依赖层只负责整数渲染

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [键名, 已归一化值, "base.int" | "quote", 允许值列表]`
- output：YAML 键值片段；枚举参数与 `quote` 可共存，非枚举值中断
- ownership：依赖层负责最终渲染与枚举校验；本模板负责生效条件与归一化

### Dependency: `definitions.container.array`

- availability：`existing`
- source：`templates/api-resources/Definitions/_Container.tpl`
- operation：`update`
- input：新增可选 `allowString`（bool，默认 `false`）；其余入参与既有 `key`、`define`、`raw` 不变
- output：与既有相同；`allowString=true` 时 string 元素放行，非 map 非 string 元素仍中断
- ownership：依赖层负责数组恢复、逐项委托、空项剔除与 `base.slice` 渲染；本模板只提供 string 上下文支持，既有 YAML 错误保护不变

### Dependency: `definitions.container`

- availability：`existing`
- source：`templates/api-resources/Definitions/_Container.tpl`
- operation：`update`
- input：上下文 map 不变
- output：与既有相同；`ports` 元素可为 string 或 map
- ownership：依赖层负责字段取值与渲染顺序；本模板只调整 `ports` 的委托参数与契约注释

## 代码边界

### `templates/api-resources/Definitions/_ContainerPort.tpl`

- access：`write`
- operations：`add definitions.containerPort`
- writable-scopes：新文件的完整内容

### `templates/base/_env.tpl`

- access：`write`
- operations：`add base.env 的 K8S.CONTAINER_PORT`
- writable-scopes：`base.env` 常量 Map 的 `K8S.CONTAINER_PORT` 键

### `templates/api-resources/Definitions/_Container.tpl`

- access：`write`
- operations：`update definitions.container.array 的契约注释与元素类型分支`、`update definitions.container 的 ports 注释与调用参数`
- writable-scopes：`definitions.container.array` 整体、`definitions.container` 中 `ports` 字段的注释与 `include` 调用行

### `templates/base/_validate.tpl`

- access：`read`
- operations：`base.port`
- writable-scopes：无

### `templates/base/_get.tpl`

- access：`read`
- operations：`base.get`
- writable-scopes：无

### `templates/base/_convert.tpl`

- access：`read`
- operations：`base.string.normalize`
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

- 最小有效：输入 `8080`，输出只含 `containerPort`。
- 较完整有效：`127.0.0.1,8080,80/tcp#http` 与 `::1,8080,80/udp#dns`，验证五字段顺序、IPv6 与协议大写。
- 位置分支：`8080,80` 解析为 `hostPort`+`containerPort`，`127.0.0.1,80` 解析为 `hostIP`+`containerPort`。
- map 分支：`{containerPort: 8080}` 只输出 `containerPort`；`{containerPort: 80, hostIP: "::1", hostPort: 8080, name: dns, protocol: udp}` 输出五字段且 `protocol` 为首字母无关的大写；map 缺少 `containerPort`、`hostPort: 0`、域名 `hostIP`、非法 `name`、非枚举 `protocol` 均中断；非 string 非 map 上下文中断。
- 关键失败：空输入、含空白、多余分隔符、端口 `0`/`65536`/`65537`、域名或 CIDR `hostIP`、非法 `name`、非枚举 `protocol`，均中断渲染。
- 集成：加载真实 `_Container.tpl`，验证 `ports` 的 string 简写、仅 map 元素、简写与 map 混用，以及 `volumeMounts` 的 string 元素仍中断。
- 依赖边界：`base.*` 与 `_Container.tpl` 均为真实实现，直接在 `/tmp/` 最小 application Chart 中加载并执行 `helm template`，不使用同名 fixture。
