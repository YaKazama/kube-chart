---
change-id: definitions-cluster-trust-bundle-projection
updated_at: "2026-11-28T08:55:16Z"
---

# definitions.clusterTrustBundleProjection

## 目标

- 新增命名模板 `definitions.clusterTrustBundleProjection`，用于渲染 Kubernetes core/v1 `ClusterTrustBundleProjection`。

## 需求

- 字段按官方定义。
- 按官方定义渲染顺序：`labelSelector`、`name`、`optional`、`path`、`signerName`。
- `path` 必填；`optional` 可选；`labelSelector` 可选。
- 非空 `labelSelector` 委托子模板 `definitions.labelSelector` 渲染。
- `path` 为相对路径。
- `name` 与 `signerName` 互斥，二选一必填。
- `name` 不与 `signerName`、非空 `labelSelector` 同时设置。
- 非空 `labelSelector` 仅与 `signerName` 同时使用。
- `labelSelector` 为空（缺失、null、空字符串或空 map）时参与判断但按未设置处理：视同父模板未传递，不渲染，也不触发伴随约束。
- 违反约束的输入中断渲染并报错。

## 期望输入格式

- 模板上下文为原生 map。

## 非目标

## 验收

- 调用该模板可得到合法的 `ClusterTrustBundleProjection`，字段按官方定义与官方顺序输出。
- `labelSelector` 的渲染由 `definitions.labelSelector` 承担。
- `path` 缺失、`name` 与 `signerName` 同时设置或同时缺失、非空 `labelSelector` 与 `name` 同时设置、非空 `labelSelector` 未配合 `signerName` 时，渲染中断并报错。
- 空 `labelSelector` 不渲染且不报错，等同父模板未传递。
