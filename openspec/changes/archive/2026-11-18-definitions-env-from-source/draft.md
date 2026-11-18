---
change-id: definitions-env-from-source
updated_at: "2026-11-18T04:16:47Z"
---

# definitions.envFromSource

## 目标

- 新增命名模板 `definitions.envFromSource`，把 `EnvFromSource` 形状的 map 上下文转换为可渲染的字段片段。

## 需求

- 上下文为 map，形状含 `configMapRef`、`prefix`、`secretRef`。
- `configMapRef` 与 `secretRef` 互斥且至少存在一个，不满足时中断报错。
- `configMapRef` / `secretRef` 的值需要传给子模板，由本模板先处理：值为 string 时按 `<name> [optional]` 处理为子模板所需的 map，值为 map 时原样传递。
- `name` 与 `optional` 以 string 值组成子模板所需的 map。
- `prefix` 可选；未提供时不输出该键，提供时与 ref 同级输出。
- `name`、`prefix`、`optional` 均不校验：`name` 与 `optional` 原样传给子模板，`prefix` 原样输出。
- 输出字段顺序按官方文档：`configMapRef`、`prefix`、`secretRef`。
- 子模板选择：存在 `configMapRef` 时调用 `definitions.configMapEnvSource`，存在 `secretRef` 时调用 `definitions.secretEnvSource`。
- 子模板 `definitions.configMapEnvSource`、`definitions.secretEnvSource` 本 change 不创建，仅占位。

## 期望输入格式

- `definitions.envFromSource`：map，即 `EnvFromSource` 形状。
- `configMapRef` / `secretRef` 的值：string `<name> [optional]`，或 map。
- ref 值 string 的分隔符为空白与逗号，复用 `templates/base/_env.tpl` 中 `base.env` 的 `SPLIT.SPACE_COMMA`。

## 约束

- 按官方文档顺序处理。
- 尽量使用直白写法。
- 子模板不创建，仅占位。

## 非目标

- 不实现 `definitions.configMapEnvSource`、`definitions.secretEnvSource` 的行为。
- 不处理 `envFrom` 数组与 string 行解析，该部分属父级 change `fix-definitions-container-env-from`。

## 验收

- map 上下文能按 `EnvFromSource` 形状选择 ref 并传给对应子模板。
- `configMapRef` 与 `secretRef` 互斥判定生效，不满足时渲染中断报错。
- `configMapRef` / `secretRef` 为 string 时被处理为子模板所需的 map；为 map 时原样传递。
- `prefix` 未提供时不出现该键，提供时与 ref 同级输出且不被校验。
- 输出字段顺序为 `configMapRef`、`prefix`、`secretRef`。

## 开放问题

- 无。
