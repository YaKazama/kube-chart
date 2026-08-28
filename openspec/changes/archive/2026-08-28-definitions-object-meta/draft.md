---
change-id: definitions-object-meta
updated_at: "2026-08-28T02:36:15Z"
---

# definitions.objectMeta 命名模板

> 用户初始意图入口。
> 只需编辑下面的“目标、需求、约束、非目标、验收”。

## 目标

- 在 `templates/api-resources/Definitions/_ObjectMeta.tpl` 中提供命名模板 `definitions.objectMeta`。

## 需求

- 包含字段 `annotations`、`generateName`、`labels`、`name`、`namespace`。
- `_kind`、`_pkind` 作为上下文字段，用于标识资源身份、字段是否渲染的判断条件。

## 约束

- `_kind` 优先级 `_pkind` > `_kind`。
- `annotations` 可选。取值顺序：
  - `_kind=PodTemplateSpec` 时，从 `podAnnotations` 取值，不共享 `annotations`。
  - `_kind=JobTemplateSpec` 时，从 `jobAnnotations` 取值，不共享 `annotations`。
  - `_kind=PersistentVolumeClaim` 时，从 `pvcAnnotations` 取值，不共享 `annotations`。
- `generateName` 可选。仅当未指定 `name` 时才应用。正则校验采用 `base.rfc` 的 `1035` 规则。
  - 通常只以 `name` 显示传入空字符串时才会生效。
  - `generateName` 不调用 `base.name`；`definitions.objectMeta` 对 `base.name` 的直接调用仅用于 `name` 字段。
- `labels` 可选。调用 `base.labels` 命名模板。向下透传 `.`。
  - 缺省输出语义由 `base.labels` 的既有契约决定，`definitions.objectMeta` 不另设调用条件或缺省值。
- `name` 必填。调用 `base.name` 命名模板。向下透传 `.`。
  - 正则校验：
    - `_kind` 为 `ClusterRole`、`Role`、`ClusterRoleBinding`、`RoleBinding` 时，`base.name` mode 为 `rbac`。
    - `_kind` 为 `APIService` 时，`base.name` mode 为 `apiservice`。
  - `_kind` 为 `PodTemplateSpec`、`JobTemplateSpec` 时，不渲染。
- `namespace` 可选。调用 `base.namespace` 命名模板。向下透传 `.`。
  - 缺省输出语义由 `base.namespace` 的既有契约决定，`definitions.objectMeta` 不另设调用条件或缺省值。
  - `_kind` 为 `PodTemplateSpec`、`JobTemplateSpec`、`PersistentVolumeClaim`、`ClusterRole`、`ClusterRoleBinding` 时，不渲染。

## 非目标

## 验收

- `templates/api-resources/Definitions/_ObjectMeta.tpl` 中存在可供调用的命名模板 `definitions.objectMeta`。
