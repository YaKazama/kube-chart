---
change-id: definitions-config-map-projection
updated_at: "2026-11-28T09:04:26Z"
---

# definitions.configMapProjection

## 目标

- 新增命名模板 `definitions.configMapProjection`，用于渲染 Kubernetes core/v1 `ConfigMapProjection`。

## 需求

- 字段按官方定义，按官方字段顺序 `items`、`name`、`optional` 渲染。
- `name` 必填；`items` 与 `optional` 可选。
- `items` 为 KeyToPath array，逐项委托子模板 `definitions.keyToPath`；本 change 只保留调用占位，不创建该子模板。
- `items` 渲染后回收的数据需要去重、去空。
- `items` 的 `path` 为相对路径，且不得为 `..` 或以 `../` 开头。

## 期望输入格式

- 模板上下文为原生 map。

## 非目标

- 不创建或修改子模板 `definitions.keyToPath`。

## 验收

- 调用该模板可得到合法的 `ConfigMapProjection`，字段按官方定义与官方顺序输出。
- `items` 的渲染由 `definitions.keyToPath` 承担，结果去重并剔除空项。
- `name` 缺失或为空时中断渲染。
- `items` 的 `path` 保持相对路径，逃逸路径被拒绝。
