---
change-id: definitions-persistent-volume-claim-volume-source
updated_at: "2026-11-27T02:43:00Z"
---

# definitions.persistentVolumeClaimVolumeSource

## 目标

- 新增 `definitions.persistentVolumeClaimVolumeSource` 定义，按官方 `PersistentVolumeClaimVolumeSource` 渲染 PVC 卷源字段。

## 需求

- 上下文为原生 map 或由父模板清洗后的 map。
- 字段按官方定义：`claimName` 必填，`readOnly` 可选。
- 字段类型按官方定义：`claimName` 为 string，`readOnly` 为 boolean。
- 按官方定义渲染顺序输出字段；本地 v1.36 参考中依次为 `claimName`、`readOnly`。

## 验收

- `claimName` 缺失时渲染中断并报错。
- `readOnly` 未提供时不输出。
- 渲染结果按官方定义顺序输出 `claimName`、`readOnly`。
