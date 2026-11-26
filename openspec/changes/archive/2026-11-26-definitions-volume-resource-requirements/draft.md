---
change-id: definitions-volume-resource-requirements
updated_at: "2026-11-26T14:10:37Z"
---

# definitions.volumeResourceRequirements

## 目标

- 提供 `definitions.volumeResourceRequirements` 定义模板，渲染 Kubernetes VolumeResourceRequirements 字段片段。

## 需求

- 上下文是原生 map。
- 字段按官方定义：`limits` 和 `requests` 可选。
- 按官方定义渲染顺序：`limits` → `requests`。
- `limits`、`requests` 为空 map 时省略该字段。
- `limits`、`requests` 的字段值由 `base.map.verify` 处理。
- 校验 `requests` 不超过 `limits`，仅比较两侧同时存在的资源键。
- 比较时先转为数字，再进行数值比较。
- 新增公共函数 `base.quantity.ge`，用于比较 Quantity；参数为两个 Quantity 字符串，返回值为布尔值，首个 Quantity 大于或等于第二个时返回 `true`，其他返回 `false`，非法 Quantity 中断渲染。
- 渲染时使用原值渲染，与 `base.quantity.ge` 的比较无关。
- 失败消息由本 change 持有。

## 期望输入格式

- 调用方传入原生 map，由单个 VolumeResourceRequirements 字段集合构成。
- `limits` 与 `requests` 的值为资源名到 Quantity 的 map。

## 约束

- 渲染顺序必须与官方定义一致，不按输入 map 的键顺序输出。

## 非目标

- 不改变 `definitions.resourceRequirements` 等其他定义模板。

## 验收

- 调用 `definitions.volumeResourceRequirements` 可得到按 `limits`、`requests` 顺序输出的 YAML 字段片段。
- 字段缺失或为空 map 时不输出对应字段。
- 非法 Quantity 或 `requests` 超过 `limits` 时渲染中断。

## 开放问题

- 暂无。
