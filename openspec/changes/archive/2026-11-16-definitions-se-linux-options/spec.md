---
updated_at: "2026-11-15T15:50:44Z"
---

# SELinuxOptions 共享结构规格

## Purpose

提供可复用的 `definitions.seLinuxOptions` 模板，把 SELinux 标签输入渲染为 Kubernetes v1.36 `SELinuxOptions` 字段片段。

## ADDED Requirements

### Requirement: 渲染 SELinuxOptions 字段片段

系统 MUST 按 Kubernetes `SELinuxOptions` 字段顺序输出 `level`、`role`、`type`、`user`。

四个字段均为可选；系统 MUST 只输出取值生效的字段。

四个字段均不生效时，系统 MUST 返回空内容而不失败。

系统 MUST NOT 输出 `SELinuxOptions` 父键、`seLinuxOptions` 键、`apiVersion` 或 `kind`。

输入中除四个字段以外的键 MUST 静默忽略。

#### Scenario: 完整输入

- **WHEN** 输入为 `{level: s0, role: sysadm_r, type: container_t, user: system_u}`
- **THEN** 输出按 `level`、`role`、`type`、`user` 顺序包含四个字段，且取值与输入一致

#### Scenario: 部分字段

- **WHEN** 输入为 `{level: s0, type: container_t}`
- **THEN** 输出只包含 `level` 与 `type`，顺序为 `level` 在 `type` 之前

#### Scenario: 全部缺失

- **WHEN** 输入为 `{}`
- **THEN** 输出为空内容且渲染成功

#### Scenario: 忽略范围外键

- **WHEN** 输入为 `{level: s0, foo: bar}`
- **THEN** 输出只包含 `level`

### Requirement: 字段取值与空值跳过

系统 MUST 把四个字段都按 string 处理：缺失、`null`、空字符串或只含空白时 MUST 跳过该字段。

字段值为 string 时，系统 MUST 先去除首尾空白，判断与输出 MUST 都使用去除后的结果。

字段值不是 string 时，系统 MUST 中断渲染，MUST NOT 把数字、布尔、map 或 array 归一化为 string。

#### Scenario: 空字符串跳过

- **WHEN** 输入为 `{level: "", role: sysadm_r}`
- **THEN** 渲染成功且输出只包含 `role`

#### Scenario: 只含空白跳过

- **WHEN** 输入为 `{level: "   ", user: system_u}`
- **THEN** 渲染成功且输出只包含 `user`

#### Scenario: null 跳过

- **WHEN** 输入为 `{level: null, role: sysadm_r}`
- **THEN** 渲染成功且输出只包含 `role`

#### Scenario: 全部不生效

- **WHEN** 输入为 `{level: "", role: "   ", type: null}`
- **THEN** 输出为空内容且渲染成功

#### Scenario: 首尾空白被去除

- **WHEN** 输入为 `{level: "  s0  "}`
- **THEN** 输出取值为去除首尾空白后的 `s0`

#### Scenario: 字段类型非法

- **WHEN** 输入中任一字段为 `123`、`true`、`{a: b}` 或 `[a]`
- **THEN** 渲染中断

### Requirement: 字段值输出形态

系统 MUST 以双引号包裹每个输出的字段值。

#### Scenario: 常规取值带引号

- **WHEN** 输入为 `{level: s0}`
- **THEN** 输出为 `level: "s0"`

#### Scenario: YAML 布尔字面量保持字符串

- **WHEN** 输入为 `{level: "on", role: "yes", type: "true"}`
- **THEN** 输出为 `level: "on"`、`role: "yes"`、`type: "true"`，且回读后三者均为 string

## 非目标

- 不实现 `SELinuxOptions` 以外的安全上下文结构或字段。
- 不校验 SELinux 标签取值是否符合特定策略规范。
