---
change-id: definitions-image-volume-source
updated_at: "2026-11-26T15:52:33Z"
---

# 新增 definitions.imageVolumeSource

## 目标

- 提供 `definitions.imageVolumeSource`，用于渲染 Kubernetes `ImageVolumeSource`（v1 core），并修正父模板 `image` 简写中 `pullPolicy` 的枚举 alternation。

## 需求

- 上下文是原生 map 或由父模板清洗后的 map。
- 字段按官方定义：`pullPolicy`（string，可选）、`reference`（string，必填）。
- 按官方定义渲染顺序：`pullPolicy`、`reference`。
- `reference` 必填且非空；为空或非 string 时中断。
- `pullPolicy` 可选；空值不渲染；渲染时大小写敏感，枚举值为 `Always`、`IfNotPresent`、`Never`；非法枚举或非 string 时中断。
- “父模板”指 `templates/api-resources/Definitions/_Volume.tpl`。
- 修复父模板所用 `K8S.VOLUME.IMAGE` 正则，将 `pullPolicy` 捕获组改为枚举 alternation（大小写不敏感），枚举值为 `Always`、`IfNotPresent`、`Never`。
- 父模板捕获值保留输入大小写，MUST 映射为官方枚举值后下传；空值不下传。

## 期望输入格式

- 键名与 Kubernetes `ImageVolumeSource` 字段一致：`reference`、`pullPolicy`。

## 验收

- 仅提供 `reference` 时，渲染结果只含 `reference`。
- `pullPolicy` 为官方枚举值时，按官方大小写渲染。
- `pullPolicy` 为空值时，不渲染 `pullPolicy`。
- `pullPolicy` 不在官方枚举内时，渲染中断。
- 父模板 `image: "<reference> [pullPolicy]"` 中，`pullPolicy` 以任意大小写匹配官方枚举并下传官方枚举值，否则以不匹配中断。
- 渲染字段顺序为 `pullPolicy`、`reference`。
