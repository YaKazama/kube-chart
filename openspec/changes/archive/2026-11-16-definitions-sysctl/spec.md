---
updated_at: "2026-11-15T17:17:49Z"
---

# Sysctl 共享结构规格

## Purpose

提供可复用的 `definitions.sysctl` 模板，把内核参数配置渲染为 Kubernetes v1.36 `Sysctl` 字段片段。

## ADDED Requirements

### Requirement: 渲染 Sysctl 字段片段

系统 MUST 按 Kubernetes v1.36 `Sysctl` 字段顺序输出 `name`、`value`。

系统 MUST NOT 输出 `Sysctl` 父键、`sysctls` 键、`apiVersion` 或 `kind`。

返回值 MUST 是可被父级按 YAML 解析为 map 的字段片段。

输入中除 `name`、`value` 及两者同级别名以外的键 MUST 静默忽略，既不影响输出也不触发失败。

系统 MUST 支持同级 `<字段>Alias` 别名：别名存在且非空时优先于同规范键，视为合法输入而非范围外键。

#### Scenario: 完整输入

- **WHEN** 输入为 `{name: net.ipv4.ip_forward, value: "0"}`
- **THEN** 输出按 `name`、`value` 顺序包含两个字段，且取值与输入一致

#### Scenario: 忽略范围外键

- **WHEN** 输入为 `{name: net.ipv4.ip_forward, value: "0", foo: bar}`
- **THEN** 输出只包含 `name` 与 `value`

#### Scenario: 别名优先于规范键

- **WHEN** 输入为 `{name: kernel.x, value: "1", valueAlias: "2"}`
- **THEN** 输出为 `value: "2"`

#### Scenario: 仅提供别名

- **WHEN** 输入为 `{nameAlias: kernel.x, valueAlias: "2"}`
- **THEN** 输出为 `name: "kernel.x"` 与 `value: "2"`

#### Scenario: 返回值可被回收

- **WHEN** 输入合法
- **THEN** 输出可被父级解析为 map，且不含 `name`、`value` 之外的键

### Requirement: 必填与类型校验

`name` 必填；缺失、`null`、空字符串或只含空白时 MUST 中断渲染。

`value` 必填；`value` 与 `valueAlias` 均未提供时 MUST 中断渲染，两者仅提供其一时不视为缺失。

`value` 为 `null` 时 MUST 视为空值，与空字符串同等处理，MUST NOT 因 `null` 中断渲染。

两个字段 MUST 为 string；为数字、布尔、map 或 array 时 MUST 中断渲染，MUST NOT 归一化为 string。

#### Scenario: name 缺失

- **WHEN** 输入为 `{value: "0"}`
- **THEN** 渲染中断

#### Scenario: name 为 null

- **WHEN** 输入为 `{name: null, value: "0"}`
- **THEN** 渲染中断

#### Scenario: name 为空字符串

- **WHEN** 输入为 `{name: "", value: "0"}`
- **THEN** 渲染中断

#### Scenario: name 只含空白

- **WHEN** 输入为 `{name: "   ", value: "0"}`
- **THEN** 渲染中断

#### Scenario: name 类型非法

- **WHEN** `name` 为 `123`、`true`、`{a: b}` 或 `[a]`
- **THEN** 渲染中断

#### Scenario: value 与 valueAlias 均缺失

- **WHEN** 输入为 `{name: net.ipv4.ip_forward}` 且未提供 `valueAlias`
- **THEN** 渲染中断

#### Scenario: 仅提供 valueAlias

- **WHEN** 输入为 `{name: net.ipv4.ip_forward, valueAlias: "0"}`
- **THEN** 渲染成功且输出 `value: "0"`

#### Scenario: value 为 null

- **WHEN** 输入为 `{name: net.ipv4.ip_forward, value: null}`
- **THEN** 渲染成功且输出 `value: ""`

#### Scenario: value 类型非法

- **WHEN** `value` 为 `0`、`true`、`{a: b}` 或 `[a]`
- **THEN** 渲染中断

### Requirement: 取值与输出形态

两个字段的判空、引号判定与输出 MUST 使用去除首尾空白后的结果。

`name` MUST 恒以双引号包裹。

`value` 在不加引号会被 YAML 解析为非 string 时 MUST 以双引号包裹；否则 MUST 不加引号。

`value` 去除首尾空白后为空或输入为 `null` 时 MUST 输出带双引号的空字符串 `value: ""`。

`value` 取字符串 `null` 时 MUST 作为普通字符串处理，MUST NOT 视为空值。

输出的 `value` 在父级回收后 MUST 仍为 string。

#### Scenario: name 恒带引号

- **WHEN** 输入为 `{name: net.ipv4.ip_forward, value: "0"}`
- **THEN** 输出为 `name: "net.ipv4.ip_forward"`

#### Scenario: 普通字符串不加引号

- **WHEN** 输入为 `{name: kernel.domainname, value: abc}`
- **THEN** 输出为 `value: abc`

#### Scenario: 数字字面量带引号

- **WHEN** 输入为 `{name: net.ipv4.ip_forward, value: "0"}`
- **THEN** 输出为 `value: "0"`

#### Scenario: 布尔字面量带引号

- **WHEN** 输入为 `{name: kernel.x, value: "true"}` 或 `{name: kernel.x, value: "on"}`
- **THEN** 输出分别为 `value: "true"` 与 `value: "on"`

#### Scenario: 前导零取值不被改写

- **WHEN** 输入为 `{name: kernel.x, value: "007"}`
- **THEN** 输出为 `value: "007"`，取值与输入一致

#### Scenario: 空字符串输出显式空串

- **WHEN** 输入为 `{name: kernel.x, value: ""}`
- **THEN** 输出为 `value: ""`，且渲染成功

#### Scenario: 只含空白输出显式空串

- **WHEN** 输入为 `{name: kernel.x, value: "   "}`
- **THEN** 输出为 `value: ""`，且渲染成功

#### Scenario: null 取值输出显式空串

- **WHEN** 输入为 `{name: kernel.x, value: null}`
- **THEN** 输出为 `value: ""`，且渲染成功

#### Scenario: 字符串 null 正常渲染

- **WHEN** 输入为 `{name: kernel.x, value: "null"}`
- **THEN** 输出为 `value: "null"`，与 `null` 取值结果不同

#### Scenario: 首尾空白被去除

- **WHEN** 输入为 `{name: " kernel.x ", value: "  1  "}`
- **THEN** 输出取值为 `kernel.x` 与 `1`

#### Scenario: 取值回读仍为字符串

- **WHEN** 输入为 `{name: kernel.x, value: "0"}`
- **THEN** 父级回收后 `value` 仍为 string

## 非目标

- 不实现 `Sysctl` 以外的安全上下文结构或字段。
- 不校验 `name` 的内核参数命名格式，也不校验 `value` 的取值范围。
- 不校验目标节点是否启用对应内核参数。
