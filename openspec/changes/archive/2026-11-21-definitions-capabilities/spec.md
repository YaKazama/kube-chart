---
updated_at: "2026-11-21T14:30:52Z"
---

# definitions.capabilities 规格

## Purpose

为 Kubernetes `Capabilities` 结构提供可嵌入的 YAML 字段片段渲染，供 `definitions.securityContext` 的 `capabilities` 字段委托。

## ADDED Requirements

### Requirement: 字段顺序与字段生效

系统 MUST 按 Kubernetes 官方字段顺序渲染 `add`、`drop`；未提供的字段不输出，两者均无有效内容时输出空内容。

#### Scenario: 同时提供 add 与 drop

- **WHEN** 输入同时包含非空的 `add` 与 `drop`
- **THEN** 输出中 `add` 位于 `drop` 之前

#### Scenario: 仅提供单个字段

- **WHEN** 输入仅包含 `add` 或仅包含 `drop`
- **THEN** 只输出该字段

#### Scenario: 无有效内容

- **WHEN** `add`、`drop` 均缺失、为 null、为空数组或为空字符串
- **THEN** 输出空内容

### Requirement: capability 名称校验与归一

系统 MUST 仅接受由 ASCII 字母、数字与下划线组成、首字符为字母的 capability 名称；`CAP_` 前缀可选且大小写不敏感。校验通过后统一以大写输出，输入包含 `CAP_` 前缀时保留，不包含时不补充。

#### Scenario: 小写与可选前缀

- **WHEN** 输入为 `cap_net_admin` 或 `net_admin`
- **THEN** 分别输出 `CAP_NET_ADMIN` 与 `NET_ADMIN`

#### Scenario: 非法名称

- **WHEN** 拆分后的名称包含 `-` 或其他非字母数字下划线字符，或以数字开头
- **THEN** 渲染中断

### Requirement: 数组拆分与去重

系统 MUST 将每个字符串元素按分号、逗号或空白拆分为多个 capability，移除空项，并在归一化后去重。

#### Scenario: 复合字符串

- **WHEN** 输入包含 `NET_ADMIN; SYS_TIME`
- **THEN** 输出 `NET_ADMIN` 与 `SYS_TIME` 两个列表项

#### Scenario: 归一化后重复

- **WHEN** 输入同时包含 `net_admin` 与 `NET_ADMIN`
- **THEN** 输出仅包含一个 `NET_ADMIN`

### Requirement: 输入类型边界

系统 MUST 将缺失、null、空字符串或空数组视为未提供；其余输入必须为 string array，非数组输入或包含非 string 元素时中断渲染。

#### Scenario: 非数组输入

- **WHEN** `add` 为非空字符串或 map
- **THEN** 渲染中断

#### Scenario: 非 string 元素

- **WHEN** `add` 包含布尔、数字、map 或 null 元素
- **THEN** 渲染中断

## 非目标

- 不校验 capability 是否存在于当前内核或运行时，不拦截符合名称规则的拼写错误。
