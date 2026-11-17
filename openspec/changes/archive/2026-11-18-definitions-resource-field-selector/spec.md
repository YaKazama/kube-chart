---
updated_at: "2026-11-17T17:08:27Z"
---

# definitions.resourceFieldSelector 规格

## Purpose

新增共享结构能力 `definitions.resourceFieldSelector`，把单个 map 上下文渲染为 Kubernetes `ResourceFieldSelector` 字段片段，供 `definitions.envVarSource` 的 `resourceFieldRef` 分支使用。

## ADDED Requirements

### Requirement: 字段渲染顺序与类型

系统 MUST 按官方字段顺序渲染 `ResourceFieldSelector` 的 `containerName`、`divisor`、`resource` 三个字段。

- `containerName` MUST 以双引号字符串输出，缺省时不输出。
- `resource` MUST 以双引号字符串输出。
- `divisor` 的无单位整数 MUST 以不带引号的数字标量输出；其余取值 MUST 输出为 YAML 解析后仍为字符串的标量。
- `divisor` 为 cpu 的小数核值时 MUST 换算为整数毫核字符串输出，如 `1.5` 输出 `1500m`。
- `divisor` 缺省时不输出该字段，不补官方默认值 `1`。
- 输入中除这三个字段之外的键静默忽略。

#### Scenario: 三字段齐全

- **WHEN** 输入为 `containerName: app`、`divisor: 2Mi`、`resource: limits.memory`
- **THEN** 输出依次为 `containerName: "app"`、`divisor: 2Mi`、`resource: "limits.memory"`

#### Scenario: 无单位整数 divisor 输出为数字

- **WHEN** `divisor` 为 `1`、`2`，或为字符串 `"2"`
- **THEN** 输出均为不带引号的数字标量，值与输入一致

#### Scenario: cpu 小数 divisor 换算为毫核

- **WHEN** `divisor` 为 `1.5`、`0.05`，或为字符串 `"0.005"`
- **THEN** 输出分别为 `1500m`、`50m`、`5m`，且均为字符串标量

#### Scenario: 带单位 divisor 输出为字符串

- **WHEN** `divisor` 为 `1m`、`500m`、`2Mi` 或 `1Ti`
- **THEN** 输出为对应的字符串标量，值与输入一致

#### Scenario: 可选项缺省

- **WHEN** 输入只有 `resource`
- **THEN** 只输出 `resource`，不含 `containerName` 与 `divisor`

#### Scenario: 额外键忽略

- **WHEN** 输入含三个官方字段与未定义键 `foo`
- **THEN** 输出不含 `foo`

### Requirement: resource 必填与支持列表校验

系统 MUST 要求 `resource` 非空，并限制为 `EnvVarSource.resourceFieldRef` 官方支持的资源名。

- 允许的取值为 `limits.cpu`、`limits.memory`、`limits.ephemeral-storage`、`requests.cpu`、`requests.memory`、`requests.ephemeral-storage`。
- `resource` 缺失或为空白时中断渲染，失败消息 MUST 包含 `resource`。
- 不在支持列表内的取值 MUST 中断渲染，失败消息 MUST 包含实际取值。
- 规则 MUST 由集中定义的固定表达式表达，不在业务模板内内联。

#### Scenario: 六个官方资源名

- **WHEN** `resource` 分别为六个官方资源名
- **THEN** 全部渲染成功并输出该取值

#### Scenario: resource 缺失

- **WHEN** 输入只有 `divisor`
- **THEN** 渲染中断，失败消息包含 `resource`

#### Scenario: resource 为空白

- **WHEN** `resource` 为只含空白的字符串
- **THEN** 渲染中断，失败消息包含 `resource`

#### Scenario: 不在支持列表内

- **WHEN** `resource` 为 `metadata.name` 或 `limits.gpu`
- **THEN** 渲染中断，失败消息包含实际取值

### Requirement: divisor 单位与资源类型匹配

系统 MUST 在 `divisor` 非空后按 `resource` 的类型限制其形态，不限制量级。

- `resource` 以 `.cpu` 结尾时，`divisor` MUST 为无单位整数、无单位小数或整数毫核，如 `1`、`1.5`、`500m`、`1000m`；小数毫核如 `1.5m` MUST 中断渲染。
- `resource` 以 `.memory` 或 `.ephemeral-storage` 结尾时，`divisor` MUST 带字节单位（`Ki`、`Mi`、`Gi`、`Ti`、`Pi`、`Ei`、`k`、`M`、`G`、`T`、`P`、`E`），如 `2Mi`、`128Mi`、`1Gi`、`1Ti`；无单位取值 MUST 中断渲染。
- 形态与资源类型不匹配时 MUST 中断渲染，失败消息 MUST 包含 `divisor`、实际取值与 `resource`。
- `divisor` 为空白时按可选字段未提供处理，不输出该字段。

#### Scenario: cpu 接受核与毫核的任意量级

- **WHEN** `resource: limits.cpu` 且 `divisor` 为 `1`、`1.5`、`2`、`500m`、`1000m`
- **THEN** 全部渲染成功，其中 `1.5` 输出 `1500m`

#### Scenario: cpu 拒绝字节单位与小数毫核

- **WHEN** `resource: limits.cpu` 且 `divisor` 为 `1Ki`、`2Mi` 或 `1.5m`
- **THEN** 渲染中断，失败消息包含 `divisor`

#### Scenario: 内存类接受字节单位的任意量级

- **WHEN** `resource: limits.memory` 或 `requests.ephemeral-storage`，且 `divisor` 为 `2Mi`、`128Mi`、`1Gi`、`1.5Gi`、`1Ti`、`1k`、`1M`、`1G`
- **THEN** 全部渲染成功

#### Scenario: 内存类拒绝无单位取值与毫核

- **WHEN** `resource: requests.memory` 且 `divisor` 为 `1`、`1m` 或 `500m`
- **THEN** 渲染中断，失败消息包含 `divisor`

#### Scenario: 不合法的单位后缀

- **WHEN** `resource: limits.memory` 且 `divisor` 为 `1Xi`
- **THEN** 渲染中断，失败消息包含 `divisor`

## 非目标

- 不渲染 `EnvVarSource` 的其他字段。
- 不实现 `definitions.envVarSource` 的分发逻辑。
- 不兼容 `DownwardAPIVolumeFile` 的资源名扩展。
- 不校验 `containerName` 对应的容器是否真实存在。
