---
change-id: definitions-volume
updated_at: "2026-11-23T15:18:05Z"
---

# definitions.volume 模板

## 目标

- 新增 `definitions.volume`：接收 `core.podSpec` 归一化后的 `{name, <source>}` 上下文，渲染 `name` 与唯一一个 volume source 键。
- 扩展 `core.podSpec` 的 `volumes`：原生 map array 与 string array（可混合）统一归一化为 map 后交给 `definitions.volume`。

## 需求

### definitions.volume

- 命名：公开命名模板名统一为 `definitions.volume`；旧名 `definitions.Volume` 不再作为调用名。模板 `define`、调用点、契约注释、错误消息前缀和验证 fixture 均使用新名。
- 入参为 map：`name` + 恰好一个受支持的 source 键。
  - `name`（string）：卷名，渲染为 `name`；必填，先 `lower` 再按 RFC1123 Label 校验，缺失或非法中断。
  - `<source>`（map 或 string）：对应 source 的原始 map 或 string；map 原样传给子模板，string 由本模板解析为子模板所需的 map 上下文；无数据的类型值可为空。
  - source 值为 `nil` 时按空 map 处理，并显式输出 `source: {}`。
  - `name` 以外的键必须是受支持的 source 之一；名单外键中断报错。
- 入参键名以示例 `{name, <source>}` 为准；首个消息中的 `volumeType`、`volumeName`、`volumeData` 仅描述同一组语义。
- 输出 `name` 与输入中的唯一 source 键，字段按以下顺序渲染：`configMap`、`csi`、`downwardAPI`、`emptyDir`、`ephemeral`、`fc`、`hostPath`、`image`、`iscsi`、`name`、`nfs`、`persistentVolumeClaim`、`projected`、`secret`；`name` 位于 `iscsi` 与 `nfs` 之间。
- 同一 Volume 的 source 互斥：输入中 `name` 以外只能有一个 source 键。
- 子模板只占位：直接 `include` 以下模板，本 change 不创建任何子模板。

| source | include |
|---|---|
| `configMap` | `definitions.configMapVolumeSource` |
| `csi` | `definitions.csiVolumeSource` |
| `downwardAPI` | `definitions.downwardAPIVolumeSource` |
| `emptyDir` | `definitions.emptyDirVolumeSource` |
| `ephemeral` | `definitions.ephemeralVolumeSource` |
| `fc` | `definitions.fcVolumeSource` |
| `hostPath` | `definitions.hostPathVolumeSource` |
| `image` | `definitions.imageVolumeSource` |
| `iscsi` | `definitions.iscsiVolumeSource` |
| `nfs` | `definitions.nfsVolumeSource` |
| `persistentVolumeClaim` | `definitions.persistentVolumeClaimVolumeSource` |
| `projected` | `definitions.projectedVolumeSource` |
| `secret` | `definitions.secretVolumeSource` |

- 不过度清洗：由孙模板消费的捕获值直接传给子模板对应键，清洗工作由孙模板完成；string 模式下形成子模板上下文时，凡后续由子模板再委托给孙模板或更深层模板的字段，均原样传递；本层只按规格校验 item 形态，不构造孙模板 map，也不做值清洗或类型转换。
- 子模板输出为空或非 map 时，仍显式输出 `source: {}`。

### core.podSpec 的 volumes

- 只接受 array；元素可为原生 map 或 string，两者可混合。
- 原生 map 元素：除 `name` 外恰好一个 volume source 键；该键经 `volumeTypes` 归一化为规范 source 键，值保留。
- string 元素：仍用 `K8S.VOLUME.SHORT` 取 `volumeType`、`volumeName` 与余下原文；类型关键字经 `volumeTypes` 归一化为规范键。
- `volumeTypes` 沿用现有键，并新增 `csi` 与 `downwardAPI`；`downwardAPI` 增加缩写 `api`。匹配不区分大小写。
- 归一化结果统一为 `{name, <source>: <value>}`；示例：`{name: vol-cm, configMap: "aaa true items (...)"}`。余下原文为空时以空值表示。
- 顶层字段分隔符为空白字符；逗号只在括号内分隔 array 元素。共享常量 `SPLIT.SPACE_COMMA` 保持不变，仅 volumes 相关的父模板、本模板及子/孙模板局部收敛为空白分隔。
- 父级只负责用 `K8S.VOLUME.SHORT` 拆出 type、name 与余下原文；每类 source 的字符串语法由 `definitions.volume` 解析。
- `ephemeral`、`projected` 不接受 string：string 元素以这两个关键字开头时中断，并提示只能使用原生 map；原生 map 中该键的值为 string 时同样中断。

## 期望输入格式

### 通用规则

- 以下格式从 source 自身字段开始；`<volumeType>` 与 `<volumeName>` 已由 `core.podSpec` 消费。
- 位置段以空白分隔；括号内 array 元素以逗号分隔。
- 关键字与枚举过滤不区分大小写；枚举渲染归一化为官方拼写，例如 `memory` → `Memory`、`always` → `Always`、`directoryorcreate` → `DirectoryOrCreate`、`TRUE` → `true`。
- 显式关键字只标记其后括号内容的归属，不参与取值：`items`、`attr`、`volumeAttributes`、`targetWWNs`、`wwids`、`chap`、`portals`、`field`、`resource`。
- boolean 过滤不区分大小写，输出 `true` / `false`。
- 位置段没有值时按空字符串处理，视为未提供；`hostPath` 的 `type` 允许显式 `""` 表示空字符串。

### configMap

- 全文：`<volumeType> <volumeName> <name> [optional] [defaultMode] [items (<key> <path> [mode], ...)]`。
- `<name>` 是 ConfigMap 名称；`optional` 过滤不区分大小写，输出 `true` / `false`。
- `items` 是显式关键字；括号内每个元素以原始 item 字符串下传，由子/孙模板解析为 `{key, path, mode}`。
- `defaultMode` 与 items 的 `mode` 接受八进制 `0xxx` 与十进制 0-511；本模板原样下传，最终由子/孙模板解析为十进制。

### csi

- 全文：`<volumeType> <volumeName> <driver> <nodePublishSecretRef> [fsType] [readOnly] [attr|volumeAttributes (key value, ...)]`。
- `fsType` 仅支持 `ext4`、`xfs`、`ntfs`。
- `readOnly` 过滤不区分大小写，输出 `true` / `false`。
- `attr` 与 `volumeAttributes` 是显式关键字；括号内每个 `key value` 段映射为 `volumeAttributes` 的键值，键值分隔符为空格或冒号（如 `\s*[: ]+\s*`）。
- `nodePublishSecretRef` 以原始字符串下传，由子/孙模板映射为 `LocalObjectReference.name`；取值为空时不渲染该字段。

### downwardAPI

- 全文：`<volumeType> <volumeName> [defaultMode] [items (<item>, ...)]`。
- `items` 元素两种形态，`mode` 均为 item 末尾的可选项：
  - `<path> field <fieldPath> [mode]`：`field` 是关键字；原始 item 字符串下传，由子/孙模板映射为 `DownwardAPIVolumeFile.fieldRef`；`fieldPath` 原样下传，由后续模板校验。
  - `<path> resource <resource> [containerName] [divisor] [mode]`：`resource` 是关键字；原始 item 字符串下传，由子/孙模板映射为 `DownwardAPIVolumeFile.resourceFieldRef`；`<resource>` 映射为 `ResourceFieldSelector.resource`，`containerName` 映射为 `ResourceFieldSelector.containerName`，`divisor` 映射为 `ResourceFieldSelector.divisor`；`<resource>` 原样下传，由后续模板校验。
- 位置段没有值时按空字符串处理；`containerName` 在前，`divisor` 在后。
- `defaultMode` 与 items 均由本模板归一化为 `definitions.downwardAPIVolumeSource` 的上下文；items 以原始 item 字符串列表下传，捕获值原样下传，由子/孙模板清洗。

### emptyDir

- 全文：`<volumeType> <volumeName> [medium] [sizeLimit]`。
- `medium` 只接受空值或 `Memory`。
- `sizeLimit` 可使用 `base.quantity` 处理。

### fc

- 全文：`<volumeType> <volumeName> [lun] <fsType> [readOnly] [targetWWNs (<value>, ...)] [wwids (<value>, ...)]`。
- `targetWWNs` 与 `wwids` 不互斥，至少二选一，也可共存；两者都是显式关键字，括号内容映射为对应 string array。
- `lun` 只接受大于等于 0 的整数，且仅在 `targetWWNs` 存在时渲染。
- `fsType` 仅支持 `ext4`、`xfs`、`ntfs`。
- `readOnly` 过滤不区分大小写，输出 `true` / `false`。

### hostPath

- 全文：`<volumeType> <volumeName> <path> [type]`。
- `path` 必须是绝对路径。
- `type` 枚举：空字符串、`BlockDevice`、`CharDevice`、`Directory`、`DirectoryOrCreate`、`File`、`FileOrCreate`、`Socket`；允许显式 `""`。

### image

- 全文：`<volumeType> <volumeName> <reference> [pullPolicy]`。
- `pullPolicy` 枚举：`Always`、`IfNotPresent`、`Never`。

### iscsi

- 全文：`<volumeType> <volumeName> <iqn> <lun> [targetPortal] [fsType] [readOnly] [iscsiInterface] [initiatorName] [chap (<chapAuthDiscovery>, <chapAuthSession>)] [portals (<ip>, ...)] [secretRef.name]`。
- `lun` 只接受大于等于 0 的整数。
- `chap` 是显式关键字；两个值必须同时设置，且只映射 `chapAuthDiscovery` 与 `chapAuthSession`。
- `portals` 是显式关键字；括号内容映射为 string array。
- `secretRef` 以原始字符串下传，由子/孙模板映射为 `{secretRef: {name: ...}}`。
- `fsType` 仅支持 `ext4`、`xfs`、`ntfs`。
- `targetPortal` / `portals` 允许 `ip:port` 或端口号。
- 位置可选段没有值时按空字符串处理，视为未提供。

### nfs

- 全文：`<volumeType> <volumeName> <server> <path> [readOnly]`。
- `server` 是 IP 或域名；`path` 必须是绝对路径。

### persistentVolumeClaim

- 全文：`<volumeType> <volumeName> <claimName> [readOnly]`。

### secret

- 全文：`<volumeType> <volumeName> <secretName> [optional] [defaultMode] [items (<key> <path> [mode], ...)]`。
- `items` 是显式关键字；括号内每个元素以原始 item 字符串下传，由子/孙模板解析为 `{key, path, mode}`。
- `defaultMode` 与 items 的 `mode` 接受八进制 `0xxx` 与十进制 0-511；本模板原样下传，最终由子/孙模板解析为十进制。

## 约束

- 仅使用 Helm 内置函数、Go Template、Sprig 与 Helm 特有函数。
- 只渲染 `name` 与上表 13 个 source；`name` 以外只允许一个 source，名单外键中断。
- `ephemeral`、`projected` 只接受原生 map；string array 元素与原生 map 中的 string 值都中断。
- 共享常量 `SPLIT.SPACE_COMMA` 保持不变；仅 volumes 相关的父模板、本模板及子/孙模板局部收敛为空白分隔，逗号只在括号内分隔 array 元素。
- mode / defaultMode 等捕获值原样下传，由子/孙模板清洗与类型转换。
- 该模板为当前 change 新增、尚未进入稳定规格或用户文档；按发布前重命名处理，旧名不再作为调用名。
- 与本仓库既有 `definitions.*` 模板的输入约定和错误信息风格保持一致。

## 非目标

- 不创建 `definitions.*VolumeSource` 子模板实现。
- 不为 `ephemeral`、`projected` 提供 string 简写。
- 不改动 `volumes` 之外的 PodSpec 字段。

## 验收

- `definitions.volume` 对 `{name, <source>}` 输入只输出 `name` 与该 source 键，字段顺序与需求一致；`name` 小写并按 RFC1123 校验。
- 名单外 source 键中断。
- source 值为 map 时原样传给对应子模板；为 string 时形成子模板所需的 map 上下文。
- source 值为 `nil` 或子模板输出为空/非 map 时，仍输出 `source: {}`。
- `core.podSpec` 的 `volumes` 接受 map array、string array 及其混合，结果统一为 `{name, <source>: <value>}`；共享 `SPLIT.SPACE_COMMA` 不变。
- 类型关键字覆盖既有类型并新增 `csi`、`downwardAPI`（含 `api` 缩写）。
- `ephemeral`、`projected` 的 string 输入（含原生 map 中的 string 值）被拒绝，错误信息提示只能使用原生 map。
- `csi` 的 `readOnly` 输出布尔；`nodePublishSecretRef` 为空时由子/孙模板按空值处理。
- `fc` 至少存在 `targetWWNs` 或 `wwids`；`lun` 仅在 `targetWWNs` 存在时输出；fc 与 iscsi 的 `fsType` 仅接受三种枚举值。
- `iscsi` 的位置可选段缺失按空字符串处理；`targetPortal` / `portals` 支持 `ip:port` 或端口号。
- `downwardAPI` 两个 item 形态都支持末尾可选 `mode`；`containerName` 与 `divisor` 由子/孙模板按位置映射；`fieldPath` / `resource` 原样下传。
- 枚举过滤不区分大小写，输出为官方拼写；`memory`、`always`、`directoryorcreate`、`TRUE` 等变体归一化。
- `defaultMode` 与 `items` 的 `mode` 同时接受八进制与十进制，并原样下传。

## 参考

- [Kubernetes Volumes](https://kubernetes.io/docs/concepts/storage/volumes/)
- [release/v1.34 的 _Volume.tpl](https://git.12334.host/kazama/kube-chart/src/branch/release/v1.34/templates/api-resources/ConfigStorage/_Volume.tpl)
