---
change-id: definitions-secret-env-source
updated_at: "2026-11-18T14:35:33Z"
---

# definitions.secretEnvSource

## 目标

- 新增库模板 `definitions.secretEnvSource`，把 values 中的配置转换为 Kubernetes `SecretEnvSource` 对象。
- 参考 `definitions.configMapEnvSource` 的既有行为与边界。

## 需求

- 模板名称为 `definitions.secretEnvSource`。
- 上下文为 map，包含必填 `name` 与可选 `optional`。
- `name` 在取值后移除首尾空白，去除后为空则中断；非空名称按 RFC1123 Subdomain 校验，最多 253 字符。
- `optional` 缺失、显式 `null`、空字符串或仅空白字符串时省略；有效值只接受原生布尔或字符串 `"true"` / `"false"`，显式 `false` 仍输出。
- 输出字段顺序为 `name`、`optional`。
- 模板文件为 `templates/api-resources/Definitions/_SecretEnvSource.tpl`。

## 约束

- 与 `definitions.configMapEnvSource` 字段相同，`name` 校验、`optional` 归一、输出顺序和字段片段边界完整沿用其既有行为。

## 非目标

- 只输出 `name`、`optional` 字段片段，不包含 `secretRef` 父键与 `envFrom` 数组包装。
- 不校验被引用的 Secret 是否存在。

## 验收

- 只提供 `name` 时，渲染结果不含 `optional`。
- 提供合法 `optional` 时按 `name`、`optional` 顺序输出，显式 `false` 保留。
- `name` 缺失、空白、非字符串或不符合名称规则时渲染中断。
