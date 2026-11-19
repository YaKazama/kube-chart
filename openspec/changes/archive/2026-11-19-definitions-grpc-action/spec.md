---
updated_at: "2026-11-19T15:13:07Z"
---

# definitions.grpcAction 规格

## Purpose

新增命名模板 `definitions.grpcAction`，将 GRPCAction 的 map 上下文校验并渲染为可嵌入 Probe 动作的 YAML 字段片段。

## ADDED Requirements

### Requirement: 字段输出与顺序

系统 MUST 接受 map 上下文，可包含 `port` 与 `service`；`port` MUST 必填，`service` MUST 可选。输出 MUST 只包含已生效字段，并按 `port`、`service` 的 Kubernetes 官方字段顺序排列。

#### Scenario: 完整有效输入

- **WHEN** 上下文同时提供 `port` 与 `service`
- **THEN** 输出按 `port`、`service` 的顺序包含这两个字段

#### Scenario: 仅提供端口

- **WHEN** 上下文只提供 `port`
- **THEN** 输出只包含 `port`，不含 `service` 键

#### Scenario: 缺少必填端口

- **WHEN** 上下文缺少 `port`，或 `port` 为 `null` 或空字符串
- **THEN** 渲染中断

### Requirement: port 校验

`port` MUST 是 integer、纯数字字符串或命名端口。integer 与纯数字字符串 MUST 位于 1-65535 并作为 integer 输出。命名端口 MUST 符合完整 Kubernetes `IsValidPortName` 规则：非空、长度不超过 15、仅含 `[a-z0-9-]`、至少包含一个字母、不得以 `-` 开头或结尾、不得包含连续 `--`，并作为字符串输出。缺失、`null`、空字符串、布尔、带小数数值、map、list、越界数值或非法名称 MUST 中断渲染。

#### Scenario: 数值端口

- **WHEN** `port` 为 `8080` 或字符串 `"8080"`
- **THEN** 输出 integer `port: 8080`

#### Scenario: 命名端口

- **WHEN** `port` 为符合规则的名称，例如 `http` 或 `grpc-web`
- **THEN** 输出该名称作为字符串 `port`

#### Scenario: 非法端口

- **WHEN** `port` 为 `0`、`65536`、带小数数值、布尔、map、list，或非法命名端口（如大写、超过 15 字符、首尾为 `-` 或包含连续 `--`）
- **THEN** 渲染中断

### Requirement: service 输出

`service` 提供且归一后非空时 MUST 以字符串输出；缺失、`null`、空字符串或仅含空白时 MUST 省略该字段。布尔、数值、map 与 list MUST 中断渲染。

#### Scenario: 输出服务名

- **WHEN** `service` 为非空字符串，例如 `grpc.health.v1.Health`
- **THEN** 输出 `service` 字段

#### Scenario: 省略空服务名

- **WHEN** `service` 缺失、为 `null`、为空字符串或仅含空白
- **THEN** 输出不含 `service` 键

#### Scenario: 非字符串服务名

- **WHEN** `service` 为布尔、数值、map 或 list
- **THEN** 渲染中断

## 非目标

- 不实现 Probe 的动作分派或动作互斥判定，由 `definitions.probe` 负责。
- 不校验 `service` 指向的 gRPC 服务在运行时是否存在。
- 不拦截与官方 `GRPCAction.port` integer 类型不一致的命名端口输入，也不在渲染期模拟 API Server 的类型校验。
