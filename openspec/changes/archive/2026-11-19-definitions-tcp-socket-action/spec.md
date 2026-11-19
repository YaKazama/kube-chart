---
updated_at: "2026-11-19T14:25:03Z"
---

# definitions.tcpSocketAction 规格

## Purpose

新增命名模板 `definitions.tcpSocketAction`，将 TCPSocketAction 的 map 上下文校验并渲染为可嵌入父动作的 YAML 字段片段。

## ADDED Requirements

### Requirement: 字段输出与顺序

系统 MUST 接受 map 上下文，可包含 `host` 与 `port`；`port` MUST 必填且非空，`host` 可选。输出 MUST 只包含已生效字段，并按 `host`、`port` 的 Kubernetes 官方字段顺序排列。

#### Scenario: 最小有效输入

- **WHEN** 上下文仅包含 `port: 8080`
- **THEN** 输出只包含 `port: 8080`

#### Scenario: 完整有效输入

- **WHEN** 上下文同时提供 `host` 与 `port`
- **THEN** 输出按 `host`、`port` 的顺序包含这两个字段

#### Scenario: 缺少必填端口

- **WHEN** 上下文缺少 `port` 或 `port` 为空
- **THEN** 渲染中断

### Requirement: host 校验

`host` 提供时 MUST 是主机名、IPv4 地址或 IPv6 地址；缺失或为空时 MUST 省略该字段。CIDR、URL、非字符串或其他非法主机值 MUST 中断渲染。

#### Scenario: 接受主机名与 IP 地址

- **WHEN** `host` 分别为域名、IPv4 地址或 IPv6 地址
- **THEN** 值校验通过并作为 `host` 输出

#### Scenario: 拒绝 CIDR 或非法主机

- **WHEN** `host` 为 CIDR、包含 URL、不是字符串或不符合主机名/IP 语法
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

- **WHEN** `port` 为 `0`、`65536`、带小数的数值、非 integer/string 类型，或非法命名端口（如大写、超过 15 字符、首尾为 `-` 或包含连续 `--`）
- **THEN** 渲染中断

## 非目标

- 不处理其他 Action 类型（`exec`、`httpGet`、`grpc`、`sleep`）以及 probe、lifecycle handler 的动作分派。
