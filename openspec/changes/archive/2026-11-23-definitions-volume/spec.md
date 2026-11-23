---
updated_at: "2026-11-23T15:20:03Z"
---

# definitions.volume 规格

## Purpose

为 `core.podSpec` 的 volumes 提供统一的 Volume 渲染入口：把归一化后的 `{name, <source>}` 上下文或各 source 的字符串简写转换为 Volume 字段片段，并在子模板未实现时保持可预测的占位行为。

## ADDED Requirements

### Requirement: Volume 输入与渲染契约

本能力 MUST 以 `definitions.volume` 命名模板提供；旧名 `definitions.Volume` MUST NOT 作为调用入口。

系统 MUST 接受 `{name, <source>}` map，其中 `name` 必填，`name` 以外恰好一个受支持的 source 键；`name` 先小写再按 RFC1123 Label 校验；source 值可为原始 map、string 或 nil。

系统 MUST 按 `configMap`、`csi`、`downwardAPI`、`emptyDir`、`ephemeral`、`fc`、`hostPath`、`image`、`iscsi`、`name`、`nfs`、`persistentVolumeClaim`、`projected`、`secret` 的顺序输出，且只输出 `name` 与该 source 键。

系统 MUST 将 map 形式的 source 值原样传给对应子模板；string 形式由本能力解析为子模板上下文；nil source 值 MUST 按空 map 处理并输出 `source: {}`；其他类型 MUST 中断。子模板输出为空或非 map 时 MUST 输出 `source: {}`；非法 YAML 输出 MUST 中断。

#### Scenario: map 形式渲染

- **WHEN** 输入 `{name: "data", emptyDir: {}}`
- **THEN** 输出 `emptyDir: {}` 与 `name: "data"`，顺序符合字段列表

#### Scenario: string 形式渲染

- **WHEN** 输入 `{name: "cfg", configMap: "cm TRUE 0644 items (key path)"}`
- **THEN** 输出 `configMap` 上下文与 `name: "cfg"`

#### Scenario: nil source

- **WHEN** 输入 `{name: "data", emptyDir: nil}`
- **THEN** 输出 `emptyDir: {}` 与 `name: "data"`

#### Scenario: 子模板空输出

- **WHEN** 子模板返回空内容
- **THEN** 对应 source 键输出 `{}`

#### Scenario: name 缺失或非法

- **WHEN** `name` 缺失、为空或不符合 RFC1123 Label
- **THEN** 渲染中断

#### Scenario: source 数量或类型非法

- **WHEN** `name` 以外的键为零个、多于一个或不在受支持列表
- **THEN** 渲染中断

### Requirement: Volume 字符串通用规则

所有 source 字符串 MUST 按空白字符分隔顶层位置段；括号内 array 元素 MUST 按逗号分隔。关键字与枚举匹配 MUST 不区分大小写；枚举输出 MUST 归一化为官方拼写，布尔输出 MUST 为 `true` / `false`。位置可选段没有值时 MUST 使用空字符串占位，空字符串 MUST 视为未提供。

#### Scenario: 枚举大小写归一化

- **WHEN** 输入包含 `MEMORY`、`ALWAYS` 或 `DIRECTORYORCREATE`
- **THEN** 输出分别为 `Memory`、`Always` 或 `DirectoryOrCreate`

#### Scenario: 空字符串占位

- **WHEN** 位置可选段使用 `""` 或 `''`
- **THEN** 该段视为未提供，不输出对应字段

### Requirement: configMap 与 secret 卷字符串

`configMap` 与 `secret` 的字符串简写 MUST 为 `<name> [optional] [defaultMode] [items (<key> <path> [mode], ...)]`，其中 `<name>` 是对应 ConfigMap 或 Secret 的名称；`optional` 不区分大小写并输出 `true` / `false`；`defaultMode` 与 item 的 `mode` MUST 接受八进制 `0xxx` 与十进制 0-511，并原样下传，最终由子/孙模板解析为十进制。

`items` MUST 是显式关键字，括号内至少一个元素；每个元素 MUST 以原始 item 字符串下传，由子模板/孙模板按 `key`、`path`、可选 `mode` 解析。括号缺失、元素不足两段或超过三段时 MUST 中断。

#### Scenario: configMap 完整简写

- **WHEN** 输入 `{name: "cfg", configMap: "cm TRUE 0644 items (key path, key1 path1 0400)"}`
- **THEN** 输出 `configMap` 上下文，`optional` 为 `true`，`defaultMode` 为 `0644`，`items` 含两个原始 item 字符串

#### Scenario: secret 仅名称

- **WHEN** 输入 `{name: "sec", secret: "my-secret"}`
- **THEN** 输出 `secret` 上下文且只含 `secretName`

#### Scenario: items 非法

- **WHEN** `items` 括号缺失或元素段数不在 2-3
- **THEN** 渲染中断

### Requirement: csi 卷字符串

`csi` 的字符串简写 MUST 为 `<driver> <nodePublishSecretRef> [fsType] [readOnly] [attr|volumeAttributes (key value, ...)]`。

`nodePublishSecretRef` MUST 以原始字符串下传，由子模板/孙模板映射为 `LocalObjectReference.name`；取值为空时不渲染该字段，空位置 MUST 使用空字符串占位。`fsType` MUST 仅接受 `ext4`、`xfs`、`ntfs`；`readOnly` MUST 输出 `true` / `false`。`attr` 与 `volumeAttributes` MUST 是等价显式关键字，括号内 MUST 至少一个 `key value` 段并映射为 `volumeAttributes` 键值，键值分隔符为空格或冒号；缺少 key 或 value 时 MUST 中断。

#### Scenario: csi 完整简写

- **WHEN** 输入 `{name: "csi-vol", csi: "driver.example secret ext4 TRUE attr (mode 0777, foo:bar)"}`
- **THEN** 输出 `csi` 上下文，含 `driver`、原始 `nodePublishSecretRef`、`fsType`、`readOnly: true` 与两个 `volumeAttributes`

#### Scenario: csi 空 secretRef

- **WHEN** 输入 `{name: "csi-vol", csi: "driver.example \"\" xfs"}`
- **THEN** 输出 `csi` 上下文，`nodePublishSecretRef` 为空字符串占位，由子/孙模板视为未提供

#### Scenario: csi 非法枚举或属性段

- **WHEN** `fsType` 不在枚举、`readOnly` 不是布尔或属性段缺少 key/value
- **THEN** 渲染中断

### Requirement: downwardAPI 卷字符串

`downwardAPI` 的字符串简写 MUST 为 `[defaultMode] [items (<item>, ...)]`，`items` 为显式关键字且括号内至少一个元素。

item MUST 支持两种形态：`<path> field <fieldPath> [mode]` 与 `<path> resource <resource> [containerName] [divisor] [mode]`，并以原始 item 字符串下传。子模板/孙模板 MUST 将 `field` 映射为 `fieldRef`、`resource` 映射为 `resourceFieldRef`；`<resource>` 映射为 `ResourceFieldSelector.resource`，`containerName` 与 `divisor` 按位置映射；`fieldPath` 与 `<resource>` MUST 原样下传，实际校验由后续模板完成。跳过 `containerName` 或 `divisor` 时 MUST 使用空字符串占位。

#### Scenario: field item

- **WHEN** 输入 `{name: "dw", downwardAPI: "0644 items (meta field metadata.name 0400)"}`
- **THEN** 输出 `downwardAPI` 上下文，`items` 含原始 item 字符串，其内容包含 `path`、`field`、`fieldPath` 与 `mode`

#### Scenario: resource item

- **WHEN** 输入 `{name: "dw", downwardAPI: "items (cpu resource limits.cpu app 1m)"}`
- **THEN** 输出 `downwardAPI` 上下文，`items` 含原始 item 字符串，其内容包含 `path`、`resource`、`containerName` 与 `divisor`

#### Scenario: item 形态非法

- **WHEN** item 既不是 `field` 形态也不是 `resource` 形态
- **THEN** 渲染中断

### Requirement: emptyDir 卷字符串

`emptyDir` 的字符串简写 MUST 为 `[medium] [sizeLimit]`。`medium` MUST 只接受空值或 `Memory`；`sizeLimit` MUST 通过 Kubernetes Quantity 校验。非法 `medium` 或 `sizeLimit` MUST 中断。

#### Scenario: emptyDir 完整简写

- **WHEN** 输入 `{name: "tmp", emptyDir: "memory 1Gi"}`
- **THEN** 输出 `emptyDir` 上下文，`medium` 为 `Memory`，`sizeLimit` 为 `1Gi`

#### Scenario: emptyDir 空值

- **WHEN** 输入 `{name: "tmp", emptyDir: ""}`
- **THEN** 输出 `emptyDir: {}`

#### Scenario: emptyDir 非法值

- **WHEN** `medium` 不是空或 `Memory`，或 `sizeLimit` 不是合法 Quantity
- **THEN** 渲染中断

### Requirement: fc 卷字符串

`fc` 的字符串简写 MUST 为 `[lun] <fsType> [readOnly] [targetWWNs (<value>, ...)] [wwids (<value>, ...)]`。`targetWWNs` 与 `wwids` MUST 至少二选一、可共存；两者括号内均至少一个元素。`lun` MUST 大于等于 0，且仅在 `targetWWNs` 存在时渲染。`fsType` MUST 仅接受 `ext4`、`xfs`、`ntfs`；`readOnly` MUST 输出 `true` / `false`。

#### Scenario: fc 两个 WWN 组共存

- **WHEN** 输入 `{name: "fc", fc: "0 ext4 TRUE targetWWNs (a, b) wwids (c)"}`
- **THEN** 输出 `fc` 上下文，含 `lun: 0`、`fsType`、`readOnly: true`、`targetWWNs` 与 `wwids`

#### Scenario: fc 仅 wwids

- **WHEN** 输入 `{name: "fc", fc: "xfs wwids (c, d)"}`
- **THEN** 输出 `fc` 上下文且不含 `lun`

#### Scenario: fc 缺少 WWN 组或 lun 非法

- **WHEN** `targetWWNs` 与 `wwids` 都缺失，或 `lun` 小于 0
- **THEN** 渲染中断

### Requirement: hostPath、image、nfs 与 persistentVolumeClaim 卷字符串

- `hostPath` MUST 为 `<path> [type]`；`path` 必须是绝对路径；`type` MUST 按官方枚举 `""`、`BlockDevice`、`CharDevice`、`Directory`、`DirectoryOrCreate`、`File`、`FileOrCreate`、`Socket` 校验并归一化，允许显式 `""`。
- `image` MUST 为 `<reference> [pullPolicy]`；`pullPolicy` MUST 仅接受 `Always`、`IfNotPresent`、`Never`。
- `nfs` MUST 为 `<server> <path> [readOnly]`；`server` 必须是 IP 或域名；`path` 必须是绝对路径；`readOnly` MUST 输出 `true` / `false`。
- `persistentVolumeClaim` MUST 为 `<claimName> [readOnly]`；`readOnly` MUST 输出 `true` / `false`。

#### Scenario: hostPath 显式空 type

- **WHEN** 输入 `{name: "host", hostPath: "/data \"\""}`
- **THEN** 输出 `hostPath` 上下文，`type` 为 `""`

#### Scenario: image 枚举归一化

- **WHEN** 输入 `{name: "img", image: "nginx:latest ifnotpresent"}`
- **THEN** 输出 `image` 上下文，`pullPolicy` 为 `IfNotPresent`

#### Scenario: nfs 与 pvc

- **WHEN** 输入 `{name: "nfs", nfs: "server.example /export TRUE"}` 与 `{name: "pvc", persistentVolumeClaim: "claim TRUE"}`
- **THEN** 两者均输出对应 source 上下文，`readOnly` 为 `true`

#### Scenario: 路径、枚举或布尔非法

- **WHEN** `hostPath` 或 `nfs` 的路径不是绝对路径，或任一枚举、布尔值非法
- **THEN** 渲染中断

### Requirement: iscsi 卷字符串

`iscsi` 的字符串简写 MUST 为 `<iqn> <lun> [targetPortal] [fsType] [readOnly] [iscsiInterface] [initiatorName] [chap (<chapAuthDiscovery>, <chapAuthSession>)] [portals (<ip>, ...)] [secretRef.name]`。

`lun` MUST 大于等于 0。`fsType` MUST 仅接受 `ext4`、`xfs`、`ntfs`；`readOnly` MUST 输出 `true` / `false`。`chap` MUST 同时提供两个布尔值并映射为 `chapAuthDiscovery` 与 `chapAuthSession`；`portals` MUST 映射为至少一个元素的 string array；`secretRef` MUST 以原始字符串下传，由子模板/孙模板映射为 `secretRef.name`。`targetPortal` 与 `portals` 元素 MUST 允许 `ip:port` 或端口号。位置可选段跳过时 MUST 使用空字符串占位，空值视为未提供。

#### Scenario: iscsi 完整简写

- **WHEN** 输入 `{name: "iscsi", iscsi: "iqn.1994-05.com 0 10.0.0.1:3260 ext4 TRUE default iqn.example chap (true, false) portals (10.0.0.1, 10.0.0.2) my-secret"}`
- **THEN** 输出 `iscsi` 上下文，含 `chapAuthDiscovery: true`、`chapAuthSession: false`、两个 `portals` 与原始 `secretRef`

#### Scenario: iscsi 空占位

- **WHEN** 输入 `{name: "iscsi", iscsi: "iqn.example 0 \"\" ext4 TRUE \"\" \"\""}`
- **THEN** 输出 `iscsi` 上下文且不含 `targetPortal`、`iscsiInterface` 与 `initiatorName`

#### Scenario: iscsi 非法值

- **WHEN** `lun` 小于 0、`fsType` 非法、`readOnly` 非布尔、`chap` 值不完整或 `portals` 元素格式非法
- **THEN** 渲染中断

### Requirement: core.podSpec volumes 归一化

`core.podSpec` 的 `volumes` MUST 只接受 array，元素可为原生 map 或 string，两者可混合。原生 map MUST 在 `name` 以外恰好一个 source 键；string MUST 通过 Volume 短写提取类型、名称与余下原文；类型关键字 MUST 归一化为规范 source 键，覆盖既有类型并新增 `csi`、`downwardAPI` 与 `downwardAPI` 的 `api` 缩写。

归一化结果 MUST 为 `{name, <source>: <value>}`。顶层字段分隔符 MUST 只使用空白字符，逗号只在括号内分隔 array 元素；共享分隔行为与其他模板 MUST 保持不变。`ephemeral` 与 `projected` MUST 只接受原生 map；string array 元素以这两个关键字开头，或原生 map 中该键的值为 string 时，MUST 中断并提示使用原生 map。

#### Scenario: map 与 string 混合

- **WHEN** `volumes` 为 `[{name: "cm-vol", configMap: "cm"}, "emptydir tmp"]`
- **THEN** 两项均归一化为 `{name, <source>: <value>}` 并交给 `definitions.volume`

#### Scenario: 类型关键字归一化

- **WHEN** string 元素以 `API` 或 `downwardapi` 开头
- **THEN** 归一化 source 键为 `downwardAPI`

#### Scenario: ephemeral 或 projected 字符串

- **WHEN** string 元素以 `ephemeral` / `projected` 开头，或原生 map 中对应键为 string
- **THEN** 渲染中断并提示只能使用原生 map

## 非目标

- 不实现本 change 列出的 13 个 `definitions.*VolumeSource` 子模板。
- 不为 `ephemeral` 或 `projected` 提供 string 简写。
- 不改变其他模板的逗号分隔行为或共享分隔常量。
