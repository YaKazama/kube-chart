---
change-id: definitions-secret-projection
updated_at: "2026-11-28T10:03:05Z"
---

# definitions.secretProjection

## 目标

- 新增 `definitions.secretProjection`，按 Kubernetes `SecretProjection` 官方定义渲染该字段片段。

## 期望输入格式

- 上下文为原生 map，不使用类型化对象。
- 键与官方字段一致：`name`、`items`、`optional`。

## 需求

- 字段按官方 `SecretProjection` 定义：`name`（string）、`items`（KeyToPath 数组）、`optional`（bool）。
- 渲染顺序按官方定义字段顺序：`items`、`name`、`optional`。
- `name` 必填；`items`、`optional` 可选。
- `items` 通过子模板 `definitions.keyToPath` 渲染；本 change 只占位调用，不创建该子模板。
- 收集的渲染数据需要去重、去空，由 Helm 函数处理。
- `items`、`optional` 为空时不渲染对应字段。
- `optional` 为显式 `false` 时允许渲染。
- 输入非法时中断并报错。

## 约束

- `definitions.keyToPath` 仅作为占位调用，不创建、不修改。
- 尽量采用简洁直白写法。

## 非目标

- 不创建 `definitions.keyToPath`（仓库中已存在 `templates/api-resources/definitions/_KeyToPath.tpl`）。
- 不调整 `SecretProjection` 之外的其他 definition 模板。

## 验收

- 合法输入按 `items`、`name`、`optional` 的官方顺序渲染。
- `items`、`optional` 为空时对应字段不出现。
- `optional` 为显式 `false` 时渲染对应的 `optional: false`。
- 收集的渲染数据已去重且去空，由 Helm 函数处理。
- 非法输入时渲染中断并报错。
