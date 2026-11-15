---
updated_at: "2026-11-15T15:38:13Z"
---

# AppArmorProfile 共享结构规格

## Purpose

提供可复用的 `definitions.appArmorProfile` 模板，把 AppArmor 配置输入渲染为 Kubernetes v1.36 `AppArmorProfile` 字段片段。

## ADDED Requirements

### Requirement: 渲染 AppArmorProfile 字段片段

系统 MUST 按 Kubernetes `AppArmorProfile` 字段顺序输出 `localhostProfile` 与 `type`。

系统 MUST 输出 `type`；`localhostProfile` 按适用条件输出。

系统 MUST NOT 输出 `AppArmorProfile` 父键、`appArmorProfile` 键、`apiVersion` 或 `kind`。

输入中除 `localhostProfile` 与 `type` 以外的键 MUST 静默忽略。

#### Scenario: Localhost 完整输入

- **WHEN** 输入为 `{type: Localhost, localhostProfile: k8s-apparmor-example-deny-write}`
- **THEN** 输出先包含 `localhostProfile` 后包含 `type`，且取值与输入一致

#### Scenario: 仅 type

- **WHEN** 输入为 `{type: RuntimeDefault}`
- **THEN** 输出只包含 `type: RuntimeDefault`

#### Scenario: 忽略范围外键

- **WHEN** 输入为 `{type: Unconfined, foo: bar}`
- **THEN** 输出只包含 `type: Unconfined`

### Requirement: type 必填与枚举校验

系统 MUST 把 `type` 视为必填字段：缺失、`null` 或空字符串 MUST 中断渲染。

`type` 为 string 时，系统 MUST 先去除首尾空白再参与判断与输出；去除后为空字符串时 MUST 视为空值。

`type` 不是 string 时，系统 MUST 中断渲染，MUST NOT 把数字、布尔、map 或 array 归一化为 string。

`type` 为 string 时，系统 MUST 只接受 `Localhost`、`RuntimeDefault`、`Unconfined` 三个取值，且比较 MUST 大小写敏感；其他 string 取值 MUST 中断渲染，失败信息 MUST 给出合法范围。

#### Scenario: 三个合法取值

- **WHEN** `type` 依次为 `Localhost`、`RuntimeDefault`、`Unconfined`
- **THEN** 每次渲染成功且输出包含该取值

#### Scenario: type 大小写变体

- **WHEN** 输入为 `{type: localhost}` 或 `{type: RUNTIMEDEFAULT}`
- **THEN** 渲染中断，失败信息包含 `Localhost`、`RuntimeDefault` 与 `Unconfined`

#### Scenario: type 缺失

- **WHEN** 输入为 `{}`
- **THEN** 渲染中断

#### Scenario: type 为 null

- **WHEN** 输入为 `{type: null}`
- **THEN** 渲染中断

#### Scenario: type 为空字符串

- **WHEN** 输入为 `{type: ""}`
- **THEN** 渲染中断

#### Scenario: type 非法字面量

- **WHEN** 输入为 `{type: Disabled}`
- **THEN** 渲染中断，失败信息包含 `Disabled` 与三个合法取值

#### Scenario: type 只含空白

- **WHEN** 输入为 `{type: "   "}`
- **THEN** 渲染中断，与空字符串同样按必填失败处理

#### Scenario: type 首尾带空白

- **WHEN** 输入为 `{type: "  Localhost  "}`
- **THEN** 渲染成功，输出为 `type: Localhost`

#### Scenario: type 非 string 类型

- **WHEN** 输入为 `{type: 123}` 或 `{type: true}`
- **THEN** 渲染中断

### Requirement: localhostProfile 条件渲染

系统 MUST 只在 `type` 为 `Localhost` 时输出 `localhostProfile`。

`localhostProfile` 为 string 时，系统 MUST 先去除首尾空白再参与判断与输出；去除后为空字符串时 MUST 视为空值。

`type` 为 `Localhost` 且 `localhostProfile` 缺失、`null` 或空字符串时，系统 MUST 中断渲染。

`type` 为 `Localhost` 且 `localhostProfile` 不是 string 时，系统 MUST 中断渲染，MUST NOT 把数字、布尔、map 或 array 归一化为 string。

`type` 不是 `Localhost` 时，系统 MUST 忽略 `localhostProfile`：既不输出该字段，也不因该字段缺失或类型非法而失败。

#### Scenario: Localhost 缺少 localhostProfile

- **WHEN** 输入为 `{type: Localhost}`
- **THEN** 渲染中断

#### Scenario: Localhost 的 localhostProfile 为 null

- **WHEN** 输入为 `{type: Localhost, localhostProfile: null}`
- **THEN** 渲染中断

#### Scenario: Localhost 的 localhostProfile 为空字符串

- **WHEN** 输入为 `{type: Localhost, localhostProfile: ""}`
- **THEN** 渲染中断

#### Scenario: localhostProfile 类型非法

- **WHEN** 输入为 `{type: Localhost, localhostProfile: 123}`
- **THEN** 渲染中断

#### Scenario: localhostProfile 只含空白

- **WHEN** 输入为 `{type: Localhost, localhostProfile: "   "}`
- **THEN** 渲染中断，与空字符串同样处理

#### Scenario: localhostProfile 首尾带空白

- **WHEN** 输入为 `{type: Localhost, localhostProfile: "  prof  "}`
- **THEN** 渲染成功，输出取值为去除首尾空白后的 `prof`

#### Scenario: 非 Localhost 时忽略 localhostProfile

- **WHEN** 输入为 `{type: RuntimeDefault, localhostProfile: prof}`
- **THEN** 渲染成功且输出只包含 `type: RuntimeDefault`

#### Scenario: 非 Localhost 时忽略非法 localhostProfile

- **WHEN** 输入为 `{type: Unconfined, localhostProfile: 123}`
- **THEN** 渲染成功且输出只包含 `type: Unconfined`

## 非目标

- 不实现 `AppArmorProfile` 以外的安全上下文结构或字段。
