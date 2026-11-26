---
updated_at: "2026-11-26T16:31:45Z"
---

# 新增 definitions.iscsiVolumeSource 规格

## Purpose

为 Kubernetes `ISCSIVolumeSource` 提供字段渲染能力，新增通用 host:port 归一化基础能力，并修正 `definitions.volume` 的 `iscsi` 字符串简写解析。

## ADDED Requirements

### Requirement: base.net.hostPort host:port 归一化

系统 MUST 提供通用 host:port 归一化能力，接受 IPv4 或 IPv6 地址与可选端口。

- 未提供端口时 MUST 使用调用方传入的默认端口；没有默认端口时 MUST 视为非法。
- 输出 MUST 为 `host:port`；IPv6 host MUST 输出为 `[host]:port`。
- IPv6 带端口输入 MUST 使用方括号，例如 `[2001:db8::1]:3260`。
- 纯端口号、非法 IP 或非法端口 MUST 视为非法。
- 严格模式下非法输入 MUST 中断；非严格模式下非法输入 MUST 返回空字符串。

#### Scenario: IPv4 省略端口

- **WHEN** 输入 `10.0.2.15`，默认端口 `3260`
- **THEN** 输出 `10.0.2.15:3260`

#### Scenario: IPv4 显式端口

- **WHEN** 输入 `10.0.2.15:3260`
- **THEN** 输出 `10.0.2.15:3260`

#### Scenario: IPv6 省略端口

- **WHEN** 输入 `2001:db8::1`，默认端口 `3260`
- **THEN** 输出 `[2001:db8::1]:3260`

#### Scenario: IPv6 方括号显式端口

- **WHEN** 输入 `[2001:db8::1]:3260`
- **THEN** 输出 `[2001:db8::1]:3260`

#### Scenario: 纯端口号非法

- **WHEN** 输入 `3260`
- **THEN** 严格模式中断，非严格模式返回空字符串

#### Scenario: 非法地址

- **WHEN** 输入 `999.0.0.1`
- **THEN** 严格模式中断，非严格模式返回空字符串

### Requirement: definitions.iscsiVolumeSource 字段渲染

系统 MUST 将上下文 map 渲染为 Kubernetes `ISCSIVolumeSource` 字段片段，并按官方顺序输出 `chapAuthDiscovery`、`chapAuthSession`、`fsType`、`initiatorName`、`iqn`、`iscsiInterface`、`lun`、`portals`、`readOnly`、`secretRef`、`targetPortal`。

- `iqn`、`lun`、`targetPortal` MUST 必填；`lun` MUST 为非负 integer，显式 `0` MUST 输出。
- `fsType` 可选；MUST 大小写不敏感匹配 `ext4`、`xfs`、`ntfs`，并 MUST 输出小写枚举值；其他值 MUST 中断。
- boolean 字段 `chapAuthDiscovery`、`chapAuthSession`、`readOnly` 可选；MUST 接受 boolean 或大小写不敏感的 `true`/`false` 字符串，并 MUST 输出小写 `true`/`false`；其他值 MUST 中断。
- `portals` 可选；MUST 清洗为 string array，元素 MUST 按 `targetPortal` 的 portal 规则归一化，非法元素 MUST 丢弃；归一化后为空时 MUST 不输出。
- `secretRef` 可选；string 名称 MUST 清洗为 `{name: <名称>}`，map MUST 原样作为 `LocalObjectReference`，并 MUST 委托 `definitions.localObjectReference` 渲染；空值 MUST 不输出。
- `targetPortal` MUST 按 host:port 规则归一化，省略端口时 MUST 补全 `:3260`；非法值 MUST 中断。
- 上下文未声明的键 MUST 静默忽略。

#### Scenario: 最小必填字段

- **WHEN** 上下文为 `{iqn: "iqn.1994-05.com.example:disk", lun: 0, targetPortal: "10.0.2.15"}`
- **THEN** 输出按顺序包含 `iqn: "iqn.1994-05.com.example:disk"`、`lun: 0`、`targetPortal: "10.0.2.15:3260"`

#### Scenario: 全字段按官方顺序渲染

- **WHEN** 上下文包含全部字段，`fsType` 为 `EXT4`，`readOnly` 为 `TRUE`，`portals` 含合法与非法元素
- **THEN** 输出顺序为 `chapAuthDiscovery`、`chapAuthSession`、`fsType`、`initiatorName`、`iqn`、`iscsiInterface`、`lun`、`portals`、`readOnly`、`secretRef`、`targetPortal`，且 `fsType` 为 `ext4`、`readOnly` 为 `true`、非法 portal 被丢弃

#### Scenario: portals 归一化与丢弃非法元素

- **WHEN** `portals` 为 `["10.0.2.15", "[2001:db8::1]:3260", "bad", "3260"]`
- **THEN** 输出仅含 `10.0.2.15:3260` 与 `[2001:db8::1]:3260`

#### Scenario: secretRef string 清洗

- **WHEN** `secretRef` 为 `"iscsi-secret"`
- **THEN** 输出 `secretRef` 下含 `name: "iscsi-secret"`

#### Scenario: 缺失 iqn

- **WHEN** 上下文缺失 `iqn`
- **THEN** 渲染中断

#### Scenario: 非法 targetPortal

- **WHEN** `targetPortal` 为 `3260` 或非法 IP
- **THEN** 渲染中断

#### Scenario: 非法 fsType

- **WHEN** `fsType` 为 `btrfs`
- **THEN** 渲染中断

### Requirement: definitions.volume iscsi 字符串简写

当 `definitions.volume` 的 `iscsi` source 为 string 时，系统 MUST 按 `<iqn> <lun> <targetPortal> [fsType] [readOnly] [iscsiInterface] [initiatorName] [chap (<chapAuthDiscovery>, <chapAuthSession>)] [portals (<portal>, ...)] [secretRef.name]` 解析。

- `targetPortal` MUST 必填。
- `lun` MUST 匹配 `[0-9]+`。
- `fsType` MUST 大小写不敏感匹配 `ext4`、`xfs`、`ntfs`。
- boolean 段 MUST 大小写不敏感匹配 `true`、`false`。
- 解析成功后 MUST 将捕获值委托 `definitions.iscsiVolumeSource`；`portals` 由该模板清洗并丢弃非法元素。
- 输入不符合语法时 MUST 以 `does not match` 中断。

#### Scenario: 最小简写

- **WHEN** `iscsi` 为 `iqn.1994-05.com.example:disk 0 10.0.2.15`
- **THEN** 输出含 `lun: 0` 与 `targetPortal: "10.0.2.15:3260"`

#### Scenario: 缺少 targetPortal

- **WHEN** `iscsi` 为 `iqn.1994-05.com.example:disk 0`
- **THEN** 渲染以 `does not match` 中断

#### Scenario: fsType 与 boolean 大小写不敏感

- **WHEN** `iscsi` 为 `iqn.1994-05.com.example:disk 0 10.0.2.15 EXT4 TRUE`
- **THEN** 输出 `fsType: ext4` 与 `readOnly: true`

#### Scenario: portals 丢弃非法元素

- **WHEN** `iscsi` 含 `portals (10.0.2.15, bad, 3260)`
- **THEN** 输出仅含 `10.0.2.15:3260`

#### Scenario: secretRef 简写

- **WHEN** `iscsi` 末尾为 `my-secret`
- **THEN** 输出 `secretRef` 下含 `name: "my-secret"`
