---
change-id: definitions-typed-object-reference
updated_at: "2026-11-26T13:49:04Z"
---

# definitions.typedObjectReference

## 目标

- 提供 `definitions.typedObjectReference` 定义模板，渲染 Kubernetes TypedObjectReference 字段片段。

## 需求

- 上下文是原生 map。
- 字段按官方定义：`kind` 和 `name` 必填，`apiGroup`、`namespace` 可选。
- 按官方定义渲染顺序：`apiGroup` → `kind` → `name` → `namespace`。
- `apiGroup` 与 `namespace` 为空时省略该字段。
- `apiGroup` 非空时不校验，因为该字段涉及第三方 API 的定义，不做严格校验。
- `namespace` 非空时校验是否符合 Kubernetes namespace 名称格式。
- 必填字段的失败消息由本 change 维护。

## 期望输入格式

- 调用方传入原生 map，由单个 TypedObjectReference 字段集合构成。

## 约束

- 渲染顺序必须与官方定义一致，不按输入 map 的键顺序输出。

## 非目标

- 不实现 `definitions.typedLocalObjectReference`、`definitions.volumeResourceRequirements` 等其他定义模板。

## 验收

- 调用 `definitions.typedObjectReference` 可得到按 `apiGroup`、`kind`、`name`、`namespace` 顺序输出的 YAML 字段片段。
- 缺少 `kind` 或 `name` 时渲染中断并给出明确失败信息。

## 开放问题

- 暂无。
