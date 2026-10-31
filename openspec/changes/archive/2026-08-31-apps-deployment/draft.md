---
change-id: apps-deployment
updated_at: "2026-08-28T02:36:15Z"
---

# Apps Deployment

## 目标

- 新增模板 `apps.deployment`。

## 需求

- 模板路径为 `templates/api-resources/Apps/_Deployment.tpl`。
- 上下文 `.` 中设置 `_kind: Deployment`。

## 约束

- 渲染 `metadata`、`spec` 时，均将父模板当前上下文 `.` 直接传给对应子模板，且不使用 `mustDeepCopy`。

## 非目标

## 验收

- `templates/api-resources/Apps/_Deployment.tpl` 提供名为 `apps.deployment` 的命名模板。
