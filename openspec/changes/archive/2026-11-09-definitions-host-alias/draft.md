---
change-id: definitions-host-alias
updated_at: "2026-11-09T10:29:46Z"
---

# 新增 `definitions.hostAlias` 渲染模板

## 目标

- 提供 `definitions.hostAlias` 模板，把单个 HostAlias 数据渲染为 Kubernetes `HostAlias` 结构。

## 需求

- 模板名为 `definitions.hostAlias`。
- 入参为父级透传的单个 HostAlias 数据，字段为 `ip` 与 `hostnames`。
- 输出字段按官方文档定义顺序生成：先 `hostnames`，后 `ip`。
- `ip` 与 `hostnames` 同时为空时，两个字段都不渲染，返回空 map，父级据此跳过该条目且不报错。
- `ip` 与 `hostnames` 中任意一个为空、另一个非空时，中断报错，不输出单字段条目。
- “为空”包含字段缺失、`ip` 为空字符串与 `hostnames` 为空数组。
- 字段校验统一使用正则表达式完成。
- `ip` 按标准 ipv4 / ipv6 格式校验，不接受 CIDR 后缀。
- `ip` 接受 IPv4-mapped 形式与 IPv6 zone 后缀。
- IPv6 zone 后缀接受字母、数字、`.` 与 `-`，例如 `fe80::1%eth0`、`fe80::1%eth0.100`、`fe80::1%en-0`。
- `ip` 接受无压缩的 IPv4 混合式 IPv6，例如 `1:2:3:4:5:6:1.2.3.4`。
- `hostnames` 每个元素按标准 DNS 域名格式校验，不支持 `*` 通配符。
- `hostnames` 元素经底层集合清洗能力完成拆分与格式校验，允许单个元素内按空白或逗号分隔多个域名。
- `hostnames` 内部重复域名自动去重，保持首次出现顺序。
- 单标签纯数字元素（如 `0012`、`1234`）不是合法 hostname，必须中断报错；带点的形式（如 `0012.example.com`）正常通过。
- 名称中含 `error` 的合法域名（如 `errors.example.com`、`myerror.io`、`provider-error.io`）必须正常通过，不得被 YAML 解析保护误判。
- hostname 校验忽略大小写，大写形式同样合法。
- 单个 hostname 按 DNS 域名 253 字符限制校验。
- 任一字段非法时中断报错。
- `hostnames` 元素不是 string 类型时直接失败，不做字符串归一化。

## 期望输入格式

```yaml
ip: 1.1.1.1
hostnames:
  - a.example.com
  - b.example.com
```

## 约束

- 父级只做条目类型分支、空结果过滤与去重，不清洗字段；字段类型与格式校验由本模板承担。
- 校验使用正则表达式，不借助额外依赖或自定义函数。

## 非目标

- 不处理 `hostAliases` 数组的循环、合并与去重；由调用方负责。
- 不支持 `*` 等通配符域名，RFC 1123 本身不允许该形式。
- 不修改既有其他 `definitions.*` 模板行为。

## 验收

- 同时给出合法 `ip` 与 `hostnames` 时，按 `hostnames`、`ip` 顺序输出两项。
- `ip` 非标准 ipv4 / ipv6 格式时渲染失败，带 CIDR 后缀视为非法。
- `::ffff:1.2.3.4`、`fe80::1%eth0`、`fe80::1%eth0.100` 与 `1:2:3:4:5:6:1.2.3.4` 通过校验。
- 以双冒号结尾的合法 IPv6（如 `::`、`1::`、`2001:db8::`）渲染后能被父级正常解析并保留条目，不出现静默丢失。
- `hostnames` 为 `errors.example.com`、`myerror.io` 等名称含 `error` 的合法域名时，正常渲染而非报错。
- `hostnames` 中存在非标准 DNS 域名时渲染失败。
- `hostnames` 为 `["a.example.com b.example.com,c.example.com"]` 时拆分为三个域名并按顺序输出。
- `hostnames` 为 `["a.example.com", "a.example.com"]` 时去重为单个域名。
- `hostnames` 为单标签纯数字（`0012`、`1234`、`0000`）时渲染失败。
- `A.Example.COM` 等大写形式域名通过校验。
- 超过 253 字符的 hostname 渲染失败。
- `*.example.com` 等含 `*` 的 hostname 渲染失败。
- `ip` 与 `hostnames` 同时为空时返回空 map，父级不产生 `hostAliases` 条目且不报错。
- 任一字段为空、另一个非空时渲染失败，包括仅给出合法 `ip` 或仅给出合法 `hostnames`。
- `hostnames` 元素为数字、bool 或 map 时渲染失败。

## 已确认决策（本轮 `/opsx:explore` 实测，Helm 4.3.1 + 真实 `templates/base`）

以下内容已由用户确认，需据此更新 `spec.md`、`design.md` 与 `tasks.md`。既有执行制品尚未包含这些决策，实施前必须重新执行 `/opsx:spec definitions-host-alias`。

### `ip` 输出必须带引号

- 事实：`base.field` + `base.rawString` 直出 `ip` 会产出 `ip: ::` 这类片段；`::`、`1::`、`2001:db8::`、`1:2:3:4:5:6:7::` 均使父级 `fromYaml` 解析失败。
- 影响：`core.podSpec` 对解析失败条目静默跳过，合法 IPv6 会在不报错的情况下整条丢失；同批 3 条输入实测仅 1 条留存。
- 决策：`ip` 输出统一带引号（`base.field` + `quote`），实测端到端全部保留且地址文本不变。

### `ip` 校验范围放宽

- 事实：候选表达式拒绝无压缩 IPv4 混合式 `1:2:3:4:5:6:1.2.3.4`，以及 zone 含 `.` 或 `-` 的后缀（`fe80::1%eth0.100`、`fe80::1%en-0`）。
- 决策：zone 字符集放宽到字母、数字、`.` 与 `-`，并补齐无压缩 IPv4 混合式分支。
- 实测：放宽后的表达式接受 `1:2:3:4:5:6:1.2.3.4`、`fe80::1%eth0.100`、`fe80::1%en-0`、`::1.2.3.4`、`1::1.2.3.4`、`0:0:0:0:0:0:0:1`、`::ffff:0:1.2.3.4`；仍拒绝 `1.1.1.1`、`1:2:3:4:5:6:7`、`1:2:3:4:5:6:7:8:9`、`::ffff:1.2.3.4/24`。

### `hostnames` 解析保护使用精确判定

- 事实：`base.isFromYamlArrayError` 以“首元素转 string 后包含 `error`”判定，导致 `errors.example.com`、`Error.example.com`、`myerror.io` 这类合法域名作为唯一元素时被误判为数组解析错误。
- 决策：不使用 `base.isFromYamlArrayError`，改为判定“数组长度为 1 且首元素小写后以 `go value of type []interface {}` 结尾”。
- 实测：四类真实 `fromYamlArray` 错误文本（`unmarshal string/object/number/bool`）均带该后缀；`errors.example.com`、`Error.example.com`、`error.example.com`、`myerror.io`、`provider-error.io`、`terror.example.com` 均是合法域名，不匹配该错误后缀，按域名格式校验正常通过。

### 已核实无冲突的事实

- `NET.IPV4`（候选表达式）拒绝 `1.1.1.1/24` 与前导零 `01.1.1.1`，接受 `0.0.0.0`、`255.255.255.255`。
- `NET.DOMAIN_NAME` 不限制总长度（317 字符通过整条正则），因此 253 字符上限必须由模板层 `len` 承担。
- `base.slice` 会把 `1234`、`true`、`null`、`0755` 样式的元素加引号，父级 `fromYaml` 往返后仍为 string。
- 空输出经 `fromYaml` 得到空 map `{}` 且 `base.isFromYamlError` 为 false，父级空 map 过滤可用。
- `hostnames` 元素为 `1`、`true`、map 时 `fromYamlArray` 不报错且保留原类型，因此元素级 `kindIs "string"` 门禁必须保留。
- 父级 `mustUniq` 对同构 map 去重有效。

### `hostnames` 委托集合清洗能力

- 决策：`hostnames` 的元素拆分、域名正则校验与去重委托 `base.slice.cleanup`；元素类型门禁、253 字符上限与空值收敛仍由 `definitions.hostAlias` 承担。
- 已接受：`base.slice.cleanup` 内部无条件去重，因此 `hostnames` 会出现去重；这与“数组循环与合并由调用方负责”不冲突，调用方仍负责 `hostAliases` 条目级去重。
- 已接受：元素非法时失败消息由被委托能力产生，使用其自身前缀，不使用 `[definitions.hostAlias]`。
- 事实：`base.slice.cleanup` 的 `TYPES.INT` 分支会把单标签纯数字字符串转为数值（`0012` → `10`、`0000` → `0`、`0755` → `493`），且该转换发生在域名正则之前；含点的 `0012.example.com` 不匹配 `^[+-]?\d+$`，不受影响。
- 决策：对清洗结果逐项要求 string 类型，被转为数值的单标签纯数字因此中断报错；该门禁同时覆盖原始数字与 bool 元素。
- 实测：去重保持首次出现顺序（`b,a,b,c` → `b,a,c`）；`a..b`、`*.example.com`、空字符串由被委托能力中断；空数组输出 `[]`。
