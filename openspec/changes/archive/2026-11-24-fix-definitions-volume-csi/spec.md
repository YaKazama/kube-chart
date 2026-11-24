---
updated_at: "2026-11-24T09:38:46Z"
---

# 修正 definitions.volume 的 csi string 中 nodePublishSecretRef 为可选规格

## MODIFIED Requirements

### Requirement: csi 卷字符串

`csi` 的字符串简写 MUST 为 `<driver> [nodePublishSecretRef] [fsType] [readOnly] [attr|volumeAttributes (key value, ...)]`，位置段 MUST 按出现顺序绑定，取值内容 MUST NOT 改变归属。

`nodePublishSecretRef` MUST 可省略；省略时 MUST NOT 渲染该字段。出现在该位置的 `ext4`、`xfs`、`ntfs`（不区分大小写）MUST 归属 `fsType`，此时 `nodePublishSecretRef` MUST 视为未提供。出现在该位置的 `true`、`false`（不区分大小写）MUST 作为 `nodePublishSecretRef` 原始字符串下传，MUST NOT 重解释为 `readOnly`；其他非空取值同样以原始字符串下传，由子模板/孙模板映射为 `LocalObjectReference.name`。

`fsType` MUST 仅接受 `ext4`、`xfs`、`ntfs` 并归一化为小写；`readOnly` MUST 输出 `true` / `false`；两者未提供时 MUST NOT 渲染。`fsType` 位置与 `nodePublishSecretRef` 位置的枚举取值同时出现时 MUST 中断。

`attr` 与 `volumeAttributes` MUST 是等价显式关键字，括号内 MUST 至少一个 `key value` 段并映射为 `volumeAttributes` 键值，键值分隔符为空格或冒号；缺少 key 或 value 时 MUST 中断。无法匹配该简写的输入 MUST 以与新语法一致的位置段说明中断。

#### Scenario: 省略 nodePublishSecretRef

- **WHEN** 输入 `{name: "csi-vol", csi: "driver.example"}`
- **THEN** 输出 `csi` 上下文仅含 `driver`，不含 `nodePublishSecretRef` 键

#### Scenario: 只写 fsType

- **WHEN** 输入 `{name: "csi-vol", csi: "driver.example ext4"}`
- **THEN** 输出 `csi` 上下文含 `driver` 与 `fsType: ext4`，不含 `nodePublishSecretRef` 键

#### Scenario: 提供 nodePublishSecretRef

- **WHEN** 输入 `{name: "csi-vol", csi: "driver.example regcred"}`
- **THEN** 输出 `csi` 上下文含 `driver` 与原始 `nodePublishSecretRef: "regcred"`，不含 `fsType` 与 `readOnly` 键

#### Scenario: csi 完整简写

- **WHEN** 输入 `{name: "csi-vol", csi: "driver.example secret ext4 TRUE"}`
- **THEN** 输出 `csi` 上下文含 `driver`、原始 `nodePublishSecretRef`、`fsType: ext4` 与 `readOnly: true`

#### Scenario: 省略 nodePublishSecretRef 的 fsType 与 readOnly

- **WHEN** 输入 `{name: "csi-vol", csi: "driver.example ext4 true"}`
- **THEN** 输出 `csi` 上下文含 `fsType: ext4` 与 `readOnly: true`，不含 `nodePublishSecretRef` 键

#### Scenario: true 作为 secret 名

- **WHEN** 输入 `{name: "csi-vol", csi: "driver.example true"}`
- **THEN** 输出 `csi` 上下文含 `nodePublishSecretRef: "true"`，不含 `readOnly` 键

#### Scenario: csi 空 secretRef 占位

- **WHEN** 输入 `{name: "csi-vol", csi: "driver.example \"\" xfs"}`
- **THEN** 输出 `csi` 上下文以原始 `""` 下传 `nodePublishSecretRef` 与 `fsType: xfs`，由子/孙模板视为未提供

#### Scenario: 省略 nodePublishSecretRef 的 attributes

- **WHEN** 输入 `{name: "csi-vol", csi: "driver.example volumeAttributes (foo:bar)"}`
- **THEN** 输出 `csi` 上下文含 `volumeAttributes`，不含 `nodePublishSecretRef` 键

#### Scenario: csi 非法属性段

- **WHEN** 属性段缺少 key 或 value，或括号组内容为空
- **THEN** 渲染中断

#### Scenario: csi 枚举取值重复

- **WHEN** 输入 `{name: "csi-vol", csi: "driver.example ext4 xfs"}`
- **THEN** 渲染中断，因为 `fsType` 被两个位置同时赋值

#### Scenario: csi 语法不匹配

- **WHEN** 输入含多余位置段，例如 `{name: "csi-vol", csi: "driver.example secret ext4 true junk"}`
- **THEN** 渲染中断，提示文案使用新位置段说明

## 非目标

- 不实现或修改 `definitions.csiVolumeSource` 模板本体，`nodePublishSecretRef` 的 YAML 渲染与 `LocalObjectReference` 映射仍由该子模板负责。
- 不修改原生 map 形式的 `csi` 输入，也不修改其他 volume source 的字符串简写。
- 不修改已归档的 `2026-11-23-definitions-volume` 制品。
