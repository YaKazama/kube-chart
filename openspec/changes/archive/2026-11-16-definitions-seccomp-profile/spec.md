---
updated_at: "2026-11-15T16:30:40Z"
---

# SeccompProfile 共享结构规格

## Purpose

提供可复用的 `definitions.seccompProfile` 模板，把 seccomp 配置输入渲染为 Kubernetes v1.36 `SeccompProfile` 字段片段。

## ADDED Requirements

### Requirement: 渲染 SeccompProfile 字段片段

系统 MUST 按 Kubernetes v1.36 `SeccompProfile` 字段顺序输出 `localhostProfile`、`type`。

系统 MUST 只输出取值生效的字段。

`type` 与生效的 `localhostProfile` 取值 MUST 去除首尾空白，判空、枚举校验与输出 MUST 都使用去除后的结果。

系统 MUST NOT 输出 `SeccompProfile` 父键、`seccompProfile` 键、`apiVersion` 或 `kind`。

输入中除 `type`、`localhostProfile` 以外的键 MUST 静默忽略，既不影响输出也不触发失败。

#### Scenario: 仅 type

- **WHEN** 输入为 `{type: RuntimeDefault}`
- **THEN** 输出只包含 `type`

#### Scenario: 完整输入

- **WHEN** 输入为 `{type: Localhost, localhostProfile: profiles/a.json}`
- **THEN** 输出按 `localhostProfile`、`type` 顺序包含两个字段

#### Scenario: 首尾空白被去除

- **WHEN** 输入为 `{type: " Localhost ", localhostProfile: "  profiles/a.json  "}`
- **THEN** 输出取值为 `Localhost` 与 `profiles/a.json`

#### Scenario: 忽略范围外键

- **WHEN** 输入为 `{type: RuntimeDefault, foo: bar}`
- **THEN** 输出只包含 `type`

### Requirement: type 必填与枚举校验

`type` 为必填字段；缺失、`null`、空字符串或只含空白时 MUST 中断渲染。

`type` MUST 只接受 `Localhost`、`RuntimeDefault`、`Unconfined`，比较 MUST 大小写敏感。

`type` 去除首尾空白后不在允许范围时 MUST 中断渲染，且错误信息 MUST 给出合法取值。

`type` 不是 string 时 MUST 中断渲染，MUST NOT 把数字、布尔、map 或 array 归一化为 string。

#### Scenario: type 缺失

- **WHEN** 输入为 `{localhostProfile: profiles/a.json}`
- **THEN** 渲染中断

#### Scenario: type 为 null

- **WHEN** 输入为 `{type: null}`
- **THEN** 渲染中断

#### Scenario: type 为空字符串

- **WHEN** 输入为 `{type: ""}`
- **THEN** 渲染中断

#### Scenario: type 只含空白

- **WHEN** 输入为 `{type: "   "}`
- **THEN** 渲染中断

#### Scenario: 大小写变体

- **WHEN** 输入为 `{type: localhost}` 或 `{type: RUNTIMEDEFAULT}`
- **THEN** 渲染中断，错误信息给出合法取值

#### Scenario: 超出枚举

- **WHEN** 输入为 `{type: Bogus}`
- **THEN** 渲染中断，错误信息给出合法取值

#### Scenario: 首尾空白后命中枚举

- **WHEN** 输入为 `{type: " Localhost ", localhostProfile: profiles/a.json}`
- **THEN** 渲染成功且输出 `type` 取值为 `Localhost`

#### Scenario: 类型非法

- **WHEN** `type` 为 `123`、`true`、`{a: b}` 或 `[a]`
- **THEN** 渲染中断

### Requirement: localhostProfile 条件渲染

`type` 为 `Localhost` 时 `localhostProfile` MUST 必填；缺失、`null`、空字符串或只含空白时 MUST 中断渲染。

`type` 为 `RuntimeDefault` 或 `Unconfined` 时，系统 MUST NOT 读取、校验或输出 `localhostProfile`。

#### Scenario: Localhost 缺失 localhostProfile

- **WHEN** 输入为 `{type: Localhost}`
- **THEN** 渲染中断

#### Scenario: Localhost 空字符串

- **WHEN** 输入为 `{type: Localhost, localhostProfile: ""}`
- **THEN** 渲染中断

#### Scenario: Localhost 只含空白

- **WHEN** 输入为 `{type: Localhost, localhostProfile: "   "}`
- **THEN** 渲染中断

#### Scenario: Localhost 类型非法

- **WHEN** 输入为 `{type: Localhost, localhostProfile: 123}`
- **THEN** 渲染中断

#### Scenario: 非 Localhost 不输出 localhostProfile

- **WHEN** 输入为 `{type: RuntimeDefault, localhostProfile: profiles/a.json}`
- **THEN** 渲染成功且输出只包含 `type`

#### Scenario: 非 Localhost 不校验 localhostProfile

- **WHEN** 输入为 `{type: Unconfined, localhostProfile: {a: b}}`
- **THEN** 渲染成功且输出只包含 `type`

### Requirement: 字段值输出形态

系统 MUST 以双引号包裹每个输出的字段值。

#### Scenario: 常规取值带引号

- **WHEN** 输入为 `{type: RuntimeDefault}`
- **THEN** 输出为 `type: "RuntimeDefault"`

#### Scenario: YAML 布尔字面量保持字符串

- **WHEN** 输入为 `{type: Localhost, localhostProfile: "on"}`
- **THEN** 输出为 `localhostProfile: "on"`，且回读后 `localhostProfile` 仍为 string

## 非目标

- 不实现 `SeccompProfile` 以外的安全上下文结构或字段。
- 不校验 `localhostProfile` 指向的配置文件路径在设计节点上是否真实存在。
