---
change-id: definitions-downward-api-projection
updated_at: "2026-11-28T09:18:14Z"
---

# definitions.downwardAPIProjection

## 目标

- 新增命名模板 `definitions.downwardAPIProjection`，用于渲染 Kubernetes core/v1 `DownwardAPIProjection`。

## 需求

- 字段按官方定义，按官方字段顺序 `items` 渲染。
- `items` 可选，为 DownwardAPIVolumeFile array。
- `items` 逐项委托子模板 `definitions.downwardAPIVolumeFile`；本 change 只保留调用占位，不创建该子模板。
- `items` 渲染后回收的数据需要去重、去空。

## 期望输入格式

- 模板上下文为原生 map。

## 非目标

- 不创建或修改子模板 `definitions.downwardAPIVolumeFile`。

## 验收

- 调用该模板可得到合法的 `DownwardAPIProjection`，`items` 按官方定义输出。
- `items` 的渲染由 `definitions.downwardAPIVolumeFile` 承担，结果去重并剔除空项。
- `items` 缺失、为空数组或全部结果被剔除时省略。
