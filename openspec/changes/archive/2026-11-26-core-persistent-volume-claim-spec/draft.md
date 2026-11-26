---
change-id: core-persistent-volume-claim-spec
updated_at: "2026-11-26T06:10:25Z"
---

# core.persistentVolumeClaimSpec

## 目标

- 新增 core 级模板 `core.persistentVolumeClaimSpec`，渲染 Kubernetes `PersistentVolumeClaimSpec` 字段片段。

## 需求

- 所有字段可选。
- 各字段类型以 Kubernetes 官方定义为准。
- 渲染字段集合以 Kubernetes 官方 `PersistentVolumeClaimSpec` 字段表为准，不得遗漏。
- 所有字段经 `base.get` 取值，别名由 `base.get` 隐式识别，不单独配置。
- 字段 `dataSource`（TypedLocalObjectReference）委托 `definitions.typedLocalObjectReference` 渲染。
- 字段 `dataSourceRef`（TypedObjectReference）委托 `definitions.typedObjectReference` 渲染。
- 字段 `resources`（VolumeResourceRequirements）委托 `definitions.volumeResourceRequirements` 渲染。
- 字段 `selector`（LabelSelector）委托 `definitions.labelSelector` 渲染。
- 字段 `volumeAttributesClassName`（string）由本模板直接渲染。
- 字段 `accessModes`、`volumeName`、`storageClassName`、`volumeMode` 由本模板直接渲染，不接受 string 简写。
- 枚举校验按 Kubernetes 官方定义。
- 渲染顺序以 Kubernetes 官方文档字段表顺序为准。
- 所有字段缺省或无有效内容时输出空内容。

## 期望输入格式

- 上下文是原生 map，即 `PersistentVolumeClaimSpec` 本身，不含 `spec`、`_kind` 等包装键。

## 约束

- 子模板只占位、不在本 change 创建：`definitions.typedLocalObjectReference`、`definitions.typedObjectReference`、`definitions.volumeResourceRequirements`。
- `definitions.labelSelector` 已存在，按既有模板契约调用。
- 现有 `definitions.persistentVolumeClaimTemplate` 已按 `core.persistentVolumeClaimSpec` 调用，本变更沿用该名称。

## 非目标

- 不创建上述缺失子模板。
- 不修改 `definitions.persistentVolumeClaimTemplate` 等现有调用方。

## 验收

- 输入仅含四个子模板字段之一时，对应片段按官方位置输出，其余字段省略。
- 输入包含全部字段时，输出顺序与官方定义一致。
- 输入非法枚举值时渲染中断。
