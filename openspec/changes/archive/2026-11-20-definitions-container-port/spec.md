---
updated_at: "2026-11-19T16:00:15Z"
---

# definitions.containerPort 规格

## Purpose

新增命名模板 `definitions.containerPort`，把 string 简写或 `ContainerPort` map 上下文解析并渲染为可嵌入 `containers[].ports` 的 YAML 字段片段，并使 `definitions.container` 的 `ports` 同时接受该简写。

## ADDED Requirements

### Requirement: string 简写的位置解析

系统 MUST 接受 string 或 map 两种上下文，并 MUST 拒绝其他类型。string 上下文 MUST 完整匹配 `[hostIP,][hostPort,]<containerPort>[/protocol][#name]`。`containerPort` MUST 存在。`hostIP`、`hostPort` 与 `containerPort` MUST 按 `,` 分隔的位置顺序解析，`protocol` MUST 由 `/` 引导，`name` MUST 由 `#` 引导。

`hostIP` 位置 MUST 只在片段同时包含 `.` 或 `:` 时成立，因此纯数字片段 MUST 解析为 `hostPort`。`hostIP` 与 `hostPort` MUST 相互独立，任一存在都不要求另一个同时存在。

string 上下文 MUST 不含任何空白字符；不匹配该格式或缺少 `containerPort` 时 MUST 中断渲染。

#### Scenario: 仅容器端口

- **WHEN** 输入为 `8080`
- **THEN** 只解析出 `containerPort` 为 `8080`

#### Scenario: 纯数字两段

- **WHEN** 输入为 `8080,80`
- **THEN** 解析出 `hostPort` 为 `8080`、`containerPort` 为 `80`，且不解析 `hostIP`

#### Scenario: IP 两段

- **WHEN** 输入为 `127.0.0.1,80`
- **THEN** 解析出 `hostIP` 为 `127.0.0.1`、`containerPort` 为 `80`，且不解析 `hostPort`

#### Scenario: 完整五字段

- **WHEN** 输入为 `127.0.0.1,8080,80/tcp#http`
- **THEN** 五个字段全部解析成功

#### Scenario: 非法格式

- **WHEN** string 输入为空、含空白、缺少 `containerPort` 或含多余分隔符
- **THEN** 渲染中断

#### Scenario: 非法上下文类型

- **WHEN** 上下文既不是 string 也不是 map
- **THEN** 渲染中断

### Requirement: map 上下文

系统 MUST 接受 map 上下文，键为 `containerPort`（必填）与 `hostIP`、`hostPort`、`name`、`protocol`（可选）。map 上下文的字段校验与输出 MUST 与 string 简写完全一致，不受上下文形态影响。

`containerPort` 缺失、为 null 或为空时 MUST 中断渲染；可选字段缺失、为 null 或为空时 MUST 省略。map 中上述键及其对应 `<键>Alias` 以外的字段 MUST 静默忽略。

#### Scenario: map 最小输入

- **WHEN** 上下文为 `{containerPort: 8080}`
- **THEN** 输出只含 `containerPort: 8080`

#### Scenario: map 完整输入

- **WHEN** 上下文为 `{containerPort: 80, hostIP: "::1", hostPort: 8080, name: dns, protocol: udp}`
- **THEN** 输出依次为 `containerPort`、`hostIP`、`hostPort`、`name`、`protocol`，且 `protocol` 为 `"UDP"`

#### Scenario: map 缺少必填端口

- **WHEN** map 上下文缺少 `containerPort`，或 `containerPort` 为 null、空字符串
- **THEN** 渲染中断

#### Scenario: map 字段非法

- **WHEN** map 中 `hostPort` 为 `0`、`hostIP` 为域名、`name` 含大写、或 `protocol` 非枚举
- **THEN** 渲染中断

#### Scenario: map 忽略未声明字段

- **WHEN** map 上下文同时包含 `containerPort: 80` 与未声明的 `foo: bar`
- **THEN** 输出只含 `containerPort: 80`，不输出 `foo`

### Requirement: 输出字段与顺序

输出 MUST 只包含已解析出的字段，并按 `containerPort`、`hostIP`、`hostPort`、`name`、`protocol` 的固定顺序渲染，与 Kubernetes `ContainerPort` 官方字段顺序一致。未解析出的可选字段 MUST 省略。`protocol` 缺省时 MUST 不输出该字段，交由 API 默认值 `TCP` 生效。

#### Scenario: 最小输出

- **WHEN** 输入为 `8080`
- **THEN** 输出只含 `containerPort: 8080`

#### Scenario: 固定顺序

- **WHEN** 输入为 `::1,8080,80/udp#dns`
- **THEN** 输出依次为 `containerPort`、`hostIP`、`hostPort`、`name`、`protocol`

### Requirement: 端口校验

`containerPort` 与 `hostPort` MUST 是位于 1-65535 的端口号，并以 integer 输出。`0`、`65536` 及更大值 MUST 中断渲染。

#### Scenario: 合法端口

- **WHEN** 输入为 `8080,80`
- **THEN** 输出 integer `hostPort: 8080` 与 `containerPort: 80`

#### Scenario: 越界端口

- **WHEN** `containerPort` 或 `hostPort` 为 `0`、`65536`、`65537`
- **THEN** 渲染中断

### Requirement: hostIP 校验

`hostIP` MUST 是标准 IPv4 或 IPv6 地址，并以带引号的字符串输出。域名、CIDR、URL 及其他地址形式 MUST 中断渲染。

#### Scenario: 接受 IPv4 与 IPv6

- **WHEN** `hostIP` 为 `127.0.0.1`、`::1`、`2001:db8::1` 或带 zone 的 `fe80::1%eth0`
- **THEN** 校验通过并以带引号字符串输出

#### Scenario: 拒绝非 IP

- **WHEN** `hostIP` 为 `example.com`、`10.0.0.0/8` 或 `http://1.2.3.4`
- **THEN** 渲染中断

### Requirement: name 校验

`name` MUST 符合 Kubernetes 命名端口规则：长度不超过 15 字符、符合 `IANA_SVC_NAME`、至少包含一个字母，并以带引号的字符串输出。含大写、首尾连字符、连续连字符、超过 15 字符或不含字母的 `name` MUST 中断渲染。

#### Scenario: 合法名称

- **WHEN** `name` 为 `http` 或 `http-web`
- **THEN** 校验通过并以带引号字符串输出

#### Scenario: 非法名称

- **WHEN** `name` 为 `HTTP`、`-http`、`http--web`、`123` 或超过 15 字符
- **THEN** 渲染中断

### Requirement: protocol 校验

`protocol` MUST 大小写不敏感匹配，输出 MUST 强制大写，枚举范围 MUST 为 Kubernetes 官方标示的 `SCTP`、`TCP`、`UDP`。其他取值 MUST 中断渲染。

#### Scenario: 大小写归一

- **WHEN** `protocol` 为 `tcp`、`Tcp` 或 `TCP`
- **THEN** 均输出 `protocol: "TCP"`

#### Scenario: 非法协议

- **WHEN** `protocol` 为 `HTTP` 或 `icmp`
- **THEN** 渲染中断

### Requirement: definitions.container 的 ports 集成

`definitions.container` 的 `ports` MUST 接受 string 简写元素与 map 元素。两种元素 MUST 都按 `definitions.containerPort` 渲染，map 元素 MUST 保持既有逐项委托行为，其他类型元素 MUST 中断渲染。其他数组字段的元素 MUST 仍要求为 map。

#### Scenario: 简写元素

- **WHEN** `ports` 为 `["80", "8080,80"]`
- **THEN** 渲染出两个完整 `ContainerPort` 字段片段

#### Scenario: 简写与 map 混用

- **WHEN** `ports` 为 `["80", {containerPort: 443, name: https}]`
- **THEN** 两项均渲染为 `ContainerPort` 字段片段，顺序与输入一致

#### Scenario: 其他数组字段不变

- **WHEN** `volumeMounts`、`env` 或 `envFrom` 的元素不是 map
- **THEN** 渲染中断

## 非目标

- 不校验 `name` 在 Pod 内的唯一性。
- 不新增 `definitions.containerPort` 与 `ports` 集成以外的模板或字段。
- 不接受 `:` 作为 `,` 的兼容分隔符。
