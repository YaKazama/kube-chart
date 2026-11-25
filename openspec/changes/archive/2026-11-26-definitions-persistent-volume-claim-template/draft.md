---
change-id: definitions-persistent-volume-claim-template
updated_at: "2026-11-25T17:15:50Z"
---

# `definitions.persistentVolumeClaimTemplate`

## 目标

- 新增 `definitions.persistentVolumeClaimTemplate`。

## 需求

- 上下文是原生 map。
- `metadata`（ObjectMeta，可选）：缺失或为空时省略；存在时直接调用 `definitions.objectMeta` 渲染。
- `spec`（PersistentVolumeClaimSpec，必填）：委托 `core.persistentVolumeClaimSpec` 渲染；该子模板本 change 不创建，只保留调用占位。
- `metadata`、`spec` 存在但无法恢复为 map 时中断报错；`spec` 缺失或为空时中断报错。

## 期望输入格式

- 原生 map，包含可选的 `metadata` 与必填的 `spec`。

## 约束

- `spec` 不能为空。
- 直接调用 `definitions.objectMeta`，不改造该模板。

## 非目标

- 不创建 `core.persistentVolumeClaimSpec`。
