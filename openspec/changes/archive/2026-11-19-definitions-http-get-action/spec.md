---
updated_at: "2026-11-18T17:10:16Z"
---

# definitions.httpGetAction 规格

## Purpose

新增命名模板 `definitions.httpGetAction`，将 HTTPGetAction 的 map 上下文校验并渲染为可嵌入父动作的 YAML 字段片段，同时为 HTTPHeader 子模板提供逐项委托边界。

## ADDED Requirements

### Requirement: 字段输出与顺序

系统 MUST 接受 map 上下文，可包含 `host`、`httpHeaders`、`path`、`port`、`scheme`；`port` MUST 必填且非空，其他字段可选。输出 MUST 只包含已生效字段，并按 `host`、`httpHeaders`、`path`、`port`、`scheme` 的 Kubernetes 官方顺序排列。

#### Scenario: 最小有效输入

- **WHEN** 上下文仅包含 `port: 8080`
- **THEN** 输出只包含 `port: 8080`

#### Scenario: 完整有效输入

- **WHEN** 上下文同时提供 `host`、`httpHeaders`、`path`、`port`、`scheme`
- **THEN** 输出按 `host`、`httpHeaders`、`path`、`port`、`scheme` 的顺序包含这些字段

#### Scenario: 缺少必填端口

- **WHEN** 上下文缺少 `port` 或 `port` 为空
- **THEN** 渲染中断

### Requirement: host 校验

`host` 提供时 MUST 是主机名、IPv4 地址或 IPv6 地址；缺失或为空时 MUST 省略该字段。CIDR、URL 或其他非法主机值 MUST 中断渲染。

#### Scenario: 接受主机名与 IP 地址

- **WHEN** `host` 分别为域名、IPv4 地址或 IPv6 地址
- **THEN** 值校验通过并作为 `host` 输出

#### Scenario: 拒绝 CIDR 或非法主机

- **WHEN** `host` 为 CIDR、包含 URL 或不符合主机名/IP 语法
- **THEN** 渲染中断

### Requirement: httpHeaders 解析与委托

`httpHeaders` 提供时 MUST 是 HTTPHeader array 或 string array。HTTPHeader array 的每个元素 MUST 是包含 `name` 与 `value` 键的 map，并原样作为 map 上下文传给 `definitions.httpHeader`。string array 的每个元素 MUST 先 trim，再按一个或多个空格拆分后得到恰好两个非空 token，分别构造为 `name` 与 `value` map 后传给 `definitions.httpHeader`。子模板返回的非空 map MUST 按原顺序组成 `httpHeaders` 输出；缺失、空 array 时 MUST 省略该字段。元素形态混用、HTTPHeader map 缺少 `name` 或 `value`、字符串 token 数不是 2，或子模板输出非法 YAML 或非 map 时 MUST 中断渲染。

#### Scenario: 原生 HTTPHeader array

- **WHEN** `httpHeaders` 是包含 `name` 与 `value` 的 map array
- **THEN** 每个 map 按顺序传给 `definitions.httpHeader`，返回的非空 map 组成 `httpHeaders` array

#### Scenario: 字符串数组

- **WHEN** `httpHeaders` 是元素形如 `X-Foo bar` 的 string array
- **THEN** 每个元素拆分为 `name: X-Foo` 与 `value: bar` 后按顺序委托 `definitions.httpHeader`

#### Scenario: 字符串 token 数非法

- **WHEN** string array 的任一元素 trim 后不能拆分为恰好两个 token
- **THEN** 渲染中断

#### Scenario: 元素形态非法

- **WHEN** `httpHeaders` 不是 array、混用 map 与 string 元素，或 HTTPHeader map 缺少 `name` 或 `value`
- **THEN** 渲染中断

### Requirement: path 校验

`path` 提供时 MUST 是绝对 URI 路径；系统 MUST 去除首尾空白并清理 `.`、`..` 路径段后输出。缺失或为空时 MUST 省略该字段，相对路径 MUST 中断渲染。

#### Scenario: 归一化绝对路径

- **WHEN** `path` 为 `/api/../health`
- **THEN** 输出归一化后的绝对路径 `/health`

#### Scenario: 拒绝相对路径

- **WHEN** `path` 为 `health` 或其他相对路径
- **THEN** 渲染中断

### Requirement: port 校验

`port` MUST 是 integer、纯数字字符串或命名端口。integer 与纯数字字符串 MUST 位于 1-65535 并作为 integer 输出。命名端口 MUST 符合完整 Kubernetes `IsValidPortName` 规则：非空、长度不超过 15、仅含 `[a-z0-9-]`、至少包含一个字母、不得以 `-` 开头或结尾、不得包含连续 `--`，并作为字符串输出。其他类型、越界数值或非法名称 MUST 中断渲染。

#### Scenario: 数值端口

- **WHEN** `port` 为 `8080` 或字符串 `"8080"`
- **THEN** 输出 integer `port: 8080`

#### Scenario: 命名端口

- **WHEN** `port` 为符合规则的名称，例如 `http` 或 `http-web`
- **THEN** 输出该名称作为字符串 `port`

#### Scenario: 非法端口

- **WHEN** `port` 为 `0`、`65536`、非 integer/string 类型，或非法命名端口（如大写、超过 15 字符、首尾为 `-` 或包含连续 `--`）
- **THEN** 渲染中断

### Requirement: scheme 归一化

`scheme` 提供时 MUST 按大小写不敏感识别 `HTTP` 与 `HTTPS`，并在输出时统一转为全大写；缺失或为空时 MUST 省略该字段。其他值 MUST 中断渲染。

#### Scenario: 小写 scheme

- **WHEN** `scheme` 为 `http` 或 `https`
- **THEN** 输出分别为 `HTTP` 或 `HTTPS`

#### Scenario: 非法 scheme

- **WHEN** `scheme` 不是 `HTTP` 或 `HTTPS` 的大小写变体
- **THEN** 渲染中断

## 非目标

- 不创建 `definitions.httpHeader`，也不在本 change 校验其字段语义。
- 不处理 `definitions.lifecycleHandler` 的动作分派或其他动作字段解析。
- 不接受 CIDR、URL 作为 `host`，不解析 HTTPHeader 的协议语义。
