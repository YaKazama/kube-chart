---
change-id: definitions-empty-dir-volume-source
updated_at: "2026-11-24T16:06:37Z"
---

# definitions.emptyDirVolumeSource

## 目标

- 新增 `definitions.emptyDirVolumeSource` 定义模板，渲染 Kubernetes `EmptyDirVolumeSource` 字段片段。

## 需求

- 入参上下文需同时兼容原生 map 与父模板清洗后的 map。
- 父模板清洗后的 map 包含 `EmptyDirVolumeSource` 定义的键，也可能是空 map；值理论上已完成归一化，子模板只校验、不重复清洗。
- `medium` 与 `sizeLimit` 均可选；空值不渲染，非法值中断报错。
- `medium` 仅接受 `""` 与 `Memory`，枚举校验大小写敏感。
- `sizeLimit` 接受 Quantity 字符串（实际为 int 或 string），校验与渲染参考 `definitions.resourceFieldSelector` 的 `divisor` 处理。
- 空 map 不渲染任何字段，`emptyDir: {}` 由父模板处理。
- `EmptyDirVolumeSource` 定义之外的键忽略。
- 输出字段顺序按 K8s API 规范字段顺序处理。

## 期望输入格式

- 原生 map：调用方或 values 直接传入的未经清洗的 map。
- 父模板清洗后的 map：由父模板归一化后传入的子模板上下文，包含 `EmptyDirVolumeSource` 定义的键，值理论上已归一化，可能为空 map。

## 验收

- 渲染包含 emptyDir 卷的工作负载时，输出合法且可被 Kubernetes 接受的 `emptyDir` 字段片段。
