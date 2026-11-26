---
updated_at: "2026-11-26T15:39:24Z"
---

# 新增 definitions.hostPathVolumeSource 规格

## Purpose

为 Kubernetes `HostPathVolumeSource` 提供可复用的字段渲染能力，并统一 `definitions.volume` 中 `hostPath` 字符串简写的解析与归一化。

## ADDED Requirements

### Requirement: definitions.hostPathVolumeSource 字段渲染

系统 MUST 将上下文 map 渲染为 Kubernetes `HostPathVolumeSource` 字段片段，并按官方顺序输出 `path`、`type`。

- `path` MUST 为非空绝对路径 string；缺失、空、非 string 或非绝对路径时 MUST 中断，渲染值 MUST 为绝对路径归一化结果。
- `type` 可选；缺失、空字符串或 `""` 时 MUST 不输出。
- `type` 非空时 MUST 为官方枚举值之一：`BlockDevice`、`CharDevice`、`Directory`、`DirectoryOrCreate`、`File`、`FileOrCreate`、`Socket`；MUST 按大小写敏感校验并原样输出；非法枚举或非 string 时 MUST 中断。
- 上下文未声明的键 MUST 静默忽略。

#### Scenario: 仅渲染 path

- **WHEN** 上下文为 `{path: "/data"}`
- **THEN** 输出仅含 `path: "/data"`

#### Scenario: 渲染 path 与 type

- **WHEN** 上下文为 `{path: "/data", type: "DirectoryOrCreate"}`
- **THEN** 输出按顺序包含 `path: "/data"` 与 `type: DirectoryOrCreate`

#### Scenario: 显式空 type 不渲染

- **WHEN** 上下文为 `{path: "/data", type: ""}`
- **THEN** 输出仅含 `path`，不含 `type`

#### Scenario: 绝对路径归一化

- **WHEN** 上下文为 `{path: "/data/../logs"}`
- **THEN** 输出 `path: "/logs"`

#### Scenario: path 缺失或为空

- **WHEN** 上下文缺失 `path` 或 `path` 为空字符串
- **THEN** 渲染中断

#### Scenario: path 不是绝对路径

- **WHEN** 上下文为 `{path: "data/logs"}`
- **THEN** 渲染中断

#### Scenario: type 大小写不匹配

- **WHEN** 上下文为 `{path: "/data", type: "directory"}`
- **THEN** 渲染中断

#### Scenario: type 不在枚举内

- **WHEN** 上下文为 `{path: "/data", type: "Invalid"}`
- **THEN** 渲染中断

#### Scenario: type 不是 string

- **WHEN** 上下文为 `{path: "/data", type: 1}`
- **THEN** 渲染中断

### Requirement: definitions.volume hostPath 字符串简写

当 `definitions.volume` 的 `hostPath` source 为 string 时，系统 MUST 按 `<path> [type]` 解析。

- `path` MUST 为非空绝对路径。
- `type` 可选，MUST 以大小写不敏感方式匹配官方枚举值或 `""`。
- 路径或类型不符合上述范围时 MUST 以 `hostPath: '<值>' does not match '<path> [type]'` 中断。
- 解析成功后 MUST 将 map 委托 `definitions.hostPathVolumeSource`：`path` 为捕获的绝对路径；`type` 非空时 MUST 为对应官方枚举值，`type` 为 `""` 或未提供时 MUST 不下传 `type`。

#### Scenario: 仅 path

- **WHEN** `hostPath` 为 `/data`
- **THEN** 输出 `hostPath` 下仅含 `path: "/data"`

#### Scenario: type 大小写不敏感并归一化

- **WHEN** `hostPath` 为 `/data directoryorcreate`
- **THEN** 输出 `type: DirectoryOrCreate`

#### Scenario: 显式空 type

- **WHEN** `hostPath` 为 `/data ""`
- **THEN** 输出不含 `type`

#### Scenario: path 为空

- **WHEN** `hostPath` 为空字符串
- **THEN** 渲染以 `does not match '<path> [type]'` 中断

#### Scenario: path 不是绝对路径

- **WHEN** `hostPath` 为 `data`
- **THEN** 渲染以 `does not match '<path> [type]'` 中断

#### Scenario: type 非法

- **WHEN** `hostPath` 为 `/data Invalid`
- **THEN** 渲染以 `does not match '<path> [type]'` 中断
