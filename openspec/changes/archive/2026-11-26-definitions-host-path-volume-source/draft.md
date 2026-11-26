---
change-id: definitions-host-path-volume-source
updated_at: "2026-11-26T15:35:27Z"
---

# 新增 definitions.hostPathVolumeSource

## 目标

- 提供 `definitions.hostPathVolumeSource`，用于渲染 Kubernetes `HostPathVolumeSource`（v1 core），并修正父模板 `hostPath` 简写中 `type` 的枚举校验。

## 需求

- `path` 字段必填且必须是绝对路径；为空或非法时中断报错。
- 父模板 `hostPath` 为 string 简写时，解析阶段校验 `path`：为空或不是绝对路径时中断报错。
- `type` 字段可选；允许显式空字符串 `""`，空值不渲染 `type`（使用 Kubernetes 默认值 `""`）。
- 父模板 string 简写的 `type` 捕获组改为枚举 alternation（大小写不敏感）；`(?i:...)` 捕获值保留输入大小写，父模板负责替换为官方枚举值后下传。
- 原生 map 传入的 `type` 不处理（不做大小写归一化）；由 `definitions.hostPathVolumeSource` 按官方枚举大小写校验并原样渲染。
- `type` 非空时按官方枚举校验：`BlockDevice`、`CharDevice`、`Directory`、`DirectoryOrCreate`、`File`、`FileOrCreate`、`Socket`；渲染官方大小写。
- 按官方字段顺序渲染：`path`、`type`。
- “父模板”指 `templates/api-resources/Definitions/_Volume.tpl`；接受正则不匹配时的新中断信息 `does not match '<path> [type]'`。

## 期望输入格式

- 上下文是原生 map 或由父模板清洗后的 map。
- 键名与 Kubernetes `HostPathVolumeSource` 字段一致：`path`、`type`。

## 验收

- 仅提供绝对路径 `path` 时，渲染结果只含 `path`。
- `path` 缺失、为空或不是绝对路径时，渲染中断并报错。
- 父模板 string 简写的 `path` 为空或不是绝对路径时，解析中断并报错。
- 父模板 string 简写的 `type` 接受任意大小写官方枚举值或 `""`，下传官方枚举值。
- 原生 map 的 `type` 使用官方大小写枚举值时渲染该值；使用非官方大小写时中断。
- `type` 为 `""` 或空值时，不渲染 `type`。
- `type` 不在官方枚举内时，渲染中断；父模板 string 简写以 `does not match '<path> [type]'` 中断。
- 渲染字段顺序为 `path`、`type`。
