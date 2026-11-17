---
change-id: definitions-object-field-selector
updated_at: "2026-11-17T16:00:48Z"
---

# definitions.objectFieldSelector

## 目标

- 新增命名模板 `definitions.objectFieldSelector`，把 map 上下文渲染为 Kubernetes `ObjectFieldSelector` 字段片段。
- 供 `definitions.envVarSource` 的 `fieldRef` 分支调用。

## 需求

- 入参上下文为 map。
- `fieldPath` 为必填字段；缺失或为空时中断渲染。
- `fieldPath` 必须是下列官方支持路径之一：`metadata.name`、`metadata.namespace`、`metadata.uid`、`metadata.labels['<KEY>']`、`metadata.annotations['<KEY>']`、`spec.nodeName`、`spec.serviceAccountName`、`status.hostIP`、`status.podIP`、`status.podIPs`。
- `metadata.uid` 来自 `DownwardAPIVolumeFile.fieldRef` 的官方支持集，为兼容该用途而纳入允许列表。
- `fieldPath` 不在支持列表内时中断渲染。
- 按官方文档字段顺序渲染：`apiVersion`、`fieldPath`。
- 字段类型按官方定义：`apiVersion` 为 string，`fieldPath` 为 string。
- `apiVersion` 缺省时不输出该字段，不使用官方默认值 `v1`。
- 取值使用 `base.get`。
- 只渲染官方文档约定的两个字段；入参中的其他键静默忽略。

## 期望输入格式

- `definitions.objectFieldSelector` 的入参为单个 `ObjectFieldSelector` map，键为 `apiVersion`、`fieldPath`。

## 约束

- `fieldPath` 为空或缺失即中断，不使用默认值掩盖缺失。
- `metadata.labels['<KEY>']` 与 `metadata.annotations['<KEY>']` 的 `<KEY>` 为非空标签键，需在匹配时作为捕获组提取。
- `fieldPath` 的支持列表校验需要固定正则，统一放入 `templates/base/_env.tpl` 的 `base.env`。
- 输出为单层字段片段，不包含 `fieldRef` 父键。

## 非目标

- 不渲染 `EnvVarSource` 的其他字段。
- 不实现 `definitions.envVarSource` 的分发逻辑。
- 不校验标签键是否符合 Kubernetes 标签语法。
- 不兼容 `DownwardAPIVolumeFile` 除 `metadata.uid` 以外的路径扩展。

## 验收

- 最小输入 `fieldPath` 能渲染出合法的 `ObjectFieldSelector` 字段片段。
- 两个字段齐全时按 `apiVersion`、`fieldPath` 顺序输出。
- `apiVersion` 缺省时只输出 `fieldPath`。
- `fieldPath` 缺失或为空时中断渲染。
- `fieldPath` 为十个官方路径之一时渲染成功，包括 `metadata.uid`、`metadata.labels['app']` 与 `metadata.annotations['note']`。
- `fieldPath` 不在十个官方路径内时中断渲染。
- 入参中的额外键不产生输出。

## 开放问题

- 无。
