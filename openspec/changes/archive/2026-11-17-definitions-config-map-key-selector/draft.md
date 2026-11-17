---
change-id: definitions-config-map-key-selector
updated_at: "2026-11-17T15:48:38Z"
---

# definitions.configMapKeySelector

## 目标

- 新增命名模板 `definitions.configMapKeySelector`，把 map 上下文渲染为 Kubernetes `ConfigMapKeySelector` 字段片段。
- 供 `definitions.envVarSource` 的 `configMapKeyRef` 分支调用。

## 需求

- 入参上下文为 map。
- `key` 与 `name` 均为必填字段；缺失或为空时中断渲染。
- 按官方文档字段顺序渲染：`key`、`name`、`optional`。
- 字段类型按官方定义：`key` 为 string，`name` 为 string，`optional` 为 boolean。
- `name` 按 RFC1123 Subdomain 校验：≤253 字符，允许点，每段为小写字母数字且以字母数字首尾。
- `name` 的校验复用 `base.rfc`，不在本模板内单独实现；为此需为 `base.rfc` 增加 `1123sub` 模式，覆盖 RFC1123 Subdomain 规则与 253 字符上限。
- `optional` 只接受原生 boolean；字符串 `"true"` / `"false"` 视为类型错误并中断。
- 取值使用 `base.get`。
- 只渲染官方文档约定的三个字段；入参中的其他键静默忽略。

## 期望输入格式

- `definitions.configMapKeySelector` 的入参为单个 `ConfigMapKeySelector` map，键为 `key`、`name`、`optional`。

## 约束

- `name` 为空或缺失即中断，不使用默认值掩盖缺失。
- `base.rfc` 的 `1123sub` 模式复用 `base.env` 的 `RFC.RFC1123_SUBDOMAIN` 常量；该常量需新增，因为现有 `RFC1035`、`RFC1123` 均为 Label 规则，不含点。
- `base.rfc` 新增模式不得改变 `1035`、`1123`、`rbac` 三个既有模式的行为与失败消息。
- `name` 不符合规则时由 `base.rfc` 中断，失败消息保留其自身 `[base.rfc]` 前缀，与 `definitions.localObjectReference` 的 RFC 校验错误一致。
- `templates/api-resources/Definitions/_EnvVarSource.tpl` 中 `configMapKeyRef` 的必需段数从 1 同步修正为 2，与 `key` 必填一致。
- 输出为单层字段片段，不包含 `configMapKeyRef` 父键。

## 非目标

- 不渲染 `EnvVarSource` 的其他字段。
- 不实现 `definitions.envVarSource` 的分发逻辑。
- 不校验 `name` 指向的 ConfigMap 是否真实存在。

## 验收

- 最小输入 `name` 与 `key` 能渲染出合法的 `ConfigMapKeySelector` 字段片段。
- 三个字段齐全时按 `key`、`name`、`optional` 顺序输出。
- `key` 或 `name` 缺失、为空时中断渲染。
- `name` 不符合 RFC1123 Subdomain（如含下划线、超过 253 字符、段首尾非字母数字）时中断渲染，失败消息来自 `base.rfc`。
- `base.rfc` 新增 `1123sub` 模式后，`1035`、`1123`、`rbac` 三个既有模式的校验结果与失败消息保持不变。
- `optional` 为字符串时中断；为原生 boolean 时正确输出。
- `_EnvVarSource.tpl` 的 `configMapKeyRef` 字符串在少于两段时不再组装。
- 入参中的额外键不产生输出。

## 开放问题

- 无。
