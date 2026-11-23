---
updated_at: "2026-11-23T16:36:31Z"
---

# definitions.keyToPath 规格

## Purpose

为 VolumeSource 的 KeyToPath 数组元素提供共享渲染能力，把 `{key, path, mode}` map 转换为符合 Kubernetes 语义的字段片段。

## ADDED Requirements

### Requirement: KeyToPath 输入与字段顺序

本能力 MUST 以 `definitions.keyToPath` 命名模板提供，MUST 接受 map 上下文，其他类型 MUST 中断。

系统 MUST 只读取 `key`、`path`、`mode` 三个字段，其他字段 MUST 静默忽略。`key` 与 `path` 必填，`mode` 可选。系统 MUST 按 `key`、`mode`、`path` 的顺序输出已生效字段；字段缺失、空字符串或错误类型 MUST 中断，`mode` 空值按未提供处理。

#### Scenario: 最小输入

- **WHEN** 输入 `{key: "LOG_LEVEL", path: "app/config.conf"}`
- **THEN** 只输出 `key` 与 `path`

#### Scenario: 包含 mode

- **WHEN** 输入 `{key: "LOG_LEVEL", path: "app/config.conf", mode: "0400"}`
- **THEN** 按 `key`、`mode`、`path` 顺序输出三个字段

#### Scenario: 非 map 或错误类型

- **WHEN** 上下文不是 map，或字段类型错误
- **THEN** 渲染中断

### Requirement: key 校验

`key` MUST 非空，且 MUST 只包含字母、数字、`-`、`_`、`.`；不限制首尾字符与长度。空值或非法字符 MUST 中断，合法值 MUST 以带引号标量输出。

#### Scenario: 合法 key

- **WHEN** `key` 为 `LOG_LEVEL`、`app.config` 或 `key-1`
- **THEN** 以带引号标量输出

#### Scenario: 空 key

- **WHEN** `key` 缺失、为 `null` 或 trim 后为空
- **THEN** 渲染中断

#### Scenario: 非法字符

- **WHEN** `key` 含空格、`/` 或其他字符集外字符
- **THEN** 渲染中断

### Requirement: path 归一化

`path` MUST 非空，MUST 归一化为相对路径：解析 `.` 与 `..` 段并去除多余分隔符；绝对路径 MUST 中断；归一化结果 MUST NOT 为 `..`，也 MUST NOT 以 `../` 开头。合法值 MUST 以带引号标量输出。

#### Scenario: 归一化为相对路径

- **WHEN** `path` 为 `a/../b` 或 `./app//config.conf`
- **THEN** 分别输出 `b` 与 `app/config.conf`

#### Scenario: 绝对路径

- **WHEN** `path` 以 `/` 开头
- **THEN** 渲染中断

#### Scenario: 前导 `..`

- **WHEN** 归一化结果为 `..` 或以 `../` 开头
- **THEN** 渲染中断

#### Scenario: 空 path

- **WHEN** `path` 缺失、为 `null` 或 trim 后为空
- **THEN** 渲染中断

### Requirement: mode 归一化

`mode` MUST 接受八进制 `0000`-`0777` 或十进制 `0`-`511`，并 MUST 输出十进制 int。`mode` 缺失或为空时 MUST NOT 输出；越界或非法值 MUST 中断。

#### Scenario: 八进制 mode

- **WHEN** `mode` 为 `"0400"`
- **THEN** 输出 `mode: 256`

#### Scenario: 十进制 mode

- **WHEN** `mode` 为数值或字符串 `493`
- **THEN** 输出 `mode: 493`

#### Scenario: 非法 mode

- **WHEN** `mode` 为 `"0778"`、数值 `512` 或其他非模式值
- **THEN** 渲染中断
