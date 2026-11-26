---
updated_at: "2026-11-26T17:05:39Z"
---

# NFS 卷源定义规格

## Purpose

定义 `definitions.nfsVolumeSource` 的可观察行为，使 NFS 卷源按官方 `NFSVolumeSource` 结构渲染。

## ADDED Requirements

### Requirement: NFSVolumeSource 字段渲染

系统 MUST 按 `path`、`readOnly`、`server` 顺序渲染 NFS 卷源字段；`server` 与 `path` 必填，`readOnly` 可选，缺省时不输出。

#### Scenario: 仅提供必填字段

- **WHEN** 上下文为 `{server: "10.0.0.1", path: "/data"}`
- **THEN** 输出 `path: "/data"` 与 `server: "10.0.0.1"`，不输出 `readOnly`

#### Scenario: 提供完整字段

- **WHEN** 上下文为 `{server: "nfs.example.com", path: "/data", readOnly: true}`
- **THEN** 按 `path`、`readOnly`、`server` 顺序输出，`readOnly` 为 `true`

#### Scenario: 显式 false

- **WHEN** `readOnly` 为 `false`
- **THEN** 输出 `readOnly: false`

#### Scenario: 输入形态一致

- **WHEN** 上下文为原生 map 或父模板清洗后的 map，且字段值相同
- **THEN** 两种形态渲染结果一致

### Requirement: NFSVolumeSource 输入校验

系统 MUST 在必填字段缺失、字段类型非法或字段格式非法时中断渲染。

#### Scenario: 必填字段缺失

- **WHEN** 上下文缺少 `server` 或 `path`，或对应值为空
- **THEN** 渲染中断

#### Scenario: server 格式非法

- **WHEN** `server` 既不是 IP 地址也不是 hostname
- **THEN** 渲染中断

#### Scenario: path 非绝对路径

- **WHEN** `path` 不以 `/` 开头
- **THEN** 渲染中断

#### Scenario: readOnly 类型非法

- **WHEN** `readOnly` 既不是 boolean 也不是大小写不敏感的 `true`/`false` 字符串
- **THEN** 渲染中断

## 非目标

- 不修改父模板中 nfs 简写使用的正则。
