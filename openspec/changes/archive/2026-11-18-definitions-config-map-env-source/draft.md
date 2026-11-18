---
change-id: definitions-config-map-env-source
updated_at: "2026-11-18T14:22:18Z"
---

# definitions.configMapEnvSource

## 目标

- 新增库模板 `definitions.configMapEnvSource`，把 values 中的配置转换为 Kubernetes `ConfigMapEnvSource` 对象。

## 需求

- 模板名称为 `definitions.configMapEnvSource`。
- 上下文是一个 map，包含 `name` 与 `optional` 两个字段。
- `name` 为必填字段：未提供时视为输入错误并中断渲染，不输出缺少 `name` 的对象。
- `name` 在 `base.get` 取值后使用 `trim` 移除首尾空白；去除后为空字符串时等同缺失。
- `name` 必须做名称合法性校验，非法名称中断渲染。
- `name` 采用 RFC1123 Subdomain 校验（`base.rfc` 的 `1123sub`，含 253 字符上限），与 `definitions.configMapKeySelector`、`definitions.secretKeySelector` 一致。
- `optional` 为可选字段：缺失、显式 `null`、空字符串或仅空白字符串时视为未提供，不渲染该字段。
- `optional` 仅在存在有效值时交给 `base.field` 处理。
- `optional` 经 `base.bool` 收口，接受原生布尔与 `"true"` / `"false"` 字符串；显式 `false` 仍渲染 `optional: false`，其他类型中断。
- 输出字段按 Kubernetes 官方文档中 `ConfigMapEnvSource` 的字段顺序渲染：`name`、`optional`。
- 模板文件为 `templates/api-resources/Definitions/_ConfigMapEnvSource.tpl`，沿用现有 Definitions 文件的命名约定。

## 期望输入格式

- 上下文为 map：

```yaml
name: <string>
optional: <bool>
```

## 约束

- 字段渲染顺序以官方文档为准，不按调用方 map 的书写顺序。

## 非目标

- 只输出 `name`、`optional` 字段片段，不包含 `configMapRef` 父键与 `envFrom` 数组包装。
- 不校验被引用的 ConfigMap 是否存在。

## 验收

- 调用 `definitions.configMapEnvSource` 时，渲染结果的字段顺序为 `name`、`optional`。
- 未提供 `name` 时渲染中断，不产生缺少 `name` 的片段。
- `name` 不符合所采用的名称规则时渲染中断。
- `name` 带首尾空白时，输出移除空白后的名称。
- 只提供 `name` 时，渲染结果中不含 `optional` 键。
- `optional` 为 `null`、空字符串或仅空白字符串时，渲染结果中不含 `optional` 键。
- 提供 `optional: false` 时，渲染结果含 `optional: false`。
