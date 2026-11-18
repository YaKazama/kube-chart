---
updated_at: "2026-11-18T16:06:07Z"
---

# definitions.lifecycleHandler 规格

## Purpose

为 LifecycleHandler 提供统一入口，受理原生 map 或抽象 map，并把单个动作交给对应子模板渲染。

## ADDED Requirements

### Requirement: 单动作输入与动作选择

系统 MUST 仅受理 map 上下文，并 MUST 在 `exec`、`httpGet`、`sleep`、`tcpSocket` 中识别且只处理一个动作。

#### Scenario: 恰好一个动作

- **WHEN** 上下文包含且仅包含四种动作键之一
- **THEN** 系统选择该动作，并按同名动作键输出子模板结果

#### Scenario: 动作缺失或冲突

- **WHEN** 上下文不包含任何动作键，或包含两个及以上动作键
- **THEN** 系统 MUST 中断渲染

#### Scenario: 零值与空集合仍视为已提供

- **WHEN** 所选动作的值为 `0`、空字符串、空数组或空 map
- **THEN** 系统 MUST 按动作键存在处理，不得因值为空而改选其他动作

### Requirement: 原生 map 直接委托

系统 MUST 在动作值为 map 时，将该 map 原样作为对应子模板的上下文，并 MUST 保留额外字段。

#### Scenario: 原生 exec 与 sleep

- **WHEN** `exec` 或 `sleep` 的值是 map
- **THEN** 系统分别以原 map 委托 `definitions.execAction` 或 `definitions.sleepAction`

#### Scenario: 原生 httpGet

- **WHEN** `httpGet` 的值是 map
- **THEN** 系统以原 map 委托 `definitions.httpGetAction`
- **AND** `httpHeaders` MUST 原样传递，不拆分或重写

#### Scenario: 原生 tcpSocket

- **WHEN** `tcpSocket` 的值是 map
- **THEN** 系统以原 map 委托 `definitions.tcpSocketAction`

### Requirement: 抽象 exec 与 sleep 解析

系统 MUST 将 `exec` 的 string array 解析为官方 `command` 字段，并将 `sleep` 的 integer 解析为官方 `seconds` 字段。

#### Scenario: 抽象 exec

- **WHEN** `exec` 的值是 string array
- **THEN** 系统以 `command` 为键构造 map，并委托 `definitions.execAction`

#### Scenario: 抽象 sleep

- **WHEN** `sleep` 的值是 integer
- **THEN** 系统以 `seconds` 为键构造 map，并委托 `definitions.sleepAction`
- **AND** `0` MUST 作为有效值传递

#### Scenario: exec 或 sleep 类型无效

- **WHEN** `exec` 的元素不是 string，或 `sleep` 不是 integer
- **THEN** 系统 MUST 中断渲染

### Requirement: 抽象 httpGet 解析

系统 MUST 按 `[schema] [host] <port> [path] [headers (name value, ...)]` 的位置顺序解析字符串，位置字段之间 MUST 接受空格或逗号分隔，并按官方字段名 `host`、`httpHeaders`、`path`、`port`、`scheme` 构造子模板上下文。

#### Scenario: 完整 httpGet

- **WHEN** `httpGet` 是包含全部位置字段的 string
- **THEN** `schema` MUST 映射为 `scheme`，其余位置分别映射为 `host`、`port`、`path`
- **AND** `headers` 内容 MUST 作为 `httpHeaders` string array 交给 `definitions.httpGetAction`

#### Scenario: 位置缺省

- **WHEN** `httpGet` 字符串未提供某个位置字段
- **THEN** 对应位置 MUST 得到空字符串

#### Scenario: headers 省略或为空

- **WHEN** `headers` 关键字、括号或括号内容缺失
- **THEN** 该位置 MUST 得到空字符串
- **AND** 系统 MUST NOT 设置 `httpHeaders` 字段

#### Scenario: headers 分组

- **WHEN** 括号内容包含多个 `name value` 组
- **THEN** 括号内容 MUST 先以逗号分组，再在每个逗号组内以空格分词
- **AND** 每个逗号组内的每两个连续 token MUST 组成一个 `name value` 字符串，按出现顺序放入 `httpHeaders`
- **AND** 同组 `name value` MUST 只以空格分隔，逗号 MUST NOT 作为同组分隔符
- **AND** `httpHeaders` MUST 交给 `definitions.httpGetAction`，由其进一步转交 `definitions.httpHeader`
- **AND** 系统 MUST NOT 在本层解析或调用 `definitions.httpHeader`

#### Scenario: headers 分组不完整

- **WHEN** 任一逗号组内的 token 数不是偶数，无法按每两个 token 组成完整的 `name value` 组
- **THEN** 系统 MUST 中断渲染

### Requirement: 抽象 tcpSocket 解析

系统 MUST 按 `[host] <port>` 的位置顺序解析字符串，位置字段之间 MUST 接受空格或逗号分隔，并按官方字段名 `host`、`port` 构造子模板上下文。

#### Scenario: 完整 tcpSocket

- **WHEN** `tcpSocket` 是包含 host 和 port 的 string
- **THEN** 系统分别以 `host`、`port` 为键构造 map，并委托 `definitions.tcpSocketAction`

#### Scenario: host 缺省

- **WHEN** `tcpSocket` 字符串只提供 port
- **THEN** `host` MUST 得到空字符串，`port` MUST 保留该值

#### Scenario: tcpSocket 格式无效

- **WHEN** `tcpSocket` 字符串不能按位置格式解析
- **THEN** 系统 MUST 中断渲染

### Requirement: 子模板上下文与输出

系统 MUST 以 map 作为所有子模板的上下文，并 MUST 将子模板输出作为对应动作键的 map 值输出；字段顺序 MUST 与官方文档一致。

#### Scenario: 子模板输出有效

- **WHEN** 子模板返回非空且可解析的 YAML map
- **THEN** 系统以动作键输出该 map

#### Scenario: 子模板输出非法

- **WHEN** 子模板返回的内容不能解析为 YAML map
- **THEN** 系统 MUST 中断渲染

## 非目标

- 不创建 `definitions.execAction`、`definitions.httpGetAction`、`definitions.sleepAction` 和 `definitions.tcpSocketAction`。
- 不解析 `definitions.httpHeader` 中的 `name` 与 `value`。
- 不校验子模板内部字段的 Kubernetes 语义、端口合法性或 Header 内容合法性。
