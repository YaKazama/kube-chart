---
change-id: definitions-csi-volume-source
updated_at: "2026-11-24T10:02:25Z"
---

# definitions.csiVolumeSource 定义模板

## 目标

- 新增 `definitions.csiVolumeSource`，渲染 Kubernetes `CSIVolumeSource`。
- 支撑 `definitions.volume` 的 `csi` 分支：该分支当前只负责清洗出上下文，尚无对应模板实现。

## 需求

- 上下文接受两种形态：原生 map，或父模板清洗后的 map；两种形态渲染同一 `CSIVolumeSource` 字段片段。
- 必填字段为 `driver`；`nodePublishSecretRef`、`fsType`、`readOnly`、`volumeAttributes` 为可选字段。
- 上下文为清洗后的 map 时，`nodePublishSecretRef` 可能是 string 类型；本模板需先清洗为 `definitions.localObjectReference` 可接受的上下文，再委托该子模板渲染。
- `fsType` 允许不设置；枚举校验值为 `ext4`、`xfs`、`ntfs`。
- `readOnly` 只接受 `true` / `false`，显式 `false` 正常输出。
- `volumeAttributes` 在本模板完成清洗；渲染由子模板完成，本模板负责回收结果并完成字段输出。
- 可选字段的空值判定标准统一：nil、空字符串、空 map 均视为未提供，不渲染。
- 必填字段为空或非法时中断报错。
- 可选字段为空时不渲染，非法时中断报错。
- 中断报错文案统一使用 `[definitions.csiVolumeSource]` 前缀并带上字段名。

## 期望输入格式

- 上下文为 map。
- 清洗后的形态中 `nodePublishSecretRef` 以 string 出现，表示被引用的 secret 名称；原生形态中为 `LocalObjectReference` map。

## 约束

- `nodePublishSecretRef` 的清洗与渲染统一委托 `definitions.localObjectReference`，本模板不重复实现其校验与输出逻辑。
- 清洗后的 map 中除 `nodePublishSecretRef` 外，没有其他字段会被父模板转为 string 或需要额外清洗。

## 非目标

- 不修改 `definitions.volume` 的 `csi` string 简写解析。
- 不修改 `definitions.localObjectReference` 的校验与输出行为。

## 验收

- 原生 map 与清洗后 map 两种上下文都能渲染出符合 `CSIVolumeSource` 结构的 YAML 片段。
- `nodePublishSecretRef` 的 string 形态与 map 形态都渲染为 `LocalObjectReference` 的 `name` 字段。
- 省略 `fsType` 时输出不含 `fsType`；取值不在 `ext4`、`xfs`、`ntfs` 内时中断报错。
- `readOnly` 显式 `false` 正常输出；取值不是 `true` / `false` 时中断报错。
- `volumeAttributes` 非空时渲染为键值对；为空 map 时不渲染。
- 必填字段为空或非法时中断报错；可选字段为 nil、空字符串或空 map 时不出现于输出，非法时中断报错。
- 中断报错文案以 `[definitions.csiVolumeSource]` 开头并带上字段名。

## 开放问题

- 无。
