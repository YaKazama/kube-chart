---
change-id: definitions-service-account-token-projection
updated_at: "2026-11-28T10:20:04Z"
---

# definitions.serviceAccountTokenProjection

## 目标

- 新增 `definitions.serviceAccountTokenProjection`，按 Kubernetes `ServiceAccountTokenProjection` 官方定义渲染该字段片段。

## 期望输入格式

- 上下文为原生 map，不使用类型化对象。
- 键与官方字段一致：`audience`、`expirationSeconds`、`path`。

## 需求

- 字段按官方 `ServiceAccountTokenProjection` 定义：`audience`（string, 可选）、`expirationSeconds`（integer, 可选）、`path`（string, 必填）。
- 渲染顺序按官方定义字段顺序：`audience`、`expirationSeconds`、`path`。
- `path` 必填且必须是相对路径；拒绝包含 `..` 段或以 `..` 开头，参考 `definitions.keyToPath`。
- `audience`、`expirationSeconds` 为空时不渲染对应字段。
- `expirationSeconds` 最小 600 秒；低于 600 秒时中断渲染。
- 输入非法时中断并报错。

## 非目标

- 不调整 `ServiceAccountTokenProjection` 之外的其他 definition 模板。

## 验收

- 合法输入按 `audience`、`expirationSeconds`、`path` 的官方顺序渲染。
- `audience`、`expirationSeconds` 为空时对应字段不出现。
- `path` 缺失、为空、不是相对路径、包含 `..` 段或以 `..` 开头时中断渲染。
- `expirationSeconds` 小于 600 时中断渲染，等于 600 时允许。
- 非法输入时渲染中断并报错。
