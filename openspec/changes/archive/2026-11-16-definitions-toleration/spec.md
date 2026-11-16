---
updated_at: "2026-11-16T04:31:47Z"
---

# definitions.toleration 规格

## Purpose

按 Kubernetes `Toleration` 结构渲染单条容忍规则字段片段，供 `PodSpec` 的 `tolerations` 数组逐项复用。

## ADDED Requirements

### Requirement: Toleration 字段片段渲染

系统 MUST 以单个 map 作为上下文，按 `effect`、`key`、`operator`、`tolerationSeconds`、`value` 的固定顺序渲染 Toleration 字段片段，并返回可解析为 map 的 YAML 内容。

五个字段全部可选。`effect`、`key`、`operator`、`value` 为字符串字段，`tolerationSeconds` 为整数字段。

#### Scenario: 渲染完整结构

- **WHEN** 上下文提供五个字段且取值合法
- **THEN** 输出按固定顺序包含全部字段，四个字符串字段为 YAML 字符串，`tolerationSeconds` 为 YAML 整数

#### Scenario: 仅提供部分字段

- **WHEN** 上下文只提供其中一部分字段且组合合法
- **THEN** 输出只包含已提供的字段，且顺序仍为固定顺序

#### Scenario: 上下文缺省

- **WHEN** 上下文不包含任何受支持字段
- **THEN** 模板正常渲染并返回空内容

#### Scenario: 未知字段

- **WHEN** 上下文包含上述五个字段以外的键
- **THEN** 该键被忽略，不参与输出

#### Scenario: effect 为空值

- **WHEN** `effect` 为 `null`、空字符串或仅含空白
- **THEN** 不输出该字段，且不中断渲染

#### Scenario: effect 枚举越界

- **WHEN** `effect` 归一后的取值不是 `NoExecute`、`NoSchedule`、`PreferNoSchedule` 之一
- **THEN** 渲染中断，失败消息给出合法取值范围

#### Scenario: key 与 value 为空值

- **WHEN** `key` 或 `value` 为 `null`、空字符串或仅含空白
- **THEN** 不输出该字段，且不中断渲染

#### Scenario: operator 省略或为空值

- **WHEN** `operator` 未提供、为 `null`、空字符串或仅含空白
- **THEN** 不输出该字段，不填充官方默认值 `Equal`

#### Scenario: operator 枚举越界

- **WHEN** `operator` 归一后的取值不是 `Equal`、`Exists`、`Gt`、`Lt` 之一
- **THEN** 渲染中断，失败消息给出合法取值范围

#### Scenario: operator 大小写敏感

- **WHEN** `operator` 取值为 `exists`、`equal`、`gt`、`lt` 等非精确匹配形式
- **THEN** 渲染中断，不做大小写归一化

#### Scenario: 字符串字段类型非法

- **WHEN** `effect`、`key`、`operator` 或 `value` 为 map、list、布尔或数值
- **THEN** 渲染中断，不做类型归一化

#### Scenario: tolerationSeconds 为整数

- **WHEN** `tolerationSeconds` 为原生整数，包括 `0` 与负数
- **THEN** 输出该字段，取值与输入一致，`0` 与负数均不被改写

#### Scenario: tolerationSeconds 类型非法

- **WHEN** `tolerationSeconds` 为字符串、布尔、map 或 list
- **THEN** 渲染中断，不做类型归一化

### Requirement: key、operator 与 value 互斥校验

系统 MUST 在 `key`、`operator`、`value` 至少一个有值时校验三者组合，违反以下任一规则即中断渲染；三者均无值时 MUST 跳过该校验。

#### Scenario: key 为空要求 operator 为 Exists

- **WHEN** `key` 为空且 `operator` 不是 `Exists`，包括 `operator` 省略的情况
- **THEN** 渲染中断

#### Scenario: key 非空不限制 operator

- **WHEN** `key` 非空且 `operator` 取 `Equal`、`Gt`、`Lt` 或省略
- **THEN** 互斥校验通过，`value` 可为空或非空

#### Scenario: Exists 要求 value 为空

- **WHEN** `operator` 为 `Exists` 且 `value` 非空
- **THEN** 渲染中断

#### Scenario: Gt 与 Lt 要求 value 非空

- **WHEN** `operator` 为 `Gt` 或 `Lt` 且 `value` 为空
- **THEN** 渲染中断

#### Scenario: Exists 与空 value 合法

- **WHEN** `operator` 为 `Exists` 且 `value` 为空
- **THEN** 互斥校验通过，输出不包含 `value` 字段

## 非目标

- 不处理 Schema。
- 不校验 `tolerationSeconds` 与 `effect` 的配合关系；官方说明中该字段仅在 `NoExecute` 下生效，由集群处理。
- 不填充官方默认值，`operator` 省略时不输出 `Equal`。
