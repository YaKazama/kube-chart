# 新增 `definitions.hostAlias` 渲染模板设计

## 技术目标

- capability：`definitions.hostAlias`
- artifact-type：Helm 命名模板（Kubernetes 共享结构层）
- target：`templates/api-resources/Definitions/_HostAlias.tpl` 中的 `define "definitions.hostAlias"`

## 设计决策

### Decision: 校验常量集中到 base.env 并复用既有域名常量

- requirements：`ip 校验边界`、`hostnames 校验边界`
- choice：在 `templates/base/_env.tpl` 的 `NET` 下新增 `IPV4` 与 `IPV6` 两个常量，域名直接复用既有 `NET.DOMAIN_NAME`，YAML 引号剥离复用既有 `SYS.YAML_QUOTED`。
- rationale：正则契约要求项目固定正则集中定义；既有 `NET.IP` 仅 IPv4 且允许 `/\d{1,2}` 后缀，不能满足“IPv6 + zone + 无 CIDR”；既有 `NET.DOMAIN_NAME` 已满足忽略大小写、分段 1–63 字符与不含 `*`。

### Decision: 校验常量表达式

- requirements：`ip 校验边界`
- choice：`NET.IPV4` 与 `NET.IPV6` 使用下方运行时表达式；`_env.tpl` 源码中 `\.` 写作 `\\.`，其余字符与运行时一致。
- rationale：表达式覆盖规格列出的通过范围（IPv4、压缩与非压缩 IPv6、IPv4-mapped、无压缩 IPv4 混合式、zone 后缀）和拒绝范围（CIDR、超出段数、超范围八位组、前导零 IPv4），均为整体锚定；已在 Helm 4.3.1 按本文件的 YAML 转义实测确认匹配结果与 `spec.md` 一致。

```text
NET.IPV4 = ^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$

NET.IPV6 = ^(([0-9A-Fa-f]{1,4}:){6}((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])|([0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4}|([0-9A-Fa-f]{1,4}:){1,7}:|([0-9A-Fa-f]{1,4}:){1,6}:[0-9A-Fa-f]{1,4}|([0-9A-Fa-f]{1,4}:){1,5}(:[0-9A-Fa-f]{1,4}){1,2}|([0-9A-Fa-f]{1,4}:){1,4}(:[0-9A-Fa-f]{1,4}){1,3}|([0-9A-Fa-f]{1,4}:){1,3}(:[0-9A-Fa-f]{1,4}){1,4}|([0-9A-Fa-f]{1,4}:){1,2}(:[0-9A-Fa-f]{1,4}){1,5}|[0-9A-Fa-f]{1,4}:((:[0-9A-Fa-f]{1,4}){1,6})|:((:[0-9A-Fa-f]{1,4}){1,7}|:)|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])|([0-9A-Fa-f]{1,4}:){1,4}:((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9]))(%[0-9A-Za-z._-]{1,})?$
```

### Decision: hostname 长度上限由模板层校验

- requirements：`hostnames 校验边界`
- choice：253 字符上限在委托清洗后逐项使用模板内 `len` 判断，`NET.DOMAIN_NAME` 只负责字符集、分段长度与锚定；两者任一不满足即失败。
- rationale：Go 正则引擎不支持断言，单条锚定正则无法在约束各分段长度的同时限制总长度；实测 `NET.DOMAIN_NAME` 对 317 字符域名仍返回匹配，因此上限不可交给正则。

### Decision: hostnames 元素清洗委托 base.slice.cleanup

- requirements：`hostnames 校验边界`
- choice：`hostnames` 的元素拆分、域名正则校验与去重统一委托 `base.slice.cleanup`，入参为 `list <fromYamlArray 恢复的数组> $const.SPLIT.SPACE_COMMA $const.NET.DOMAIN_NAME ""`；清洗结果再逐项执行 `kindIs "string"`、253 字符上限检查，最后用 `base.field` + `base.slice` 输出。
- rationale：`base.slice.cleanup` 已提供拆分、正则校验、去空与去重的一体化能力，复用可减少分支与临时状态；分隔符与校验正则均使用 `base.env` 常量，模板不内联正则。
- 已接受的代价：`base.slice.cleanup` 第 7 步无条件 `mustUniq`，模板无法关闭，因此 `hostnames` 内部会出现去重；这与“条目级去重由调用方负责”并存。元素非法时的失败消息由 `base.slice.cleanup` 产生并使用其自身前缀。

### Decision: 单标签纯数字由清洗后的类型门禁拦截

- requirements：`hostnames 校验边界`
- choice：对清洗结果逐项要求 `kindIs "string"`，非 string 即失败。
- rationale：实测 `base.slice.cleanup` 在 Step 5 对匹配 `^[+-]?\d+$` 的片段执行 `| int`，`"0012"` → `10`、`"0755"` → `493`、`"0000"` → `0`；含点的 `0012.example.com` 不匹配且不受影响。后置 `kindIs "string"` 同时覆盖被数值化的单标签纯数字与原始数字/bool 元素，无需额外正则。

### Decision: 取值、空值收敛与字段输出

- requirements：`空值处理`、`ip 校验边界`、`hostnames 校验边界`、`HostAlias 字段渲染顺序`
- choice：`ip` 与 `hostnames` 均经 `base.get` 取值；`ip` 先剥离 `SYS.YAML_QUOTED` 外层引号并 `trim`，再按 `NET.IPV4` 或 `NET.IPV6` 校验，非字符串值因无法匹配两个整体锚定表达式而失败；`hostnames` 用 `fromYamlArray` 恢复后先排除解析错误，再交由 `base.slice.cleanup` 清洗。两者均空时不输出任何内容，调用方 `fromYaml` 得到空 map；仅其中之一为空时 `fail`；两者均有效时按 `hostnames`、`ip` 顺序分别用 `base.slice`、`quote` 渲染输出。
- rationale：遵循 `base.get` 返回值解析保护和类型稳定规则；非字符串元素直接失败由规格锁定，因此不得使用 `toStrings` 做归一化。调用方 `core.podSpec` 的 map 分支只 `mustDeepCopy` 后原样透传，不做类型或格式清洗，因此 `ip` 与每个 hostname 的类型门禁必须由本模板承担；调用方仅在渲染后做空 map 跳过与条目级 `mustUniq` 去重。实测 Helm 4.3.1：`fromYamlArray` 对空输出与 `null` 返回空切片且不报错，对标量、数字、bool 与 map 返回错误切片，因此 `hostnames` 缺失无需前置空值判断。

### Decision: ip 使用 quote 渲染

- requirements：`HostAlias 字段渲染顺序`、`ip 校验边界`
- choice：`ip` 通过 `base.field` + `quote` 输出，得到 `ip: '::'` 形式的带引号标量。
- rationale：实测 `base.field` + `base.rawString` 直出会产出 `ip: ::`、`ip: 1::`、`ip: 2001:db8::`，父级 `fromYaml` 解析失败；而 `core.podSpec` 对解析失败条目静默跳过，合法 IPv6 会在不报错的情况下丢失整条目（同批 3 条实测仅 1 条留存）。改用 `quote` 后端到端全部保留且地址文本不变。

### Decision: hostnames 解析错误使用精确判定

- requirements：`hostnames 校验边界`
- choice：不使用 `base.isFromYamlArrayError`，改为在模板内判定“数组长度为 1 且首元素转 string 后 `lower`，以 `go value of type []interface {}` 结尾”。
- rationale：`base.isFromYamlArrayError` 以“首元素包含 `error`”判定，`errors.example.com`、`error.example.com`、`myerror.io`、`provider-error.io`、`terror.example.com` 这类名称含 `error` 的合法域名会被误判为解析错误。实测 `fromYamlArray` 的全部错误文本（`unmarshal string/object/number/bool` 四类）均以 `go value of type []interface {}` 结尾，而合法域名不会匹配该后缀，因此后缀判定可唯一区分两者。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <上下文> "ip"` 与 `list <上下文> "hostnames"`，不传强制类型、合并模式、必填与调试参数。
- output：可由 `fromYaml` / `fromYamlArray` 解析的 YAML 字符串；字段缺失时返回空输出。
- ownership：`base.get` 负责多层取值、别名识别与序列化；本模板负责归一化、空值收敛与校验失败。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`update`
- input：`""`，经 `fromYaml` 恢复为常量 Map。
- output：常量 Map 中新增 `NET.IPV4` 与 `NET.IPV6`，表达式见 `Decision: 校验常量表达式`；既有 `NET.DOMAIN_NAME` 与 `SYS.YAML_QUOTED` 保持原值不变。
- ownership：`base.env` 只声明常量；匹配范围与失败语义由 `spec.md` 与本设计约束，模板不得内联或拼接正则。

### Dependency: `base.slice.cleanup`

- availability：`existing`
- source：`templates/base/_collection.tpl`
- operation：`consume`
- input：`list <fromYamlArray 恢复的 hostnames 数组> <SPLIT.SPACE_COMMA> <NET.DOMAIN_NAME> ""`；不传处理模板、输出分隔符与保留空字符串参数。
- output：可 `fromYamlArray` 解析的 YAML 列表；元素已拆分、经域名正则校验、去空并去重；拆分片段为纯数字时会被转为数值，域名非法时以 `[base.slice.cleanup]` 前缀中断。
- ownership：`base.slice.cleanup` 负责拆分、正则校验、去空与去重；本模板负责元素类型门禁、253 字符上限、空值收敛与最终字段输出。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list "hostnames" <已校验 slice> "base.slice"` 与 `list "ip" <已校验 string> "quote"`。
- output：YAML 字段片段；空渲染值不输出。
- ownership：`base.field` 负责键值渲染与 `quote` 加引号；字段生效判断由本模板在调用前完成。

### Dependency: `base.slice`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：已校验通过的 hostname 字符串 slice。
- output：YAML 列表文本。
- ownership：只做 slice 类型门禁与序列化。

## 代码边界

### `templates/base/_env.tpl`

- access：`write`
- operations：`add` `NET.IPV4`、`NET.IPV6` 常量。
- writable-scopes：`NET` 下 `IPV4` 与 `IPV6` 两个键；`NET.IP`、`NET.DOMAIN_NAME` 及其他既有键只读。

### `templates/api-resources/Definitions/_HostAlias.tpl`

- access：`write`
- operations：`add` `definitions.hostAlias` 及其整体契约注释。
- writable-scopes：整个新建文件。

### `templates/api-resources/Core/_PodSpec.tpl`

- access：`read`
- operations：`consume` 既有 `hostAliases` 字段对 `definitions.hostAlias` 的调用契约（`include` → `fromYaml` → `base.isFromYamlError` → 空 map 过滤）。
- writable-scopes：无。

## 验证设计

- 最小有效与空值：`/tmp` 最小 application Chart 加载本 change 的 `_HostAlias.tpl` 与真实 `templates/base`，执行完整条目与两者皆空两种输入，确认完整条目按 `hostnames`、`ip` 顺序输出，两者皆空返回空内容。
- `ip` 渲染与解析：同一真实依赖边界下，用 `::`、`1::`、`2001:db8::`、`::1`、`::ffff:1.2.3.4`、`fe80::1%eth0.100`、`1:2:3:4:5:6:1.2.3.4` 渲染后交父级 `fromYaml`，确认均无解析错误且地址文本不变。
- `hostnames` 拆分与去重：同一真实依赖边界下，输入 `["a.example.com b.example.com,c.example.com"]` 与 `["b.example.com","a.example.com","b.example.com","c.example.com"]`，确认拆分结果与首次出现顺序。
- 关键失败：同一真实依赖边界下，CIDR `ip`、非法 `ip`、非字符串 `ip`、含 `*` 的 hostname、`a..b`、空字符串元素、非字符串元素、单标签纯数字、超过 253 字符、非数组 `hostnames`、`ip` 与 `hostnames` 一空一非空，逐一确认渲染中断。
- 解析保护边界：`hostnames` 仅含 `errors.example.com`、`Error.example.com`、`error.example.com`、`myerror.io`、`provider-error.io` 或 `terror.example.com` 时，确认均为合法域名，不视为解析错误并正常输出。

全部场景使用真实 `templates/base` 与真实 `_env.tpl`，不提供同名 fixture，因此结果可以证明本模板与真实常量的集成行为。
