---
updated_at: "2026-11-19T14:56:21Z"
---

# definitions.probe 规格

## Purpose

新增命名模板 `definitions.probe`，将 Probe 的 map 上下文校验并渲染为可嵌入 Container 的 YAML 字段片段，并按锁定的子模板边界委托 `exec`、`grpc`、`httpGet`、`tcpSocket` 四类动作。

## ADDED Requirements

### Requirement: 字段输出与顺序

系统 MUST 接受 map 上下文，可包含 `exec`、`failureThreshold`、`grpc`、`httpGet`、`initialDelaySeconds`、`periodSeconds`、`successThreshold`、`tcpSocket`、`terminationGracePeriodSeconds`、`timeoutSeconds`；所有字段 MUST 可选。输出 MUST 只包含已生效字段，并按上述顺序排列；未提供的字段 MUST 省略。

#### Scenario: 仅提供阈值

- **WHEN** 上下文仅包含 `failureThreshold: 3`
- **THEN** 输出只包含 `failureThreshold: 3`，不含任何动作字段

#### Scenario: 动作与阈值混合

- **WHEN** 上下文同时提供 `httpGet`、`initialDelaySeconds`、`periodSeconds`、`timeoutSeconds`
- **THEN** 输出按 `httpGet`、`initialDelaySeconds`、`periodSeconds`、`timeoutSeconds` 的顺序包含这些字段

#### Scenario: 空上下文

- **WHEN** 上下文不包含上述任何字段
- **THEN** 输出为空内容

### Requirement: 动作互斥

`exec`、`grpc`、`httpGet`、`tcpSocket` MUST 互斥，最多只提供一个。提供情况 MUST 按键是否存在判定，值为 `null` 同样视为已提供；同时提供两个及以上时 MUST 中断渲染。

#### Scenario: 单个动作

- **WHEN** 上下文只提供 `tcpSocket` 一个动作键
- **THEN** 渲染成功并输出 `tcpSocket` 字段

#### Scenario: 多个动作

- **WHEN** 上下文同时提供 `exec` 与 `httpGet`
- **THEN** 渲染中断

#### Scenario: 空值动作参与互斥

- **WHEN** 上下文提供 `exec: null` 与合法的 `httpGet`
- **THEN** 渲染中断

### Requirement: 生效动作空值

生效的动作字段值为 `null` 或空 map 时 MUST 中断渲染。

#### Scenario: null 动作

- **WHEN** 上下文只提供 `exec: null`
- **THEN** 渲染中断

#### Scenario: 空 map 动作

- **WHEN** 上下文只提供 `grpc: {}`
- **THEN** 渲染中断

### Requirement: 动作委托与简写解析

动作 MUST 按映射委托子模板：`exec` → `definitions.execAction`、`grpc` → `definitions.grpcAction`、`httpGet` → `definitions.httpGetAction`、`tcpSocket` → `definitions.tcpSocketAction`。原生 map MUST 原样传给子模板；简写 MUST 先解析为 map 再传递，且不匹配约定形态或类型既非 map 又非约定简写时 MUST 中断渲染。子模板输出 MUST 以动作键作为字段嵌入，其输出非法 YAML 时 MUST 中断渲染。

简写形态 MUST 为：

- `exec`：string array，元素 MUST 全为 string，解析为 `command`。
- `grpc`：string，格式为 `[service] <port>`，`service` 可选、`port` 必填，`service` 与 `port` 之间的分隔符 MUST 为空格或逗号，解析为 `service` 与 `port`。
- `httpGet`：string，按 `scheme`、`host`、`port`、`path`、`headers` 的位置顺序解析；`headers` 括号内容 MUST 按逗号分组、组内按空格分词，每两个 token 组成一个 `name value`，任一分组的分词数为奇数时 MUST 中断渲染。
- `tcpSocket`：string，按 `host`、`port` 的位置顺序解析。

#### Scenario: exec 简写

- **WHEN** `exec` 为 `["sh", "-c", "true"]` 的 string array
- **THEN** 解析为 `command` 后委托 `definitions.execAction`

#### Scenario: grpc 简写与原生 map

- **WHEN** `grpc` 分别为 `grpc-health 8080`、`grpc-health,8080` 与 `{port: 8080, service: grpc-health}`
- **THEN** 三种形态均以包含 `service` 与 `port` 的 map 委托 `definitions.grpcAction`

#### Scenario: httpGet 简写含 headers

- **WHEN** `httpGet` 为 `HTTPS example.com 8443 /health headers (X-Foo bar)`
- **THEN** 解析出 `scheme`、`host`、`port`、`path` 与 `httpHeaders` 后委托 `definitions.httpGetAction`

#### Scenario: tcpSocket 简写

- **WHEN** `tcpSocket` 为 `example.com 8080` 或仅 `8080`
- **THEN** 解析出可选 `host` 与 `port` 后委托 `definitions.tcpSocketAction`

#### Scenario: 非法简写

- **WHEN** 动作简写不匹配约定格式，或动作值既不是 map 也不是约定简写类型
- **THEN** 渲染中断

### Requirement: integer 字段

`failureThreshold`、`initialDelaySeconds`、`periodSeconds`、`successThreshold`、`terminationGracePeriodSeconds`、`timeoutSeconds` MUST 按整数语义接受原生整数与无小数数值。字符串、布尔、带小数数值、map 与 list MUST 中断渲染；有效值 MUST 以十进制整数输出。

#### Scenario: 整数语义

- **WHEN** 上述字段分别提供 `3` 与 `3.0`
- **THEN** 均输出相同的十进制整数

#### Scenario: 非整数类型

- **WHEN** 上述字段提供字符串 `"3"`、布尔 `true`、带小数数值 `1.5`、map 或 list
- **THEN** 渲染中断

## 非目标

- 不创建 `definitions.grpcAction`，不实现 GRPCAction 的字段校验与渲染。
- 不支持 `sleep` 动作。
