---
updated_at: "2026-11-28T10:23:27Z"
---

# definitions.serviceAccountTokenProjection 规格

## Purpose

为 Kubernetes `ServiceAccountTokenProjection` 提供共享结构渲染能力，供 `definitions.volumeProjection` 等上层模板复用。

## ADDED Requirements

### Requirement: ServiceAccountTokenProjection 字段渲染

系统 MUST 按 Kubernetes `ServiceAccountTokenProjection` 官方字段顺序渲染原生 map 输入，只读取 `audience`、`expirationSeconds`、`path`，其他字段静默忽略。

#### Scenario: 仅提供 path

- **WHEN** 输入为 `{path: "token"}`
- **THEN** 输出仅包含 `path: "token"`

#### Scenario: 完整字段按官方顺序渲染

- **WHEN** 输入同时包含合法的 `audience`、`expirationSeconds` 和 `path`
- **THEN** 输出依次为 `audience`、`expirationSeconds`、`path`

#### Scenario: audience 为空

- **WHEN** `audience` 缺失、为 null、空字符串或仅空白字符串
- **THEN** 不输出 `audience`

#### Scenario: audience 非法

- **WHEN** `audience` 不是字符串
- **THEN** 中断渲染

#### Scenario: path 缺失或为空

- **WHEN** `path` 缺失、为 null、空字符串或仅空白字符串
- **THEN** 中断渲染并报告 `path` 为必填字段

#### Scenario: path 不是相对路径

- **WHEN** `path` 为绝对路径
- **THEN** 中断渲染

#### Scenario: path 逃逸挂载点

- **WHEN** `path` 经相对路径归一化后为 `..` 或以 `../` 开头
- **THEN** 中断渲染

#### Scenario: path 归一化

- **WHEN** `path` 包含可消解的 `.` 或 `..` 段但不逃逸挂载点
- **THEN** 输出归一化后的相对路径，与 `definitions.keyToPath` 语义一致

### Requirement: expirationSeconds 取值边界

系统 MUST 将 `expirationSeconds` 作为整数渲染，并拒绝小于 600 秒的取值；空值不输出。

#### Scenario: 显式最小值

- **WHEN** `expirationSeconds` 为 `600`
- **THEN** 输出 `expirationSeconds: 600`

#### Scenario: 低于最小值

- **WHEN** `expirationSeconds` 小于 600
- **THEN** 中断渲染并报告合法下限

#### Scenario: expirationSeconds 为空

- **WHEN** `expirationSeconds` 缺失、为 null、空字符串或仅空白字符串
- **THEN** 不输出 `expirationSeconds`

#### Scenario: expirationSeconds 非法

- **WHEN** `expirationSeconds` 不是整数
- **THEN** 中断渲染

## 非目标

- 不创建或修改 `definitions.keyToPath`。
- 不校验 ServiceAccount 是否存在或 token 是否可签发。
- 不输出 `serviceAccountToken` 父键或 `VolumeProjection` 包装。
