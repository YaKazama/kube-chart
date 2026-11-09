---
updated_at: "2026-11-09T10:30:40Z"
---

# 新增 `definitions.hostAlias` 渲染模板规格

## Purpose

为 Kubernetes `HostAlias` 结构提供可复用的渲染模板，供 PodSpec 等上层结构按官方字段顺序输出 hosts 文件条目。

## ADDED Requirements

### Requirement: HostAlias 字段渲染顺序

系统 MUST 在入参同时具备合法 `ip` 与 `hostnames` 时，按 `hostnames`、`ip` 的 Kubernetes 官方字段顺序输出两个字段。

#### Scenario: 完整条目

- **WHEN** 入参 `ip` 为 `1.1.1.1`，`hostnames` 为 `a.example.com` 与 `b.example.com`
- **THEN** 输出中 `hostnames` 列表先于 `ip` 出现

#### Scenario: 双冒号结尾的 IPv6

- **WHEN** `ip` 为 `::`、`1::` 或 `2001:db8::`
- **THEN** 输出能被调用方按 YAML 解析并完整保留地址文本，不出现静默丢弃条目

### Requirement: 空值处理

系统 MUST 把字段缺失、`ip` 为空字符串与 `hostnames` 为空数组都视为空；两个字段同时为空时 MUST 输出空内容，任一为空且另一个非空时 MUST 中断渲染。

#### Scenario: 同时为空

- **WHEN** `ip` 与 `hostnames` 同时为空
- **THEN** 不输出任何字段，调用方据空结果跳过该条目且不报错

#### Scenario: 仅 ip 为空

- **WHEN** `ip` 为空且 `hostnames` 非空
- **THEN** 渲染中断并报错

#### Scenario: 仅 hostnames 为空

- **WHEN** `hostnames` 为空且 `ip` 非空
- **THEN** 渲染中断并报错

### Requirement: ip 校验边界

系统 MUST 只接受标准 IPv4 或 IPv6 文本地址，MUST 接受 IPv4-mapped 形式、无压缩的 IPv4 混合式与 IPv6 zone 后缀，MUST 拒绝 CIDR 后缀与其他非法格式。

#### Scenario: 合法 IPv4

- **WHEN** `ip` 为 `1.1.1.1`、`0.0.0.0` 或 `255.255.255.255`
- **THEN** 校验通过并输出 `ip`

#### Scenario: 合法 IPv6

- **WHEN** `ip` 为 `2001:db8::8a2e:370:7334`、`::ffff:1.2.3.4`、`0:0:0:0:0:0:0:1` 或 `1:2:3:4:5:6:7:8`
- **THEN** 校验通过并输出 `ip`

#### Scenario: IPv6 zone 后缀

- **WHEN** `ip` 为 `fe80::1%eth0`、`fe80::1%eth0.100` 或 `fe80::1%en-0`
- **THEN** 校验通过并输出 `ip`

#### Scenario: 无压缩的 IPv4 混合式

- **WHEN** `ip` 为 `1:2:3:4:5:6:1.2.3.4`、`::1.2.3.4` 或 `1::1.2.3.4`
- **THEN** 校验通过并输出 `ip`

#### Scenario: CIDR 后缀

- **WHEN** `ip` 为 `1.1.1.1/24` 或 `::ffff:1.2.3.4/24`
- **THEN** 渲染中断并报错

#### Scenario: 非法格式

- **WHEN** `ip` 为 `1.1.1`、`01.1.1.1`、`256.1.1.1`、`1:2:3:4:5:6:7`、`1:2:3:4:5:6:7:8:9` 或其他非标准文本
- **THEN** 渲染中断并报错

#### Scenario: 非字符串 ip

- **WHEN** `ip` 为数字、布尔、map 或数组
- **THEN** 渲染中断并报错，不做字符串归一化

### Requirement: hostnames 校验边界

系统 MUST 要求 `hostnames` 为数组，MUST 在单个元素内按空白或逗号拆分多个域名并按原顺序展开，MUST 逐项要求元素为符合标准 DNS 域名格式的字符串，MUST 忽略大小写，MUST 去除重复域名并保持首次出现顺序，MUST 拒绝通配符 `*`、单标签纯数字、超过 253 字符的元素与非字符串元素。

#### Scenario: 合法域名

- **WHEN** `hostnames` 元素为 `a.example.com`、`A.Example.COM` 或 `localhost`
- **THEN** 全部校验通过并按数组顺序输出

#### Scenario: 元素内多域名

- **WHEN** `hostnames` 为 `["a.example.com b.example.com,c.example.com"]`
- **THEN** 输出为按空白与逗号拆分后的三个域名，顺序与原文本一致

#### Scenario: 重复域名

- **WHEN** `hostnames` 为 `["b.example.com", "a.example.com", "b.example.com", "c.example.com"]`
- **THEN** 输出为 `b.example.com`、`a.example.com`、`c.example.com`

#### Scenario: 单标签纯数字

- **WHEN** `hostnames` 元素为 `0012`、`1234` 或 `0000`
- **THEN** 渲染中断并报错

#### Scenario: 带点前缀的纯数字域名

- **WHEN** `hostnames` 元素为 `0012.example.com`
- **THEN** 校验通过并按原文本输出

#### Scenario: 名称含 error 的合法域名

- **WHEN** `hostnames` 为仅含 `errors.example.com`、`Error.example.com`、`error.example.com`、`myerror.io`、`provider-error.io` 或 `terror.example.com` 的数组
- **THEN** 校验通过并正常输出，不视为解析错误

#### Scenario: 通配符域名

- **WHEN** `hostnames` 元素为 `*.example.com`
- **THEN** 渲染中断并报错

#### Scenario: 超长域名

- **WHEN** `hostnames` 元素长度超过 253 字符
- **THEN** 渲染中断并报错

#### Scenario: 非法域名格式

- **WHEN** `hostnames` 元素为 `a..b`、`-a.com`、`a-.com`、`a_b.com` 或空字符串
- **THEN** 渲染中断并报错

#### Scenario: 非字符串元素

- **WHEN** `hostnames` 元素为数字、布尔或 map
- **THEN** 渲染中断并报错，不做字符串归一化

#### Scenario: 非数组 hostnames

- **WHEN** `hostnames` 不是数组类型
- **THEN** 渲染中断并报错

## 非目标

- 不处理 `hostAliases` 数组的循环、条目级合并与条目级去重；由调用方负责。
- 不支持 `*` 等通配符域名。
- 不修改其他 `definitions.*` 模板的可观察行为。
