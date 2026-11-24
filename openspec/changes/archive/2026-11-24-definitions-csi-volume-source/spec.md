---
updated_at: "2026-11-24T10:08:14Z"
---

# definitions.csiVolumeSource 定义模板规格

## Purpose

为 Kubernetes `CSIVolumeSource` 提供共享结构渲染能力，供 `definitions.volume` 的 `csi` 分支复用。

## ADDED Requirements

### Requirement: CSIVolumeSource 字段渲染

`definitions.csiVolumeSource` MUST 接受原生 map 或父模板清洗后的 map 作为上下文，两种形态 MUST 渲染同一 `CSIVolumeSource` 字段片段。

`definitions.csiVolumeSource` MUST 按 Kubernetes API 字段顺序渲染 `CSIVolumeSource` 字段片段，依次输出已生效的 `driver`、`fsType`、`nodePublishSecretRef`、`readOnly`、`volumeAttributes`，MUST NOT 输出 `csi` 父键、`apiVersion`、`kind` 或 `status`。

`driver` MUST 为必填 string；缺失、为 null、为空字符串或只含空白时 MUST 中断。`driver` MUST 以带引号标量输出；非 string 取值 MUST 中断，该类型失败消息由标量解码能力给出并保留其自身前缀。

`fsType`、`nodePublishSecretRef`、`readOnly`、`volumeAttributes` MUST 为可选字段；取值为 nil、空字符串或空 map 时 MUST NOT 输出对应键。

本模板自身产生的失败消息 MUST 使用 `[definitions.csiVolumeSource]` 前缀并带上字段名；由被委托能力产生的失败消息 MUST 保持其自身前缀。

#### Scenario: 仅提供 driver

- **WHEN** 上下文为 `{driver: "csi.example.com"}`
- **THEN** 输出仅含 `driver: "csi.example.com"` 的字段片段

#### Scenario: 完整字段

- **WHEN** `driver`、`fsType`、`nodePublishSecretRef`、`readOnly`、`volumeAttributes` 均已提供且合法
- **THEN** 输出按 `driver`、`fsType`、`nodePublishSecretRef`、`readOnly`、`volumeAttributes` 顺序包含五个字段

#### Scenario: 父模板清洗后的上下文

- **WHEN** 上下文为 `{driver: "csi.example.com", fsType: "xfs", nodePublishSecretRef: "regcred", readOnly: true}`
- **THEN** 输出与同值原生 map 形态一致的字段片段

#### Scenario: driver 缺失或为空

- **WHEN** 上下文不含 `driver`，或 `driver` 为空字符串、只含空白
- **THEN** 渲染中断，消息以 `[definitions.csiVolumeSource]` 开头并包含 `driver`

### Requirement: fsType 枚举

`fsType` MUST 只接受 `ext4`、`xfs`、`ntfs`，比较 MUST 区分大小写，输出 MUST 保持原值；其他取值 MUST 中断并给出合法范围。

#### Scenario: 合法 fsType

- **WHEN** `fsType` 为 `ext4`、`xfs` 或 `ntfs`
- **THEN** 输出 `fsType: <值>`

#### Scenario: 非法 fsType

- **WHEN** `fsType` 为 `EXT4` 或其他不在枚举内的取值
- **THEN** 渲染中断，消息给出合法取值范围

#### Scenario: 省略 fsType

- **WHEN** 未提供 `fsType`，或取值为空字符串
- **THEN** 输出不含 `fsType`

### Requirement: readOnly 布尔

`readOnly` MUST 只接受布尔 `true` / `false` 或字符串 `"true"` / `"false"`；显式 `false` MUST 输出 `readOnly: false`；其他取值 MUST 中断。

#### Scenario: 显式 false

- **WHEN** `readOnly` 为 `false` 或字符串 `"false"`
- **THEN** 输出 `readOnly: false`

#### Scenario: 非法 readOnly

- **WHEN** `readOnly` 为 `yes`、`1` 等非 `true` / `false` 取值
- **THEN** 渲染中断

#### Scenario: 省略 readOnly

- **WHEN** 未提供 `readOnly`，或取值为空字符串
- **THEN** 输出不含 `readOnly`

### Requirement: nodePublishSecretRef 双形态

`nodePublishSecretRef` MUST 接受 `LocalObjectReference` map 或 string 两种形态。string 形态 MUST 表示被引用 secret 的名称，去除 YAML 引号与首尾空白后为空时 MUST 视为未提供；map 形态 MUST 原样交给 `definitions.localObjectReference`。两种形态的 `name` 校验与输出 MUST 由 `definitions.localObjectReference` 负责，其结果为空时 MUST NOT 输出该键；既不是 map 也不是 string 的取值 MUST 中断。

#### Scenario: string 形态

- **WHEN** `nodePublishSecretRef` 为 `"regcred"`
- **THEN** 输出含 `name: "regcred"` 的 `nodePublishSecretRef` 片段

#### Scenario: map 形态

- **WHEN** `nodePublishSecretRef` 为 `{name: "regcred"}`
- **THEN** 输出与 string 形态一致的 `nodePublishSecretRef` 片段

#### Scenario: 空引用

- **WHEN** `nodePublishSecretRef` 为 `""`、只含空白或空 map
- **THEN** 输出不含 `nodePublishSecretRef`

#### Scenario: 引用类型非法

- **WHEN** `nodePublishSecretRef` 为布尔、数字或数组
- **THEN** 渲染中断，消息以 `[definitions.csiVolumeSource]` 开头并包含 `nodePublishSecretRef`

#### Scenario: secret 名称非法

- **WHEN** string 形态的名称不符合 `definitions.localObjectReference` 的校验规则
- **THEN** 渲染中断，消息保留 `definitions.localObjectReference` 自身前缀

### Requirement: volumeAttributes 对象

`volumeAttributes` MUST 只接受 map；键值对 MUST 原样渲染为 `volumeAttributes` 下的键值。值 MUST 为 string，非 string 时 MUST 中断；空 map MUST NOT 输出。

#### Scenario: 渲染属性

- **WHEN** `volumeAttributes` 为 `{mode: "0777", foo: "bar"}`
- **THEN** 输出 `volumeAttributes`，包含 `mode: "0777"` 与 `foo: "bar"`

#### Scenario: 空属性

- **WHEN** `volumeAttributes` 未提供，或为空 map
- **THEN** 输出不含 `volumeAttributes`

#### Scenario: 非 string 属性值

- **WHEN** `volumeAttributes` 的任一值为数字、布尔或 map
- **THEN** 渲染中断，消息以 `[definitions.csiVolumeSource]` 开头并包含 `volumeAttributes.<key>`

## 非目标

- 不修改 `definitions.volume` 的 `csi` string 简写解析。
- 不修改 `definitions.localObjectReference` 的校验与输出行为。
- 不实现其他 volume source 的定义模板。
