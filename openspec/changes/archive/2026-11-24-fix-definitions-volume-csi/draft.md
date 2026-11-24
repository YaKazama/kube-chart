---
change-id: fix-definitions-volume-csi
updated_at: "2026-11-24T09:35:42Z"
---

# 修正 definitions.volume 的 csi string 中 nodePublishSecretRef 为可选

## 目标

- 修正 `definitions.volume` 中 `csi` 字段的 string 抽象：`nodePublishSecretRef` 由必填项改为可选项。
- 同步改写 `K8S.VOLUME.CSI` 正则与该分支的错误提示文案。

## 需求

- `csi` 的 string 形态支持省略 `nodePublishSecretRef`，最小可写为 `<driver>`。
- 位置段按出现顺序绑定：`<driver>`、`nodePublishSecretRef`、`fsType`、`readOnly`、`[attr|volumeAttributes (...)]`。
- 可选捕获组未匹配时取值为空字符串；`<driver>` 之后没有任何 token 时，`nodePublishSecretRef`、`fsType`、`readOnly` 均为空串，不需要占位符。
- 空串即未提供：`nodePublishSecretRef` 为空时不渲染该字段，`fsType`、`readOnly` 为空时同样不渲染。
- 出现在 `nodePublishSecretRef` 位置的 `ext4`、`xfs`、`ntfs`（不区分大小写）归属 `fsType`，此时 `nodePublishSecretRef` 为空串；因此只写 `fsType` 合法。
- 出现在该位置的 `true`、`false` 仍归属 `nodePublishSecretRef.name`，不在 `nodePublishSecretRef` 位置识别 `readOnly`。
- 提供 `nodePublishSecretRef` 时保持现有行为：以原始字符串下传，由 `definitions.localObjectReference` 映射为 `LocalObjectReference.name`。
- `attr` 与 `volumeAttributes` 是显式关键字，不参与位置取值。
- `K8S.VOLUME.CSI` 正则与 `definitions.volume` 中 `csi` 分支的错误提示文案必须同步改写，与新写法一致。

## 期望输入格式

- `csi` 全文：`<volumeType> <volumeName> <driver> [nodePublishSecretRef] [fsType] [readOnly] [attr|volumeAttributes (key value, ...)]`。
- `csi <volumeName> <driver> ext4` 的 `ext4` 归属于 `fsType`，不渲染 `nodePublishSecretRef`。
- `csi <volumeName> <driver> <secret>` 的 `<secret>` 归属于 `nodePublishSecretRef.name`，即使其取值形如 `true`、`false`。
- `fsType` 与 `readOnly` 只在各自位置段出现时生效；枚举取值过滤不区分大小写，渲染归一化为小写。

## 约束

- 只调整 `csi` 的 string 抽象与对应渲染分支；原生 map 与其他 volume source 的行为不变。
- `ext4`、`xfs`、`ntfs` 出现在 `nodePublishSecretRef` 位置时无法作为 secret 名表达。`true`、`false` 可以。
- 现有 `fsType`、`readOnly`、`attr`/`volumeAttributes` 的解析与校验行为保持不变。

## 非目标

- 不实现或修改 `definitions.csiVolumeSource` 定义模板本体。
- 不修改已归档的 `2026-11-23-definitions-volume` 文档；本次行为修正仅由本 change 记录。

## 验收

- `csi <volumeName> <driver>` 渲染出仅含 `driver` 的 `csi` 卷来源片段，且不含 `nodePublishSecretRef`。
- `csi <volumeName> <driver> regcred` 渲染 `nodePublishSecretRef.name: "regcred"`。
- `csi <volumeName> <driver> regcred ext4 true` 渲染 `nodePublishSecretRef.name`、`fsType: ext4`、`readOnly: true`。
- `csi <volumeName> <driver> ext4` 渲染 `fsType: ext4`，且不含 `nodePublishSecretRef`。
- `csi <volumeName> <driver> true` 渲染 `nodePublishSecretRef.name: "true"`，不含 `readOnly`。
- `csi <volumeName> <driver> ext4 true` 渲染 `fsType: ext4` 与 `readOnly: true`，不含 `nodePublishSecretRef`。
- `csi <volumeName> <driver> attr (k v)` 渲染 `volumeAttributes` 且不含 `nodePublishSecretRef`。
- 带 `attr`/`volumeAttributes` 的既有写法渲染结果不变。
- 无法匹配新语法的输入仍中断报错，提示文案与新写法一致。

## 开放问题

- 无。
