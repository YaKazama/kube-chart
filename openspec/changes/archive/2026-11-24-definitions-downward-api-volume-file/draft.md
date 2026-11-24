---
change-id: definitions-downward-api-volume-file
updated_at: "2026-11-24T15:02:37Z"
---

# definitions.downwardAPIVolumeFile

## 目标

- 新增核心命名模板 `definitions.downwardAPIVolumeFile`，渲染 Kubernetes `DownwardAPIVolumeFile` 字段片段，作为 `definitions.downwardAPIVolumeSource` 中 `items` 元素的委托目标。

## 需求

- 入参上下文支持两类形态：原生 map，以及父模板清洗后得到的 map。
- 原生 map：`fieldRef`、`resourceFieldRef` 已是子模板所需 map，直接向子模板传递并渲染，不做改写。
- 父模板清洗后的 map：`fieldRef`、`resourceFieldRef` 的实际值为字符串，必须先清洗为子模板所需的 map，再传给子模板。
- 字符串切分与父模板正则一致：分隔符为空白；`fieldRef` 按 `<fieldPath> [apiVersion]` 位次取值，`resourceFieldRef` 按 `<resource> [containerName] [divisor]` 位次取值；必需段缺失时中断，不能跳过前面的可选段。
- `fieldRef` 委托 `definitions.objectFieldSelector`。
- `resourceFieldRef` 委托 `definitions.resourceFieldSelector`。
- `path` 必填，沿用 `definitions.keyToPath` 的相对路径归一化与 `..` 拒绝规则。
- 渲染顺序按 `DownwardAPIVolumeFile` 官方定义顺序：`fieldRef`、`mode`、`path`、`resourceFieldRef`。
- `mode` 为官方可选 integer 字段，沿用 `base.fileMode` 归一化为十进制 int。
- `fieldRef` 与 `resourceFieldRef` 互斥：同时出现或都为空时均中断。

## 期望输入格式

- 原生 map：`fieldRef`、`resourceFieldRef` 为 map。
- 父模板清洗后的 map：`fieldRef`、`resourceFieldRef` 为 string，形态分别为 `<fieldPath> [apiVersion]` 与 `<resource> [containerName] [divisor]`。

## 非目标

- 不修改 `definitions.downwardAPIVolumeSource` 的 string item 过滤与组装逻辑。
- 不实现 `definitions.objectFieldSelector` 与 `definitions.resourceFieldSelector` 的内部校验，仅委托调用。

## 验收

- 原生 map 输入与等价的父模板清洗后字符串输入渲染结果一致。
- 必填字段缺失或非法、`fieldRef` 与 `resourceFieldRef` 同时出现或都为空时以明确错误中断。
- 在最小 application Chart 中通过 `helm template` 实际渲染。

## 开放问题

- 无。
