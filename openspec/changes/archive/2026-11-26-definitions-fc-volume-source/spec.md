---
updated_at: "2026-11-26T15:08:20Z"
---

# `definitions.fcVolumeSource` 规格

## Purpose

为 Kubernetes `FCVolumeSource` 提供共享结构渲染能力，供 `definitions.volume` 的 `fc` 源与父 Chart 直接复用，并使 `fc` 字符串清洗结果与原生 map 契约一致。

## ADDED Requirements

### Requirement: 上下文与输出范围

`definitions.fcVolumeSource` MUST 接受原生 map 或父模板清洗后的 map 作为上下文，两种形态 MUST 渲染同等的 `FCVolumeSource` 字段片段。

该能力 MUST 按 Kubernetes API 字段顺序依次输出已生效的 `fsType`、`lun`、`readOnly`、`targetWWNs`、`wwids`；MUST NOT 输出 `fc` 父键、`apiVersion`、`kind` 或 `status`。未声明的键 MUST 静默忽略。

`fsType`、`lun`、`readOnly`、`targetWWNs`、`wwids` MUST 为可选字段；未生效字段 MUST NOT 输出。

#### Scenario: 仅提供必需组合

- **WHEN** 上下文为 `{targetWWNs: ["10:20:30:40:50:60:70:80"], lun: 0}`
- **THEN** 输出包含 `lun: 0` 与 `targetWWNs`，顺序符合 API 字段顺序，且不含其他字段

#### Scenario: 原生 map 与清洗后 map 等价

- **WHEN** 原生 map 与父模板清洗后的 map 携带相同字段和取值
- **THEN** 两者渲染结果一致

#### Scenario: 未声明的键

- **WHEN** 上下文包含五个字段以外的任意键
- **THEN** 这些键不出现在输出中，也不触发错误

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

### Requirement: lun 整数

`lun` MUST 为非负整数，显式 `0` MUST 输出 `lun: 0`；非整数或负值 MUST 中断。

`lun` MUST 只在 `targetWWNs` 分支参与输出与校验；`wwids` 分支下 `lun` MUST NOT 输出，其取值 MUST NOT 影响渲染结果。

#### Scenario: 显式 lun 0

- **WHEN** `targetWWNs` 非空且 `lun` 为 `0`
- **THEN** 输出 `lun: 0`

#### Scenario: 非法 lun

- **WHEN** `lun` 为负值或非整数
- **THEN** 渲染中断

#### Scenario: wwids 分支忽略 lun

- **WHEN** `targetWWNs` 未提供，`wwids` 非空且 `lun` 已提供
- **THEN** 输出不含 `lun`

### Requirement: readOnly 布尔

`readOnly` MUST 只接受布尔 `true` / `false` 或字符串 `"true"` / `"false"`；显式 `false` MUST 输出 `readOnly: false`；其他取值 MUST 中断；未提供或空字符串 MUST NOT 输出。

#### Scenario: 显式 false

- **WHEN** `readOnly` 为 `false` 或字符串 `"false"`
- **THEN** 输出 `readOnly: false`

#### Scenario: 非法 readOnly

- **WHEN** `readOnly` 为 `yes`、`1` 等非 `true` / `false` 取值
- **THEN** 渲染中断

#### Scenario: 省略 readOnly

- **WHEN** 未提供 `readOnly`，或取值为空字符串
- **THEN** 输出不含 `readOnly`

### Requirement: WWN 分支与组合约束

`targetWWNs` 与 `wwids` MUST 为 string array，元素 MUST 按输入顺序原样输出；非 array 或包含非 string 元素 MUST 中断。缺失、null 与空 array MUST 视为未提供。

`targetWWNs` 与 `wwids` MUST 互斥使用，且 `targetWWNs` 优先：`targetWWNs` 已提供时 MUST 只输出 `targetWWNs` 分支，`wwids` MUST NOT 输出且 MUST NOT 影响渲染结果。

`targetWWNs` 已提供时 `lun` MUST 同时提供；只提供 `targetWWNs` 或只提供 `lun` 时 MUST 中断。`targetWWNs` 未提供时 `wwids` MUST 已提供；两者都未提供时 MUST 中断。

#### Scenario: 两个 WWN 组同时提供

- **WHEN** 同时提供 `targetWWNs`、`lun` 与 `wwids`
- **THEN** 输出 `targetWWNs` 与 `lun`，不输出 `wwids`

#### Scenario: 仅提供 wwids

- **WHEN** 提供 `wwids`，不提供 `targetWWNs`
- **THEN** 输出 `wwids`，不含 `lun`

#### Scenario: targetWWNs 缺少 lun

- **WHEN** `targetWWNs` 非空且未提供 `lun`
- **THEN** 渲染中断

#### Scenario: 两个 WWN 组都未提供

- **WHEN** `targetWWNs` 与 `wwids` 均缺失、为 null 或为空 array
- **THEN** 渲染中断

#### Scenario: WWN 取值类型非法

- **WHEN** `targetWWNs` 或 `wwids` 不是 array，或包含非 string 元素
- **THEN** 渲染中断

## MODIFIED Requirements

### Requirement: fc 卷字符串清洗

`definitions.volume` 的 `fc` 字符串简写 MUST 为 `[lun] <fsType> [readOnly] [targetWWNs (<value>, ...)] [wwids (<value>, ...)]`。

`targetWWNs` 与 `wwids` MUST 至少二选一、可共存；`targetWWNs` 已提供时子模板 MUST 只输出 `targetWWNs` 分支，`wwids` MUST NOT 输出。两者的括号内 MUST 至少一个元素。

`lun` MUST 为非负整数，且 MUST 仅在 `targetWWNs` 出现时写入子模板上下文，并 MUST 以原生整数携带。`targetWWNs` 已提供而 `lun` 缺失时 MUST 中断，该中断 MUST 由 `definitions.fcVolumeSource` 产生。`wwids` 分支下 `lun` MUST NOT 输出。

`fsType` MUST 仅接受 `ext4`、`xfs`、`ntfs`；`readOnly` MUST 输出 `true` / `false`。

#### Scenario: 两个 WWN 组共存

- **WHEN** 输入 `{name: "fc", fc: "0 ext4 TRUE targetWWNs (a, b) wwids (c)"}`
- **THEN** 输出 fc 片段含 `lun: 0`、`fsType: ext4`、`readOnly: true` 与 `targetWWNs`，不含 `wwids`

#### Scenario: 仅 wwids

- **WHEN** 输入 `{name: "fc", fc: "xfs wwids (c, d)"}`
- **THEN** 输出 fc 片段含 `fsType: xfs` 与 `wwids`，不含 `lun`

#### Scenario: targetWWNs 与 lun 组合

- **WHEN** 输入 `{name: "fc", fc: "0 xfs targetWWNs (a)"}`
- **THEN** 渲染成功，输出与携带相同取值的原生 map 渲染结果一致

#### Scenario: targetWWNs 缺少 lun

- **WHEN** 输入 `{name: "fc", fc: "xfs targetWWNs (a)"}`
- **THEN** 渲染中断，错误由 `definitions.fcVolumeSource` 产生

#### Scenario: lun 没有 WWN 组

- **WHEN** 输入 `{name: "fc", fc: "0 xfs"}`
- **THEN** 渲染中断

#### Scenario: 非法值

- **WHEN** `lun` 为负值、`fsType` 不在枚举内或 `readOnly` 不是布尔
- **THEN** 渲染中断
