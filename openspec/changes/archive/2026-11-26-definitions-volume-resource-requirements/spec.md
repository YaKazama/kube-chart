---
updated_at: "2026-11-26T14:12:19Z"
---

# definitions.volumeResourceRequirements 规格

## Purpose

为 Kubernetes VolumeResourceRequirements 提供可复用的 YAML 字段片段渲染能力，并为集合类 Quantity 提供可复用的数值比较能力。

## ADDED Requirements

### Requirement: VolumeResourceRequirements 字段渲染

`definitions.volumeResourceRequirements` MUST 以原生 map 为上下文，按 `limits`、`requests` 的官方字段顺序渲染 VolumeResourceRequirements 字段片段，忽略契约以外的字段，按原值输出通过校验的 Quantity，并在 `requests` 超过 `limits` 时中断渲染。

#### Scenario: 完整输出

- **WHEN** `limits` 与 `requests` 均包含资源 `storage`，且 `requests.storage` 不超过 `limits.storage`
- **THEN** 输出依次为 `limits`、`requests`，各 Quantity 保持输入原值

#### Scenario: 单字段输出

- **WHEN** 仅 `requests` 或仅 `limits` 包含非空资源映射
- **THEN** 只输出存在且非空的字段

#### Scenario: 空 map 省略

- **WHEN** `limits` 或 `requests` 缺失、为 `null` 或为空 map
- **THEN** 不输出该字段，也不补默认值

#### Scenario: 非共同键不参与比较

- **WHEN** `requests` 含有一个 `limits` 中不存在的资源键
- **THEN** 不对该键进行比较，两个字段仍正常输出

#### Scenario: requests 超过 limits

- **WHEN** 两侧同时存在的资源键中，`requests` 换算后的数值大于 `limits`
- **THEN** 渲染中断，失败消息以 `[definitions.volumeResourceRequirements]` 开头并指明资源键

#### Scenario: 非法 Quantity

- **WHEN** `limits` 或 `requests` 的任一值不是合法 Quantity
- **THEN** 渲染中断

#### Scenario: 非 map 类型

- **WHEN** `limits` 或 `requests` 不是 object 类型
- **THEN** 渲染中断

### Requirement: Quantity 数值比较

`base.quantity.ge` MUST 接受两个 Quantity 字符串，按各自换算后的数值进行比较，首个大于或等于第二个时返回 `true`，其他返回 `false`；任一参数不是合法 Quantity 时中断渲染。

#### Scenario: 等价单位

- **WHEN** 比较 `1Gi` 与 `1024Mi`
- **THEN** 返回 `true`

#### Scenario: 数值较大

- **WHEN** 比较 `2Gi` 与 `1Gi`
- **THEN** 返回 `true`

#### Scenario: 数值较小

- **WHEN** 比较 `500m` 与 `1`
- **THEN** 返回 `false`

#### Scenario: 非法 Quantity

- **WHEN** 任一参数不是合法 Quantity
- **THEN** 渲染中断

## 非目标

- 不改变 `definitions.resourceRequirements` 等其他定义模板。
